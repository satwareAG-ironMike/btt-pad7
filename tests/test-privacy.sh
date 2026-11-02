#!/usr/bin/env bash
# tests/test-privacy.sh - negative controls for the privacy gate (constitution I).
#
# Seeds a generic private IP (assembled from string parts - no real host or
# network detail in this suite) and verifies:
#   1. the checker flags the seeded value (rc != 0),
#   2. the whitelist suppresses exactly the seeded value (rc == 0),
#   3. the repo itself scans clean (rc == 0).
#
# The fixture is staged (git add -f) so the checker's `git grep` sees it,
# then un-staged and deleted.  The repo is left unmodified by the trap.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CHECKER="$REPO_ROOT/.specify/scripts/bash/check-privacy-leaks.sh"
WHITELIST="$REPO_ROOT/.specify/.privacy-whitelist"
FIXTURE_DIR="$REPO_ROOT/.fixtures"
FIXTURE="$FIXTURE_DIR/seed.privacy-leak"

failures=0
fail() { failures=$((failures + 1)); echo "  FAIL: $*" >&2; }
ok() { echo "  ok: $*"; }

cleanup() {
    [[ -f "$WHITELIST.bk" ]] && mv -f "$WHITELIST.bk" "$WHITELIST"
    if [[ -e "$FIXTURE" ]]; then
        git -C "$REPO_ROOT" rm -f -q -- "$FIXTURE" 2>/dev/null || true
        rm -f "$FIXTURE"
    fi
    rm -rf "$FIXTURE_DIR"
}
trap cleanup EXIT

# 1) seed a private IP -> checker must reject it
mkdir -p "$FIXTURE_DIR"
printf '%s.50\n' '192.168.1' > "$FIXTURE"   # content: 192.168.1.50
git -C "$REPO_ROOT" add -f "$FIXTURE" >/dev/null
rc=0
bash "$CHECKER" "$REPO_ROOT" >/dev/null 2>&1 || rc=1
if [[ $rc -eq 1 ]]; then
    ok "privacy checker flags the seeded 192.168.x address (rc=$rc)"
else
    fail "privacy checker rc=$rc on seeded fixture (expected 1)"
fi

# 2) whitelist suppresses the seed -> checker must pass
cp "$WHITELIST" "$WHITELIST.bk"
printf '%s\n' '^\.fixtures/' >> "$WHITELIST"
rc=0
out=$(bash "$CHECKER" "$REPO_ROOT" 2>&1) || rc=1
if [[ $rc -eq 0 ]]; then
    ok "whitelisted fixture does not block the checker"
else
    fail "whitelisted fixture still blocked the checker (rc=$rc):"
    echo "$out" | tail -5
fi
cp "$WHITELIST.bk" "$WHITELIST"
rm -f "$WHITELIST.bk"

# 3) repo itself must scan clean
git -C "$REPO_ROOT" rm -f -q -- "$FIXTURE"
rc=0
bash "$CHECKER" "$REPO_ROOT" >/dev/null 2>&1 || rc=1
if [[ $rc -eq 0 ]]; then
    ok "repo scans clean (0 content findings)"
else
    fail "repo itself has privacy findings (rc=$rc)"
fi

echo ""
if [[ $failures -eq 0 ]]; then
    echo "  privacy checks passed: 3/3"
    exit 0
fi
exit 1
