#!/usr/bin/env bash
# sod.sh — Start-of-Day protocol for spec-kit (IPADP Phase 3.2).
#
# References the harness SoD protocol when the harness repo is available
# (default: ~/internal/harness) and runs the repo's privacy + upstream-sync
# checks.  Override with HARNESS_DIR env var.
#
# Exit codes:
#   0  all checks passed
#   1  one or more checks failed

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CLINE_DIR="${HARNESS_DIR:-$HOME/internal/harness}"
PROTOCOL="$CLINE_DIR/workflows/sod.protocol.md"

echo "=== Start-of-Day protocol ==="
echo "Repo: $REPO_ROOT"
date

if [ -f "$PROTOCOL" ]; then
    echo ""
    echo "📖 SoD protocol: $PROTOCOL"
    echo "    (review manually - agents SHOULD follow its steps)"
else
    echo ""
    echo "⚠️  Harness not found at $CLINE_DIR - skipping protocol reference."
    echo "    Set HARNESS_DIR env var or clone the harness repo to enable."
fi

fail=0

echo ""
echo "🔒 Running privacy leak check..."
if "$REPO_ROOT/scripts/bash/check-privacy-leaks.sh" "$REPO_ROOT"; then
    echo "✅ privacy check passed"
else
    echo "❌ privacy check FAILED"
    fail=1
fi

echo ""
echo "🔄 Running upstream sync check..."
if "$REPO_ROOT/scripts/bash/check-upstream-sync.sh"; then
    echo "✅ upstream-sync check completed"
else
    echo "⚠️  upstream-sync check reported issues (non-fatal)"
fi

echo ""
if [ "$fail" -eq 0 ]; then
    echo "🌅 SoD complete — ready for deep work."
else
    echo "🚧 SoD finished with failures — address them before proceeding."
fi
exit "$fail"
