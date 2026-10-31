# Network

## Verified facts

| Item | Finding | Evidence |
|------|---------|----------|
| Ethernet | eth0, sunxi-gmac (5030000.ethernet), internal PHY, 100 Mbit/s full-duplex, link up (carrier=1) | 2026-10-28 survey, 2026-10-31 reverify |
| MAC | 5a:42:ee:9d:b8:4a | 2026-10-28 survey |
| WLAN | wlan0, Realtek RTL8189FS (024c:f179) on SDIO mmc0, driver 8189fs, present and unassociated; power GPIOs high; `rfkill` not installed on the box | 2026-10-28 survey, 2026-10-31 reverify |
| Bluetooth | no silicon (WiFi-only SDIO function); BlueZ/bluealsa and the rtl_bt firmware set are image carry-overs with nothing to drive them | 2026-10-28 survey |
| Bridging | Docker installed; docker0 + bridge at survey time | 2026-10-28 survey |
| Tooling | `ethtool` not installed - link speed is read from dmesg/sunxi-gmac, not ethtool | 2026-10-31 reverify |

## Online resources
- sunxi-gmac driver: https://github.com/torvalds/linux/tree/master/drivers/net/ethernet/sunxi
- Linux networking docs: <https://docs.kernel.org/networking/>
- Realtek (8189FS chip): https://www.realtek.com/
- Armbian wiki: https://wiki.armbian.org/
