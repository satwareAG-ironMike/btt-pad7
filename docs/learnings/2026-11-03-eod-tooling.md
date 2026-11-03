# 2026-11-03: EOD evidence and tooling (btt-pad7)

Context: EOD for 2026-11-03, main @ a36c161. Captures toolchain quirks hit
during the gate merge and EOD run, plus the one verified security finding.

## Tooling quirks (this environment)

### `gh` build 2.103.3 (satwareAG-ironMike) - non-standalone flags
- `gh --auth status` -> "unknown flag". Use `gh auth status` (subcommand).
- `gh api ... --json ...` -> "unknown flag". Use `-q/--jq` or pipe to `jq`.
- `gh issue create --milestone 2` -> "could not add to milestone '2': '2' not found",
  even though the milestone exists. Workaround: create the issue without a
  milestone, then `gh api repos/<o>/<r>/issues/<n> -X PATCH -f milestone=<m>`.
  The PATCH form accepts the numeric milestone id; the create subcommand does not.
- `gh api repos/.../issues -f state=open` switches the method to POST (422,
  "title wasn't supplied"). Use the encoded query string instead:
  `repos/.../issues?state=open`.
- jq reserved-word gotcha: in `{...}` object construction, `.state` and `.title`
  must be `.state` / `.title` (dotted). A bare `state:` / `title:` key value
  resolves to a jq builtin, not the field.
- jq comma/pipe precedence: `a, b | c` is `(a, b) | c`. To emit total then rows
  use explicit `def` or `@json` per element, not a bare comma pipeline.

### `grep` on this toolchain
- `grep -F '...^...'` treats a leading `^` as LITERAL (fixed-string mode).
  The `test-githooks-contract.sh` "Work Guidance" anchor therefore uses regex
  mode (`grep -q '^## Work Guidance'`), not `-F`.

### `bash` 5.3.20 parser
- `out="$(cmd 2>&1) || rc=$?` immediately before an `if` block whose then-branch
  starts with a quoted `(` was rejected (parse error). Workaround used by
  `test-pre-push.sh`: run the hook writing output to a temp file
  (`bash "$HOOK" >"$tmpout" 2>&1 || rc=$?`), then inspect `$tmpout` separately.

## Verified security finding (issue #12)

`githooks/pre-commit`, `githooks/pre-push`, and `.specify/scripts/bash/pre-pr.sh`
run only `betterleaks git "$REPO_ROOT"` (Phase A: git history/unpushed). Untracked
working-tree files (Phase B) are not scanned.

Probed 2026-11-03. The gate matches the AKIA pattern, not a specific value, so
the full literal is NOT recorded here (a real key would be the same shape):
- seed an AKIA-prefixed 20-char token into a fresh untracked file
- `betterleaks git .` -> rc=0, "no leaks found" (untracked file NOT seen)
- `betterleaks dir <dir> --config .betterleaks.toml --` -> 1 leak (dir mode sees it)


Fix (tracked, not fixed inline): add a fail-closed Phase B scan to each hook:
`git -c core.quotepath=off ls-files -z --cached --others --exclude-standard | xargs -0 -n300 betterleaks dir --config .betterleaks.toml --`
plus a RED negative-control test. See btt-pad7 issue #12.

## Status of the day

- PR #10 merged to main @ a36c161 (squash). 3 review findings fixed.
- Unlazy gates G1-G7 met; GATES.md removed.
- Branches chore/sdd-scaffold + fix/gates deleted (origin + local). Only main remains.
- Tree clean, pushed, no stashes.
- `bash tests/run.sh` -> 5/5 green. `betterleaks git .` -> clean.
