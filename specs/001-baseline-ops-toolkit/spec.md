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
(`can0`, mcp2515), SPI (`/dev/spidev1.1`), I2C buses, HDMI panel (including
its touch input), WS2812 LED, the USB camera (`/dev/video0`) and its mic,
audio cards (codec/HDMI/camera), WLAN, LEDs, and serial ports - present,
enabled, and link state where available.

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
- **FR-002**: System MUST report each peripheral from the Hardware Baseline
  section (CAN, SPI, I2C, display + touch, LED incl. WS2812, camera, audio
  cards, WLAN, serial) as present/absent with state detail where available.
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

## Hardware Baseline (verified)

Inventory first probed 2026-10-28 on the live CB1; re-verified 2026-10-31.
Evidence in `logs/2026-10-28-hardware-survey.md`,
`logs/2026-10-28-camera-quality.md`, and `logs/2026-10-31-hardware-reverify.md`;
per-domain pages with online resources in `docs/hardware/`. The probe (US2)
targets exactly this surface.

| Subsystem | Verified fact |
|-----------|---------------|
| SoC | Allwinner H616 (`bigtreetech,cb1` DT), 4x Cortex-A53, OPPs 480 MHz-1512 MHz, ondemand; 4 thermal zones (~52 C) |
| Memory | 992 MB RAM; zram0 ~485 MB swap; zram1 50 MB ext4 on `/var/log`; zram2 unconfigured |
| Storage | 32 GB SD (mmcblk1 at 2026-10-31 reverify): vfat `/boot` (256 M) + ext4 `/` (29.2 G); 2 mmc hosts (mmc0 SDIO WiFi, mmc1 SD card) |
| CAN | `can0` = mcp2515 on SPI `spi1.0` (2026-10-31 reverify), INT on gpio-73, 1 Mbit/s, sample-point 0.666, ERROR-ACTIVE |
| SPI | host spi1 (5011000): spi1.0 (10 MHz max, mcp2515), spi1.1 (1 MHz max, unbound spidev) |
| I2C | 4 buses; i2c-0 ac200-sunxi @0x10 (probe fails -22, ac300 detected); i2c-1 axp313a PMIC @0x36 |
| Display | `fb0` 1024x600 @32bpp (raw writes work for the `video` group, no sudo); HDMI-A-1 connected, EDID product "Lontium Semiconductor", modes 1024x600 + 640x480; sun4i-drm (display-engine) + sun8i-dw-hdmi 6000000; panel is a TOUCHSCREEN (HID "BIQU BTT-HDMI7"); CEC module loaded; GPU render node only (`renderD128`) |
| Audio | card0 sun4i codec: playback works; card1 HDMI: PCM registered, stream open fails ("Channels count non available"); camera card2 absent (camera unconnected, 2026-10-31) |
| Camera | optional USB: 1415:2000 gspca/ov534, sensor OV7721: YUYV only (no MJPG), max 640x480, fixed focus (no focus control), mic; unconnected at 2026-10-31 reverify |
| WLAN | Realtek RTL8189FS on SDIO (024c:f179), driver `8189fs`, power GPIOs high, unassociated |
| Bluetooth | absent silicon (WiFi-only module); BlueZ units + rtl_bt firmware are image carry-overs |
| Ethernet | sunxi-gmac internal ephy, 100 Mbit/s full-duplex |
| LEDs | `led_work` (blue, gpio-229 active-low), `wifi_power`, `wifi_wake`; WS2812 on gpio-78: `leds_ws2812` loaded, no LED-class entry ("present-but-down" case for US2) |
| PWM/GPIO | pwmchip0 npwm=6 (no pwmN exports); gpiochip0 sunxi 288 pins, gpiochip1 R_PIO 32 |
| Timing | sun6i-rtc rtc0 unconfigured (kernel sets 1970-01-02T00:00:04 UTC at boot); sunxi-wdt 16 s timeout, nowayout=0 |
| Serial | 8x sunxi UART (ttyS0-7); no ttyUSB (CH340 unconnected, 2026-10-31) |
| Misc | `/sys/class/fbdev/` absent (2026-10-31); Docker installed |

## Assumptions

- The CB1 stays reachable at `ssh bttpad7` during development; destructive
  tests use the sandboxed container sshd (port 2222).
- Workstation cross-build toolchain availability is a plan-phase concern, not
  a spec constraint.
- `logs/` lives in the repository and is committed alongside the change it
  records.
- v1 scope is read-only probes plus journal append; no remediation actions
  (e.g. loading modules) in this feature.
