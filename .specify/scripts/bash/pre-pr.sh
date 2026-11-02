#!/usr/bin/env bash
# pre-pr.sh — local health check to run before pushing a PR (IPADP Phase 4.5).
#
# Runs the same validation suite that CI enforces, so failures are caught
# locally before spending a CI run.  Fail-fast: any step failure aborts
# immediately with a non-zero exit code.
#
# Gate stack - only tools that exist in this repo (bash on arm64/Debian 13,
# no Python toolchain: no uv, no ruff, no pytest):
#   [1] bash -n over every tracked *.sh
#   [2] test suite (tests/run.sh; runs with PRE_PR_RUNNING=1)
#   [3] privacy leak check (.specify/scripts/bash/check-privacy-leaks.sh)
#   [4] betterleaks secret scan
#   [5] upstream-sync check (non-fatal)
#   [6] tool provenance (only when SATWARE_HARNESS is set)
#
# Exit codes:
#   0  all checks passed
#   1  one or more checks failed

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../" && pwd)"

echo "=== pre-pr: local health check ==="
echo "Repo: $REPO_ROOT"
date

# 1. Bash syntax over every tracked *.sh
echo ""
echo "[1/6] bash -n over tracked *.sh..."
sh_files=()
while IFS= read -r -d '' sh; do
    sh_files+=("$sh")
done < <(git -C "$REPO_ROOT" ls-files -z '*.sh')
if [ "${#sh_files[@]}" -eq 0 ]; then
    echo "   ERROR: no tracked *.sh files found (git ls-files failed or repo changed)"
    echo "   bash -n FAILED - fix before pushing"
    exit 1
fi
for sh in "${sh_files[@]}"; do
    if ! bash -n "$REPO_ROOT/$sh" 2>/dev/null; then
        echo "   syntax error in $sh"
        echo "   bash -n FAILED - fix before pushing"
        exit 1
    fi
done
count=${#sh_files[@]}
echo "   $count shell script(s) checked, all syntactically valid"

# 2. Test suite (PRE_PR_RUNNING guards tests/run.sh from recursing
#    through test-pre-pr.sh back into this script)
echo ""
echo "[2/6] tests/run.sh..."
if ! PRE_PR_RUNNING=1 bash "$REPO_ROOT/tests/run.sh" >/dev/null; then
    echo "   tests FAILED - re-run 'bash tests/run.sh' for detail"
    exit 1
fi
echo "   tests passed"

# 3. Privacy leak check
echo ""
echo "[3/6] check-privacy-leaks.sh..."
if ! "$REPO_ROOT/.specify/scripts/bash/check-privacy-leaks.sh" "$REPO_ROOT"; then
    echo "   privacy check FAILED - fix before pushing"
    exit 1
fi
echo "   privacy check passed"

# 4. betterleaks secret scan (AGENTS.md secret gate, no gitleaks fallback)
echo ""
echo "[4/6] betterleaks git..."
if ! command -v betterleaks >/dev/null 2>&1; then
    echo "   WARN: betterleaks not found - secret scan skipped"
    echo "        (pre-push hook enforces it; install betterleaks to close the gap)"
else
    if ! betterleaks git "$REPO_ROOT" >/dev/null 2>&1; then
        echo "   betterleaks FAILED - leaks found, do not push"
        exit 1
    fi
    echo "   betterleaks clean"
fi

# 5. Upstream-sync check (non-fatal: a missing 'upstream' remote is expected
#    for a standalone clone and does not block the PR)
echo ""
echo "[5/6] check-upstream-sync.sh..."
if "$REPO_ROOT/.specify/scripts/bash/check-upstream-sync.sh"; then
    echo "   upstream-sync check completed"
else
    echo "   upstream-sync check reported issues (non-fatal)"
fi

# 6. Tool provenance (rules/tool.provenance.md in the satware harness):
#    the spec-kit CLI must be the satwareAG fork at a release tag.
echo ""
echo "[6/6] tool provenance..."
if [ -n "${SATWARE_HARNESS:-}" ] && [ -x "$SATWARE_HARNESS/scripts/check-speckit-cli.sh" ]; then
    if "$SATWARE_HARNESS/scripts/check-speckit-cli.sh"; then
        echo "   provenance check passed"
    else
        echo "   provenance check FAILED"
        exit 1
    fi
else
    echo "   skipped (SATWARE_HARNESS not set or check-speckit-cli.sh not found)"
fi

echo ""
echo "=== pre-pr: all checks passed ==="
exit 0
