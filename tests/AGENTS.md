# tests/

## Purpose

Runnable bash test suite for the gate scripts (constitution I): privacy checker, eod.sh, pre-pr.sh. No Python toolchain exists in this repo (no pytest, no ruff, no uv) - tests are bash only.

## Ownership

Agents working on gate scripts (`.specify/scripts/bash/`) and the secret/privacy gates.

## Local Contracts

- Runner: `bash tests/run.sh` runs every top-level `test-*.sh`; exit 0 = all pass.
- State-changing and real-hardware tests live in `tests/sandbox/`, never in the top-level suite (reserved lane: sandboxed container sshd port 2222, key-only by design).
- Sandbox runs are journaled in `logs/` at execution time (constitution V).
- Fixtures are staged (`git add -f`), scanned, then removed; tests must leave the tree unmodified (EXIT trap).

## Work Guidance

- Tests target the real stack: actual scripts on the repo, never a mock toolchain.
- New gate changes follow test-first RED-GREEN-REFACTOR (constitution I) with negative controls.
- No full IP addresses or private hostnames in test content (the privacy gate scans tracked files, including tests).

## Verification

- `bash tests/run.sh` exits 0.
- `bash .specify/scripts/bash/pre-pr.sh` exits 0 on a clean repo (re-runs the suite under `PRE_PR_RUNNING=1`).

## Child DOX Index

None.
