# githooks/

## Purpose

Git hooks for the secret and privacy gates: pre-commit (betterleaks) and pre-push (betterleaks + IPADP L2 privacy check).

## Ownership

Agents touching gate scripts or secret handling.

## Local Contracts

- Activate per clone: `git config core.hooksPath githooks` (local setting, not committed).
- Fail-closed: hooks exit 1 when `betterleaks` is missing or a scan finds leaks; pre-push also blocks on privacy-check failure.
- pre-commit runs `betterleaks git "$REPO_ROOT"` (REPO_ROOT resolved from the script path, not the CWD); pre-push runs `betterleaks git "$REPO_ROOT"` plus `.specify/scripts/bash/check-privacy-leaks.sh`.

## Work Guidance

- Gate changes follow test-first RED-GREEN-REFACTOR via `bash tests/run.sh` (constitution I); the pre-push gate must surface the checker findings, not only block.
- Hooks resolve the repo root from their own path, never from the CWD.

## Verification

- `bash githooks/pre-commit` exits 0 on a clean repo.
- `bash githooks/pre-push` exits 0 on a clean repo.

## Child DOX Index

None.
