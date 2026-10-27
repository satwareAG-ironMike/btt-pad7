# Feature Specification: Baseline Ops Toolkit

**Feature Branch**: `001-baseline-ops-toolkit`

**Created**: 2026-10-27

**Status**: Draft

**Input**: User description: "Baseline ops toolkit: inventory + health-check tooling for the CB1 (system state, hardware probes, logs/ journal)"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Device Snapshot (Priority: P1)

As an operator, I run one command against the CB1 and get the complete current
state of the machine: OS/kernel, CPU, memory, storage, uptime, load.

**Why this priority**: Everything later (CAN tooling, panel apps) needs a
trustworthy device-state baseline; without it every diagnosis is anecdote.

**Independent Test**: SSH to the CB1, run the toolkit's snapshot command, and
verify the reported values against ground-truth tools (`uname`, `free`,
`df`, `lsb_release`). Delivers value on its own.

**Acceptance Scenarios**:

1. **Given** a booted CB1, **When** the snapshot command runs, **Then** it
   reports OS release, kernel version, CPU model/cores, total/free memory,
   root filesystem size/usage, and uptime.
2. **Given** the snapshot output, **When** validated with `jq`, **Then** the
   JSON parses with exit 0 and contains the named fields.

---

### User Story 2 - Peripheral Probe (Priority: P2)

As an operator, I list the status of the CB1's hardware peripherals: CAN
(`can0`, mcp2515), SPI (`/dev/spidev1.1`), I2C buses, HDMI panel, WS2812 LED
device nodes - present, enabled, and link state where available.

**Why this priority**: The hardware inventory is the prerequisite for the
later CAN/LED/panel features and shows which interfaces are usable at all.

**Independent Test**: Run the probe command and compare its findings with the
device nodes and `ip -d link show can0` on the CB1.

**Acceptance Scenarios**:

1. **Given** CAN is configured on the CB1, **When** the probe runs, **Then**
   it reports `can0` with its link state and driver.
2. **Given** a peripheral is absent (e.g. CAN module not loaded), **When**
   the probe runs, **Then** that peripheral is reported as absent, not as an
   error.

---

### User Story 3 - Hardware Journal (Priority: P3)

As an operator, I record every CB1 state change (what, where, when, why,
result) into `logs/` with one append-only entry per change, and list recent
entries.

**Why this priority**: Constitution article V requires journaling; the
toolkit makes it a command instead of a manual habit.

**Independent Test**: Append an entry via the journal command, list entries,
verify the recorded fields and that the file is plain text.

**Acceptance Scenarios**:

1. **Given** a completed CB1 change, **When** I journal it, **Then** a new
   entry with the five fields (what, where, when, why, result) appears.
2. **Given** the journal, **When** listed, **Then** entries display newest
   first.

---

### Edge Cases

- Peripheral absent vs peripheral present-but-down: both must be reported
  distinctly, never conflated with a tool error.
- Journal append must survive low-disk conditions and not silently truncate.
- Snapshot must run under ~1 GB RAM without swap pressure spikes.
- Non-TTY invocation (pipe, cron) must still produce valid output.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST report the CB1's OS/kernel, CPU, memory, storage,
  and uptime in one snapshot invocation.
- **FR-002**: System MUST report each named hardware peripheral (CAN, SPI,
  I2C, HDMI, LED) as present/absent with state detail where available.
- **FR-003**: All command output MUST be available as JSON and as
  human-readable text; `jq` must parse the JSON mode.
- **FR-004**: System MUST support appending and listing journal entries in
  `logs/` with the five-field format from the constitution.
- **FR-005**: The toolkit MUST run on the CB1 without installing language
  runtimes (statically linked binaries).
- **FR-006**: System MUST exit 0 on success and use distinct non-zero exit
  codes for usage error, tool error, and probe-degraded.
- **FR-007**: Implementation language MUST be Rust, compiled to statically
  linked arm64 binaries cross-built on the workstation.

### Key Entities

- **SnapshotRecord**: point-in-time device state (os, kernel, cpu, mem,
  storage, uptime).
- **PeripheralEntry**: one hardware interface with presence, state, and
  originating device node.
- **JournalEntry**: one recorded hardware state change (what, where, when,
  why, result).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A full snapshot completes on the CB1 in under 2 seconds.
- **SC-002**: Snapshot JSON parses with `jq` on the CB1 or workstation with
  exit 0 in 100% of runs.
- **SC-003**: Reported values match ground-truth tools byte-for-bite on a
  live CB1 in an end-to-end check.
- **SC-004**: Toolkit binary footprint stays ≤ 1 MB per binary on arm64.

## Clarifications

### Session 2026-10-27

- FR-007: Rust chosen as the implementation language (static arm64 binaries,
  cross-built on the workstation).
- v1 scope confirmed: all three user stories (snapshot, peripheral probe,
  journal) stay in v1 as drafted.

## Assumptions

- The CB1 stays reachable at `ssh bttpad7` during development; destructive
  tests use the sandboxed container sshd (port 2222).
- Workstation cross-build toolchain availability is a plan-phase concern, not
  a spec constraint.
- `logs/` lives in the repository and is committed alongside the change it
  records.
- v1 scope is read-only probes plus journal append; no remediation actions
  (e.g. loading modules) in this feature.
