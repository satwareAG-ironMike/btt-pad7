# 2026-10-31 - CB1 hardware re-verification (read-only SSH)

| Field | Value |
|-------|-------|
| what | re-verify the 2026-10-28 device/driver inventory before publishing hardware docs (EDID, connector, touch, state drift) |
| where | bttpad7 CB1 |
| when | 2026-10-31 (board clock; box up since 2026-10-29 11:10:24, ~1d 20h at probe time) |
| why | publish `docs/hardware` and the spec-001 baseline on verified facts, not stale ones |
| result | most facts hold; EDID confirmed populated; connector connected; camera and CH340 absent; `/sys/class/fbdev/` absent |

## Confirmed

| Area | Finding |
|------|---------|
| Kernel | 7.0.2-vendor-sunxi64 (Armbian 26.8.3 Trixie) |
| EDID | populated; `/sys/class/drm/card0/card0-HDMI-A-1/edid` (lowercase path, 4096 B block); product string "Lontium Semiconductor"; 2 preferred timing blocks; CEC + EDID-Aux blocks. Earlier probes reported "EDID empty" because they probed the wrong path (capital `card0/EDID`) |
| Connector | `card0/card0-HDMI-A-1` status `connected`; exposed modes: 1024x600, 640x480 |
| DRM/GPU | sun4i-drm card0 (display-engine); panfrost card1 (renderD128, Mali-G31 MP1 id 0x7093) |
| Audio | card0 "Codec" (sun4i-codec, `soc/5096000.codec`, h616-audio-codec); card1 "HDMI" (`snd_soc_hdmi_codec`, `soc:ahub1_mach`) |
| USB | 8 root hubs: ehci-platform bus1-4 (USB 2.0, 480 M) + ohci-platform bus5-8 (12 M); bus2 Terminus hub 1a40:0101 carries 04d9:8030 BTT-HDMI7 (usbhid, full-speed 12 M) |
| CAN | can0 UP, ERROR-ACTIVE, bitrate 1000000, sample-point 0.666, mtu 16; mcp2515 on SPI spi1.0 (supersedes the 2026-10-28 survey note "spidev1.1") |
| SPI | host spi1 (5011000): spi1.0 (max 10 MHz, mcp251x bound), spi1.1 (max 1 MHz, unbound spidev) |
| I2C | axp313a PMIC @ i2c-1/0x36 (axp20x-i2c); AC300/ac200 codec @ i2c-0/0x10 (ac200-sunxi probe failed -22) |
| PWM | pwmchip0 npwm=6, export dir empty (no pwmN) |
| Thermal | hwmon0-3: temp1_input 52307 / 52064 / 53198 / 52388 (mC, ~52 C) |
| WS2812 | leds_ws2812 loaded |
| RTC | sun6i-rtc rtc0 unconfigured; kernel set system clock to 1970-01-02T00:00:04 UTC (86404) at boot |
| Serial | ttyS0-7 present |
| Storage | mmcblk1 (179:0) 29.7 G: p1 256 M /boot, p2 29.2 G /; zram0 484.6 M [SWAP], zram1 50 M /var/log, zram2 0; mmc0 (SDIO WiFi), mmc1 (SD card) |
| Display | `/dev/fb0` present (crw-rw---- root:video); fb0 1024x600 @ 32 bpp |
| LEDs | led_work, wifi_power, wifi_wake present in `/sys/class/leds` |
| Input | `/dev/input/event0`, `event1` (panel USB HID touch) |

## Drift vs 2026-10-28 survey

| Item | 2026-10-28 | 2026-10-31 | Note |
|------|------------|------------|------|
| USB camera 1415:2000 | present (gspca, /dev/video0, 2 audio interfaces incl. mic) | absent | gspca not loaded; card2 (camera mic) also gone; optional accessory |
| CH340 serial 1a86:7523 | present (/dev/ttyUSB0) | absent | dmesg: `ch341-uart ttyUSB0: ... disconnected` at 2181 s into boot |
| CAN SPI child | survey note "spidev1.1" | spi1.0 (readlink of can0 device) | spi1.1 holds only an unbound spidev |
| SD node | mmcblk0 | mmcblk1 (179:0) | enumeration order follows the SDIO WiFi host; shifts across reboots |
| zram0 size | 508 M | 484.6 M | sizing varies |
| /sys/class/fbdev/ | present | absent | /dev/fb0 still present |
| RTC wall clock | - | stepped ~10 h 35 m between two reads the same day | NTP suspected, unverified |
| ethtool / rfkill | - | not installed | future tooling needs fallbacks |
