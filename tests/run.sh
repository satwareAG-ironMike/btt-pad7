#!/usr/bin/env bash
# tests/run.sh - runner for tests/ (constitution I: runnable test command).
#
# Runs every top-level test-*.sh in its own process.  State-changing and
# real-hardware tests live under tests/sandbox/ and are NOT picked up here
# (reserved lane: sandboxed container sshd port 2222; see tests/sandbox/README.md).
#
# Reentrancy: pre-pr.sh runs this suite with PRE_PR_RUNNING=1; the runner
# then skips test-pre-pr.sh, which would otherwise recurse into pre-pr.sh
# and loop forever.
#
# Exit: 0 = all passed, 1 = one or more failed.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
failures=0

echo "=== tests: $(date) ==="
shopt -s nullglob
for test in "$SCRIPT_DIR"/test-*.sh; do
    # Reentrancy guard (see header).
    if [[ -n "${PRE_PR_RUNNING:-}" ]] && [[ "$(basename "$test")" == "test-pre-pr.sh" ]]; then
        continue
    fi
    echo ""
    echo "--- $(basename "$test")"
    if bash "$test"; then
        echo "PASS: $(basename "$test")"
    else
        echo "FAIL: $(basename "$test")"
        failures=1
    fi
done

echo ""
if [[ $failures -eq 0 ]]; then
    echo "all tests passed"
else
    echo "test suite: failures detected"
    exit 1
fi
exit 0
