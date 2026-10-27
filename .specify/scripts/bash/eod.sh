#!/usr/bin/env bash
# eod.sh — End-of-Day protocol for spec-kit (IPADP Phase 3.2).
#
# References the harness EoD protocol when the harness repo is available
# (default: ~/internal/harness) and runs the repo's privacy check before
# session close.  Override with HARNESS_DIR env var.
#
# Exit codes:
#   0  all checks passed
#   1  privacy check failed

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CLINE_DIR="${HARNESS_DIR:-$HOME/internal/harness}"
PROTOCOL="$CLINE_DIR/workflows/eod.protocol.md"

echo "=== End-of-Day protocol ==="
echo "Repo: $REPO_ROOT"
date

if [ -f "$PROTOCOL" ]; then
    echo ""
    echo "📖 EoD protocol: $PROTOCOL"
    echo "    (review manually - agents SHOULD follow its steps)"
else
    echo ""
    echo "⚠️  Harness not found at $CLINE_DIR - skipping protocol reference."
fi

fail=0

echo ""
echo "🔒 Running privacy leak check (pre-push safety net)..."
if "$REPO_ROOT/scripts/bash/check-privacy-leaks.sh" "$REPO_ROOT"; then
    echo "✅ privacy check passed"
else
    echo "❌ privacy check FAILED — do not push until resolved."
    fail=1
fi

echo ""
if [ "$fail" -eq 0 ]; then
    echo "🌇 EoD complete — safe to wrap up."
else
    echo "🚧 EoD finished with failures — address privacy issues before pushing."
fi
exit "$fail"
