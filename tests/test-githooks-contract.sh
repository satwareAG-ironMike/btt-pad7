#!/usr/bin/env bash
# tests/test-githooks-contract.sh - content contracts for the githooks gates
# (findings #2 and #3 on PR #10):
#   --check root        pre-commit resolves REPO_ROOT from the script path and
#                       scans it explicitly (no CWD-relative `betterleaks git .`)
#   --check workguidance githooks/AGENTS.md documents a Work Guidance section
# With no flag, both checks run and the exit code is 1 on any failure.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PRE_COMMIT="$REPO_ROOT/githooks/pre-commit"
DOCS="$REPO_ROOT/githooks/AGENTS.md"

check_root() {
    if grep -q 'REPO_ROOT=' "$PRE_COMMIT" \
       && grep -qF 'betterleaks git "$REPO_ROOT"' "$PRE_COMMIT"; then
        echo "pre-commit explicit REPO_ROOT confirmed"
    else
        echo "  FAIL: pre-commit does not scan an explicit REPO_ROOT" >&2
        return 1
    fi
}

check_workguidance() {
    # grep -F treats a leading ^ as literal on this toolchain; regex mode
    # anchors correctly.
    if grep -q '^## Work Guidance' "$DOCS"; then
        echo "Work Guidance section confirmed"
    else
        echo "  FAIL: githooks/AGENTS.md has no Work Guidance section" >&2
        return 1
    fi
}

main() {
    local mode="${1:-all}"
    local rc=0
    case "$mode" in
        root)
            check_root || rc=1
            ;;
        workguidance)
            check_workguidance || rc=1
            ;;
        all)
            check_root || rc=1
            check_workguidance || rc=1
            ;;
        *)
            echo "usage: $0 [root|workguidance]" >&2
            return 2
            ;;
    esac
    return "$rc"
}

main "${1:-all}"
