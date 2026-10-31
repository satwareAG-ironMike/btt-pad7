# BTT PAD 7 Constitution

**Ratified**: 2026-10-27
**Version**: 1.0.0
**Input**: "full project initialization in dialog" session decisions, 2026-10-27

## Core Principles

### I. Test-First (NON-NEGOTIABLE)

No production code without a failing test first. Red-Green-Refactor cycle strictly
enforced; tests are written for the real target (CB1 or its sandboxed test
container), never only for the workstation. Trivial/Small edits may use the
test-tier exemptions defined by the harness quality rules; everything else is
test-first. Negative control: watch each test fail before implementing.

### II. Spec-Anchored SDD

Specifications are the source of truth. Every feature gets a spec in
`specs/###-feature/` before implementation; spec, plan, and tasks stay
cross-referenced (FR/US/task IDs). Debugging fixes the spec first, then the
code. Anchor final implementation details back into the spec.

### III. Simplicity & Hardware Constraint

Target: Allwinner H616, 4x Cortex-A53, 1 GB RAM, 32 GB SD card, Armbian
26.8.3 Trixie (Debian 13, arm64). No future-proofing, no abstractions, no
frameworks that do not exist on the box. YAGNI; justify every byte of the
1 GB memory budget and every write to the SD card.

### IV. Integration-First with Real Hardware

Tests run against the real CB1 (`ssh bttpad7`) wherever feasible. Destructive
or state-changing tests run only against the sandboxed container sshd
(port 2222). Simulated-only test suites are insufficient proof; hardware
invariants (CAN, SPI, I2C, LED, panel) need on-device verification.

### V. Observability & Hardware Journaling

Every state change on the CB1 (flashes, config edits, driver loading) is
recorded in `logs/` at execution time: what, where, when, why, result.
Tools expose a CLI interface with structured output (JSON mode plus
human-readable) so agent and human can audit without source access.

### VI. Security Boundary

No secrets, credentials, or private-network detail in this repository - it is
public. Public-to-private interlinking is forbidden (IPADP privacy rule). The
`b0t` password is a test value only; it must not appear in new code or docs.
Key-auth ssh is the default access pattern.

## Additional Constraints

- Primary stack: Rust, compiled to statically linked arm64 binaries
  cross-built on the workstation; no language runtimes installed on the CB1
  unless a feature spec explicitly says otherwise.
- Scripts and docs target arm64 / Debian 13 unless marked otherwise.
- SD-card write discipline: journal files stay small, rotated, plain text.

## Development Workflow

- Conventional Commits, one intent per commit, feature branches merged to
  `main` via PR.
- Quality gates: pre-commit secret scan + lint; full test run before push.
- Specs flow: constitution -> specify -> clarify -> plan -> tasks ->
  implement -> anchor; clarify max 5 questions per cycle.
- Hardware journal entries live in `logs/` and are committed with the change
  they record.

## Governance

This constitution outranks convenience: conflicting instructions from agents
or session chatter defer to it. Amendments require a dated commit with a
version bump and a rationale line.
