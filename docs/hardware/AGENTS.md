# docs/hardware

## Purpose
Per-domain hardware pages for the BTT PAD 7 (CB1, Allwinner H616). Each page covers one subsystem family: verified facts with dates and evidence, public online resources, and drift notes when state changed across re-verifications.

## Ownership
Repo maintainers. Pages are only updated after live read-only verification on the CB1 (`ssh bttpad7`).

## Local Contracts
One markdown file per domain, snake_case, in this directory. Current domains:

| Domain | File |
|--------|------|
| SoC and display pipeline | soc-display.md |
| GPU (Mali-G31 MP1) | gpu.md |
| Ethernet, WLAN, Bluetooth | network.md |
| USB hosts, hub, panel, optional accessories | usb.md |
| CAN (mcp2515) and SPI | can-spi.md |
| I2C, power, GPIO, PWM, thermal | i2c-power.md |
| Audio (ALSA cards) | audio.md |
| RTC, wall clock, watchdog | timing.md |
| LEDs and frame-buffer access | leds-gpios.md |
| Storage, zram, serial | storage-serial.md |

## Work Guidance
- Required sections: `## Verified facts` (table: device node / driver / state, with verification date), `## Online resources` (public URLs only), `## Drift and notes` (only when state changed between re-verifications; otherwise omit).
- Facts cite evidence in `logs/*.md` with a date (e.g. "dmesg 2026-10-31", "2026-10-28 survey").
- State changes (device attached/removed, config changed, re-verification) get a journal entry in `logs/YYYY-MM-DD-<topic>.md` at execution time, before the page is updated.
- No private network detail (Constitution VI): no LAN IPs, no credentials, no private URLs.
- One intent per commit; page changes and any DOX index row change land together.

## Verification
`bash .specify/scripts/bash/check-privacy-leaks.sh` on the repo root must exit 0.

## Child DOX Index
No child boundaries yet; the ten domain pages are content, not DOX boundaries.
