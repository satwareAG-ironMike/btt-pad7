#!/usr/bin/env bash
# Check upstream sync status for spec-kit fork.
#
# Fetches upstream tags, finds the latest release tag, and reports
# whether the current branch is up to date with upstream.
#
# Usage: ./check-upstream-sync.sh [OPTIONS]
#
# OPTIONS:
#   --json    Output in JSON format
#   --help    Show help message
#
# EXIT CODES:
#   0 - Check completed (status in output)
#   1 - Error (missing remote, fetch failure)

set -euo pipefail

show_help() {
    cat << 'EOF'
Usage: check-upstream-sync.sh [OPTIONS]

Check upstream sync status for the spec-kit fork.

OPTIONS:
  --json    Output in JSON format
  --help    Show this help message

EXAMPLES:
  # Human-readable check
  ./check-upstream-sync.sh

  # JSON output for automation
  ./check-upstream-sync.sh --json
EOF
}

JSON_MODE=false

for arg in "$@"; do
    case "$arg" in
        --json) JSON_MODE=true ;;
        --help|-h) show_help; exit 0 ;;
        *)
            echo "ERROR: Unknown option '$arg'. Use --help for usage." >&2
            exit 1
            ;;
    esac
done

REMOTE="upstream"

# Verify upstream remote exists
if ! git remote get-url "$REMOTE" >/dev/null 2>&1; then
    if $JSON_MODE; then
        echo '{"error":"remote not found","remote":"upstream","synced":false}'
    else
        echo "ERROR: Git remote '$REMOTE' not configured." >&2
        echo "Add it with: git remote add upstream https://github.com/github/spec-kit.git" >&2
    fi
    exit 1
fi

# Fetch upstream tags (quiet)
if ! git fetch "$REMOTE" --tags --quiet 2>/dev/null; then
    if $JSON_MODE; then
        echo '{"error":"fetch failed","remote":"upstream","synced":false}'
    else
        echo "ERROR: Failed to fetch from '$REMOTE'." >&2
    fi
    exit 1
fi

# Find latest upstream release tag (v* pattern)
LATEST_TAG=$(git tag --list 'v*' --sort=-v:refname | head -n 1)

if [[ -z "$LATEST_TAG" ]]; then
    if $JSON_MODE; then
        echo '{"error":"no tags found","synced":false}'
    else
        echo "WARNING: No upstream release tags found." >&2
    fi
    exit 0
fi

# Check if latest tag is an ancestor of HEAD
if git merge-base --is-ancestor "$LATEST_TAG" HEAD 2>/dev/null; then
    SYNCED=true
else
    SYNCED=false
fi

if $JSON_MODE; then
    CURRENT_VERSION=$(grep -m1 'version' pyproject.toml | sed 's/.*"\(.*\)".*/\1/' || echo "unknown")
    printf '{"latest_tag":"%s","current_version":"%s","synced":%s}\n' \
        "$LATEST_TAG" "$CURRENT_VERSION" "$SYNCED"
else
    if $SYNCED; then
        echo "OK: Up to date with upstream $LATEST_TAG"
    else
        echo "OUTDATED: Upstream $LATEST_TAG is not merged into HEAD"
        echo "Action: git merge $LATEST_TAG (or rebase)"
    fi
fi