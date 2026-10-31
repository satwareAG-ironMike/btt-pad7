# Storage, zram, serial

## Verified facts

| Item | Finding | Evidence |
|------|---------|----------|
| SD card | mmcblk1 (179:0) 29.7 G: p1 256 M `/boot` (vfat), p2 29.2 G `/` (ext4, also lists `/var/log.hdd` in lsblk); nominal 32 GB card | 2026-10-31 reverify |
| mmc hosts | 2 hosts: mmc0 (SDIO WiFi), mmc1 (SD card); enumeration order shifts across reboots (mmcblk0 at 2026-10-28) | 2026-10-28 survey, 2026-10-31 reverify |
| zram | zram0 ~485 M [SWAP], zram1 50 M `/var/log` (ext4), zram2 0 (unconfigured); swap sizing varies per boot (508 M at 2026-10-28) | 2026-10-31 reverify, 2026-10-28 survey |
| Serial | 8x sunxi UART (`/dev/ttyS0-7`); no ttyUSB (CH340 unconnected) | 2026-10-31 reverify |
| fbdev | `/sys/class/fbdev/` absent since 2026-10-31 reverify; `/dev/fb0` unchanged | 2026-10-31 reverify |

## Online resources

- Linux block layer: <https://docs.kernel.org/api/block.html>
- zram: <https://docs.kernel.org/admin-guide/device-mapper/zram.html>

## Drift and notes

- SD block node is mmcblk1 at 2026-10-31 (mmcblk0 at 2026-10-28): SD node
  number follows the SDIO WiFi host in enumeration order - do not hardcode it.
- CH340 serial `/dev/ttyUSB0` absent (see usb.md).
