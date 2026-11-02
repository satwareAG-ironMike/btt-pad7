#!/usr/bin/env bash
# tests/test-pre-push.sh - negative control for the pre-push gate (finding
# #1 on PR #10): when the privacy checker blocks, the hook must exit 1 AND
# surface the checker's findings. The pre-push hook previously redirected the
# checker's stdout+stderr to /dev/null, hiding the finding on a block.
#
# Seeds a generic private IP (assembled from string parts - no real host or
# network detail), runs githooks/pre-push directly, and restores the tree
# unmodified via the EXIT trap.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK="$REPO_ROOT/githooks/pre-push"
FIXTURE_DIR="$REPO_ROOT/.fixtures"
FIXTURE="$FIXTURE_DIR/seed.privacy-leak"
tmpout="$(mktemp)"

failures=0
fail() { failures=$((failures + 1)); echo "  FAIL: $*" >&2; }
ok() { echo "  ok: $*"; }

cleanup() {
    rm -f "$tmpout"
    if [[ -e "$FIXTURE" ]]; then
        git -C "$REPO_ROOT" rm -f -q -- "$FIXTURE" 2>/dev/null || true
        rm -f "$FIXTURE"
    fi
    rm -rf "$FIXTURE_DIR"
}
trap cleanup EXIT

# Seed the violation so the hook's tracked-file scan sees it.
mkdir -p "$FIXTURE_DIR"
printf '%s.50\n' '192.168.1' > "$FIXTURE"
git -C "$REPO_ROOT" add -f "$FIXTURE" >/dev/null

# Run the hook, capturing rc and the full output.  Output goes to a temp
# file, not into an assignment containing a redirected command substitution
# followed by an if block, which this bash 5.3 parser rejects.
rc=0
bash "$HOOK" >"$tmpout" 2>&1 || rc=$?

if [[ $rc -eq 1 ]]; then
    ok "pre-push blocks the seeded privacy violation, rc=$rc"
else
    fail "pre-push did not block, rc=$rc; expected 1"
fi

if grep -q 'privacy violation(s)' "$tmpout" \
   && grep -q 'seed.privacy-leak' "$tmpout"; then
    ok "finding surfaced in hook output, checker report not hidden"
else
    fail "hook output hid the finding; hook output:"
    tail -6 "$tmpout"
fi

echo ""
if [[ $failures -eq 0 ]]; then
    echo "pre-push negative control passed"
    exit 0
fi
exit 1
