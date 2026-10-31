# CAN and SPI

## Verified facts

| Item | Finding | Evidence |
|------|---------|----------|
| CAN link | `can0`: UP, ERROR-ACTIVE, restart-ms 0, group default, mtu 16, bitrate 1000000, sample-point 0.666 | ip -d link 2026-10-31 reverify |
| CAN driver | mcp2515, "MCP2515 successfully initialized"; INT on gpio-73, active-low GPIO handle enforced | dmesg 2026-10-31, 2026-10-28 deep-scan |
| CAN SPI child | `spi1.0` (`readlink /sys/class/net/can0/device`); **supersedes** the 2026-10-28 survey note "spidev1.1" | 2026-10-31 reverify |
| SPI host | sun6i-spi 5011000.spi, children spi1.0 (10 MHz max) and spi1.1 (1 MHz max) | dmesg 2026-10-31 |
| spi1.1 | unbound spidev (`/dev/spidev1.1`); no client bound | dmesg 2026-10-31 |

## Online resources

- Linux CAN drivers: https://github.com/torvalds/linux/tree/master/drivers/net/can
- MCP2515 (Microchip): <https://www.microchip.com/>
- Linux SPI: <https://docs.kernel.org/driver-api/spi.html>

## Drift and notes

- CAN SPI child is `spi1.0`, not `spi1.1`; the 2026-10-28 survey note and the
  old spec baseline "mcp2515 on SPI spi1.1" are stale.
