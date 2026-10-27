#!/usr/bin/env bash
# pre-pr.sh — local health check to run before pushing a PR (IPADP Phase 4.5).
#
# Runs the same validation suite that CI enforces, so failures are caught
# locally before spending a CI run.  Fail-fast: any step failure aborts
# immediately with a non-zero exit code.
#
# Exit codes:
#   0  all checks passed
#   1  one or more checks failed

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=== pre-pr: spec-kit local health check ==="
echo "Repo: $REPO_ROOT"
date

fail=0

# 1. Ruff lint (matches CI: uvx ruff@0.15.0 check src tests)
echo ""
echo "[1/5] ruff check src/ tests/..."
if uvx ruff@0.15.0 check "$REPO_ROOT/src/" "$REPO_ROOT/tests/"; then
    echo "   ruff passed"
else
    echo "   ruff FAILED"
    fail=1
fi

# 2. Integration tests (stop on first failure, quiet)
echo ""
echo "[2/5] pytest tests/integrations/ ..."
if (cd "$REPO_ROOT" && uv run pytest tests/integrations/ -x -q --no-header); then
    echo "   tests passed"
else
    echo "   tests FAILED"
    fail=1
fi

# 3. Privacy leak check
echo ""
echo "[3/5] check-privacy-leaks.sh..."
if "$REPO_ROOT/scripts/bash/check-privacy-leaks.sh" "$REPO_ROOT"; then
    echo "   privacy check passed"
else
    echo "   privacy check FAILED"
    fail=1
fi

# 4. Upstream sync check
echo ""
echo "[4/5] check-upstream-sync.sh..."
if "$REPO_ROOT/scripts/bash/check-upstream-sync.sh"; then
    echo "   upstream-sync check completed"
else
    echo "   upstream-sync check reported issues (non-fatal)"
    # Non-fatal: upstream sync warnings don't block PRs
fi

# 5. Tool provenance: system `specify` must be the satwareAG fork at a release tag
#    (rules/tool.provenance.md in the satware harness). Fatal: a stale upstream
#    or editable install silently shadowing the fork is a real bug class.
echo ""
echo "[5/5] check-speckit-cli.sh (tool provenance)..."
if [ -n "${SATWARE_HARNESS:-}" ] && [ -x "$SATWARE_HARNESS/scripts/check-speckit-cli.sh" ]; then
    if "$SATWARE_HARNESS/scripts/check-speckit-cli.sh"; then
        echo "   provenance check passed"
    else
        echo "   provenance check FAILED"
        fail=1
    fi
else
    echo "   skipped (SATWARE_HARNESS not set or check-speckit-cli.sh not found)"
fi

echo ""
if [ "$fail" -eq 0 ]; then
    echo "=== pre-pr: all checks passed ==="
else
    echo "=== pre-pr: failures detected - fix before pushing ==="
fi
exit "$fail"
