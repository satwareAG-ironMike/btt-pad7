#!/usr/bin/env bash
# tests/test-pre-pr.sh - pre-pr.sh end-to-end (constitution I, IV; AC2 of issue #7).
#
# pre-pr.sh must gate on the stack that exists in this repo (bash scripts:
# bash -n, tests, privacy, betterleaks, sync) and exit 0 on a clean repo.
# It fails against the missing src/ + tests/ Python gate.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"

if ! bash "$REPO_ROOT/.specify/scripts/bash/pre-pr.sh" >/dev/null; then
    echo "FAIL: pre-pr.sh exited non-zero (broken gate stack?)" >&2
    exit 1
fi
echo "ok: pre-pr.sh runs the real gate stack and exits 0 on a clean repo"
