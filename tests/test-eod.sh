#!/usr/bin/env bash
# tests/test-eod.sh - eod.sh end-to-end (constitution I/IV, AC1 of issue #7).
#
# eod.sh must invoke the privacy checker from the path that exists in this
# repo (.specify/scripts/bash/) and exit 0 on a clean repo.  This test fails
# against the missing scripts/bash/ path and passes once the path is fixed.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"

if ! bash "$REPO_ROOT/.specify/scripts/bash/eod.sh" >/dev/null; then
    echo "FAIL: eod.sh exited non-zero (privacy checker path broken?)" >&2
    exit 1
fi
echo "ok: eod.sh runs the privacy check and exits 0 on a clean repo"
