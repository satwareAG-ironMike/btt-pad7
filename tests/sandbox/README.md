# tests/sandbox/ - reserved lane for state-changing and real-hardware tests (constitution IV)

These tests are **not** run by `tests/run.sh` and must never be added to it.

- Run against the real CB1 (`ssh bttpad7`) only when feasible.
- Destructive or state-changing runs go only against the sandboxed container
  sshd lane (port 2222, key-only by design).
- Every run is journaled in `logs/` at execution time (constitution V).

Naming: do not use a top-level `test-*.sh` name, or the runner picks it up.
Use `tests/sandbox/<name>.sh` and invoke it explicitly.
