#!/usr/bin/env bash
# check-fork-release.sh — guard for the mandatory satware fork release step.
#
# Issue #131: every merged upstream sync must cut `satware-vX.Y.Z+1` AND
# publish a GitHub release object. Nothing enforced that, so v1.0.7,
# v1.0.12 and v1.1.2 were merged without a release.
#
# This check finds the newest upstream release tag merged into the checked
# ref and verifies that the matching fork tag and release object exist.
#
# Usage: ./check-fork-release.sh [OPTIONS]
#
# OPTIONS:
#   --repo <path>        Repository to inspect (default: current directory)
#   --ref <ref>          Ref whose merged upstream tag is checked (default: HEAD)
#   --repo-slug <o/r>    Forge slug (default: derived from `origin` remote)
#   --json               Output in JSON format
#   --help               Show help message
#
# ENVIRONMENT:
#   GH                   gh binary to use (default: gh; tests stub it)
#
# EXIT CODES:
#   0 - Fork tag and release present, or no upstream tag merged yet
#   1 - Merged upstream tag has no matching satware-v*+1 tag and/or release
#   2 - Environment/usage error (not a repo, unknown ref, gh missing)
#
# Backfill a missing release with --latest=false so the backfill does not
# hijack `releases/latest`. If the fork tag is also missing, push it with
# git first - the releases API cannot create '+'-bearing tags inline (422):
#
#   git tag -a satware-vX.Y.Z+1 <merge-sha> && git push origin satware-vX.Y.Z+1
#   gh release create satware-vX.Y.Z+1 --verify-tag --latest=false \
#       --title "satware-vX.Y.Z+1 - upstream vX.Y.Z" --notes-file notes.md

set -euo pipefail

show_help() {
    awk 'NR==1 { next }
         /^#/ { sub(/^# ?/, ""); print; started=1; next }
         started { exit }' "${BASH_SOURCE[0]}"
}

REPO_DIR="."
REF="HEAD"
REPO_SLUG=""
JSON_MODE=false
GH_BIN="${GH:-gh}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo)
            [[ $# -ge 2 ]] || { echo "ERROR: --repo needs a value" >&2; exit 2; }
            REPO_DIR="$2"; shift 2 ;;
        --ref)
            [[ $# -ge 2 ]] || { echo "ERROR: --ref needs a value" >&2; exit 2; }
            REF="$2"; shift 2 ;;
        --repo-slug)
            [[ $# -ge 2 ]] || { echo "ERROR: --repo-slug needs a value" >&2; exit 2; }
            REPO_SLUG="$2"; shift 2 ;;
        --json) JSON_MODE=true; shift ;;
        --help|-h) show_help; exit 0 ;;
        *) echo "ERROR: Unknown option '$1'. Use --help for usage." >&2; exit 2 ;;
    esac
done

emit_error() {
    local message="$1"
    if $JSON_MODE; then
        printf '{"ok":false,"status":"error","error":"%s"}\n' "$message"
    else
        echo "ERROR: $message" >&2
    fi
    exit 2
}

git -C "$REPO_DIR" rev-parse --git-dir >/dev/null 2>&1 \
    || emit_error "not a git repository: $REPO_DIR"

git -C "$REPO_DIR" rev-parse --verify --quiet "${REF}^{commit}" >/dev/null \
    || emit_error "unknown ref: $REF"

command -v "$GH_BIN" >/dev/null 2>&1 \
    || emit_error "gh CLI not found (set GH or install gh)"

if [[ -z "$REPO_SLUG" ]]; then
    origin_url="$(git -C "$REPO_DIR" remote get-url origin 2>/dev/null || true)"
    [[ -n "$origin_url" ]] || emit_error "no origin remote and no --repo-slug given"
    case "$origin_url" in
        *://*) slug="${origin_url#*://}"; slug="${slug#*/}" ;;
        *:*)   slug="${origin_url#*:}" ;;
        *)     slug="$origin_url" ;;
    esac
    slug="${slug%.git}"
    REPO_SLUG="$slug"
fi

case "$REPO_SLUG" in
    */*/*) emit_error "cannot parse repo slug: $REPO_SLUG" ;;
    */*) ;;
    *) emit_error "cannot parse repo slug: $REPO_SLUG" ;;
esac

# Newest upstream release tag merged into the ref. Fork tags are `satware-*`
# and never match the `v*` pattern.
upstream_tag=""
while IFS= read -r tag; do
    [[ -n "$tag" ]] || continue
    [[ "$tag" == satware-* ]] && continue
    if git -C "$REPO_DIR" merge-base --is-ancestor "${tag}^{commit}" "${REF}^{commit}" 2>/dev/null; then
        upstream_tag="$tag"
        break
    fi
done < <(git -C "$REPO_DIR" tag --list 'v*' --sort=-v:refname)

if [[ -z "$upstream_tag" ]]; then
    if $JSON_MODE; then
        printf '{"ok":true,"status":"no-upstream-tag","ref":"%s","repo":"%s"}\n' "$REF" "$REPO_SLUG"
    else
        echo "OK: no upstream release tag merged into $REF - nothing to release."
    fi
    exit 0
fi

fork_tag="satware-${upstream_tag}+1"

tag_present=false
if git -C "$REPO_DIR" rev-parse --verify --quiet "refs/tags/${fork_tag}^{commit}" >/dev/null 2>&1; then
    tag_present=true
fi

release_present=false
if "$GH_BIN" release view "$fork_tag" --repo "$REPO_SLUG" --json tagName >/dev/null 2>&1; then
    release_present=true
fi

ok=false
status="missing"
if $tag_present && $release_present; then
    ok=true
    status="ok"
fi

if $JSON_MODE; then
    printf '{"ok":%s,"status":"%s","ref":"%s","repo":"%s","upstream_tag":"%s","expected_fork_tag":"%s","tag_present":%s,"release_present":%s}\n' \
        "$ok" "$status" "$REF" "$REPO_SLUG" "$upstream_tag" "$fork_tag" "$tag_present" "$release_present"
else
    if $ok; then
        echo "OK: $fork_tag exists with a published release (upstream $upstream_tag)."
    else
        echo "MISSING: upstream $upstream_tag is merged into $REF but $fork_tag is incomplete."
        $tag_present || echo "  - tag $fork_tag not found"
        $release_present || echo "  - release $fork_tag not found"
        echo "Backfill (does not hijack releases/latest):"
        if ! $tag_present; then
            # The releases API cannot inline-create '+'-bearing tags (422),
            # and --verify-tag requires the tag to exist: push via git first.
            echo "  git tag -a $fork_tag <merge-sha> && git push origin $fork_tag"
        fi
        echo "  gh release create $fork_tag --verify-tag --latest=false \\"
        echo "      --title \"$fork_tag - upstream $upstream_tag\" --notes-file notes.md"
    fi
fi

$ok && exit 0
exit 1
