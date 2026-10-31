# BTT PAD 7 (CB1)

Build software on the BTT PAD 7 (CB1, Allwinner H616) and manage its
installation. This repository is public: no credentials, no private-network
detail (Constitution VI, `.specify/memory/constitution.md`).

## Baseline (as of 2026-10-31)

| Item | Value |
|------|-------|
| SoC/board | Allwinner H616, device tree `bigtreetech,cb1` |
| CPU | 4x Cortex-A53, OPPs 480 MHz-1512 MHz, ondemand |
| RAM | 992 MB, zram swap |
| OS | Armbian 26.8.3 Trixie, kernel 7.0.2-vendor-sunxi64, BTT-CB1 V3.1.0 minimal |
| Storage | 32 GB SD (vfat `/boot` + ext4 `/`) + zram swap |
| Display | 7" HDMI touchscreen (Lontium EDID), `fb0` 1024x600 @32bpp |
| GPU | Mali-G31 MP1 via panfrost (render-only, `renderD128`) |
| Access | SSH, key-auth; read-only probes are the repo workflow |

## Verified device/driver inventory

Facts verified by live read-only SSH probes on the board. First survey
2026-10-28, re-verification 2026-10-31. Per-domain pages (online resources,
drift notes): [`docs/hardware/`](docs/hardware/).
Evidence: `logs/2026-10-28-hardware-survey.md`,
`logs/2026-10-28-camera-quality.md`, `logs/2026-10-31-hardware-reverify.md`.

| Subsystem | Finding |
|-----------|---------|
| SoC | H616 (`bigtreetech,cb1` DT), 4x Cortex-A53, OPPs 480 MHz-1512 MHz; 4 thermal zones (~52 C) |
| Memory | 992 MB; zram0 ~485 MB swap, zram1 50 MB `/var/log`, zram2 unconfigured |
| Storage | mmcblk1 29.7 G: p1 256 M `/boot`, p2 29.2 G `/`; 2 mmc hosts (mmc0 SDIO WiFi, mmc1 SD card) |
| CAN | `can0`: mcp2515 on SPI `spi1.0`, INT gpio-73, 1 Mbit/s, sample-point 0.666, ERROR-ACTIVE, mtu 16 |
| SPI | host spi1 (5011000): spi1.0 (10 MHz max, mcp2515), spi1.1 (1 MHz max, unbound spidev) |
| I2C | 4 buses; i2c-0 ac200-sunxi @0x10 (probe fails -22, ac300 detected), i2c-1 axp313a PMIC @0x36 |
| Display | sun4i-drm (display-engine) card0; HDMI-A-1 connected; EDID product "Lontium Semiconductor"; modes 1024x600 + 640x480; fb0 1024x600 @32bpp |
| Touch | USB HID "BIQU BTT-HDMI7" (04d9:8030) on bus 2-1.1; input0 + hidraw0 (panel is a touchscreen) |
| GPU | panfrost 1.6.0, card1/renderD128, Mali-G31 MP1 (0x7093), L2/Shader/Tiler/MMU present |
| Ethernet | eth0 sunxi-gmac 5030000, internal ephy, 100 Mbit/s full-duplex |
| WLAN | wlan0 Realtek RTL8189FS (024c:f179) on SDIO mmc0, driver 8189fs, unassociated |
| Bluetooth | no silicon (WiFi-only module); BlueZ + rtl_bt firmware are image carry-overs |
| Audio | card0 sun4i codec: playback works; card1 HDMI: stream open fails; camera card2 absent (camera unconnected) |
| Camera | optional 1415:2000 gspca/ov534 (OV7721): YUYV only, 640x480, fixed focus, mic; unconnected 2026-10-31 |
| LEDs | `led_work` (blue, gpio-229 active-low), `wifi_power`, `wifi_wake`; WS2812 on gpio-78 (`leds_ws2812` loaded, no LED-class entry) |
| PWM/GPIO | pwmchip0 npwm=6 (no pwmN exports); gpiochip0 sunxi 288 pins, gpiochip1 R_PIO 32 |
| Timing | sun6i-rtc rtc0 unconfigured (boot clock 1970-01-02T00:00:04 UTC); sunxi-wdt 16 s timeout, nowayout=0 |
| Serial | 8x sunxi UART (ttyS0-7); no ttyUSB (CH340 unconnected 2026-10-31) |

## Drift since 2026-10-28 (2026-10-31 re-verification)

| Item | 2026-10-28 | 2026-10-31 |
|------|------------|------------|
| USB camera (1415:2000) + audio card2 | present | unconnected (gspca not loaded, no `/dev/video0`) |
| CH340 serial (1a86:7523) | `/dev/ttyUSB0` | unconnected (dmesg: disconnect after boot) |
| CAN SPI child | survey note "spidev1.1" | `spi1.0` |
| SD block node | mmcblk0 | mmcblk1 (enumeration order shifts across reboots) |
| zram0 size | 508 MB | ~485 MB (varies) |
| `/sys/class/fbdev/` | present | absent (`/dev/fb0` unchanged) |

## Verify

Facts are live-verified by read-only SSH probes; re-verify before trusting an
entry (2026-10-31: EDID populated, connector connected, no camera/CH340).
Hardware state changes are journaled in `logs/` at execution time (Constitution
V).
