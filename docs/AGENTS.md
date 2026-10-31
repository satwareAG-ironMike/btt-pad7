# docs

## Purpose
Public documentation for the BTT PAD 7 (CB1). `README.md` is the public entry point with the full verified device/driver inventory; `docs/hardware/` holds per-domain device pages; `logs/` is the append-only state-change journal.

## Ownership
Repo maintainers. Every hardware claim must be re-verified by read-only SSH against the live CB1 before commit.

## Local Contracts
- `README.md`: self-contained public overview; no private-network detail (Constitution VI).
- `docs/hardware/AGENTS.md`: local contracts for the per-domain pages.
- `logs/*.md`: journal entries, five fields (what/where/when/why/result), plain text, small (SD-card write discipline).

## Work Guidance
- Facts carry a verification date and an evidence file in `logs/*.md`.
- No secrets, credentials, private IPs (10.x / 172.16-31.x / 192.168.x), or private/internal URLs - this is a public repo (Constitution VI).
- No em dash or en dash in any output; hyphen only.
- New domain: one markdown page per subsystem family under `docs/hardware/`, plus a Child DOX Index row; one intent per commit.

## Verification
`bash .specify/scripts/bash/check-privacy-leaks.sh` must exit 0 (no private URLs/IPs/credential patterns in tracked files).

## Child DOX Index

| Path | Scope | File |
|------|-------|------|
| docs/hardware/ | per-domain device pages for the CB1 | docs/hardware/AGENTS.md |
