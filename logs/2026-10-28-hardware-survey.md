# 2026-10-28 - full hardware survey + LED/audio state checks (CB1)

| Field | Value |
|-------|-------|
| what | read-only hardware survey (CPU/RAM/storage/USB/NET/CAN/I2C/SPI/GPU/display/audio/LEDs/thermals); LED trigger experiments + restore; audio path tests; panel graphic (cat) display via raw `/dev/fb0` write; camera state checks via computervision |
| where | bttpad7 CB1 (bigtreetech,cb1, allwinner sun50i-h616) |
| when | 2026-10-28 00:24-00:40 (board clock) |
| why | user request: "explore all hardware, sound and all display capabilities" |
| result | see findings below |

## Findings

1. **SoC/board**: `bigtreetech,cb1` on `sun50i-h616` (DT compatible), 4x Cortex-A53 @ ondemand governor, 4 thermal zones (cpu/gpu/ve/ddr, ~51C).
2. **Memory**: 992 MB RAM (799 MB available at survey), zram0 508 MB swap (used 0), zram1 50 MB ext4 for /var/log, zram2 unconfigured.
3. **Storage**: mmcblk0 32 GB, vfat /boot (256 MB) + ext4 / (29 GB, 9% used).
4. **USB (bus 2 hub 1a40:0101)**: BTT-HDMI7 panel (04d9:8030), CH340 serial (1a86:7523, exposes /dev/ttyUSB0), camera 1415:2000 gspca (surveyed separately).
5. **Network**: eth0 UP (H616 GMAC, MAC 5a:42:ee:9d:b8:4a), can0 UP mcp251x @ 1 Mbit/s (ERROR-ACTIVE, sample-point 0.666), wlan0 DOWN/NO-CARRIER (rfkill wlan enabled; chip present, no association), docker0 + br-cd4eedadd5fa (Docker installed), no Bluetooth.
6. **I2C**: 4 buses; i2c-1: axp313a PMIC @0x36, ac200-sunxi @0x10 (i2c-0).
7. **SPI**: spi1.0 + spi1.1; mcp2515 CAN transceiver on spidev1.1.
8. **Display**: DRM card0 = HDMI-A-1 (connected), EDID vendor Lontium Semi (panel controller); modes 1024x600 + 640x480; fb0 = 1024x600 @ 32 bpp; render node card1/renderD128 (panfrost render-only). Raw `/dev/fb0` write displays a full-frame graphic (cat test, b0t via video group - no sudo needed).
9. **Audio (3 cards)**: card0 "Codec" H616 sun4i-codec - playback WORKS (1 kHz tone stream ok); card1 "HDMI" (ahub_plat-i2s-hifi) - PCM registered but stream open fails ("Channels count non available", audio graph not up); card2 = the USB camera's own audio (capture registered, open fails the same way).
10. **LEDs**: `led_work` (blue, confirmed via camera A/B test), `wifi_power` + `wifi_wake` (module LEDs; red is dim/off in captures, red-to-wifi_power correlation weak - below vision resolution). Left behind: led_work trigger=none/brightness=0 (functionally off, original was heartbeat/0), wifi_power=1, wifi_wake=1.
11. **Camera state checks (computervision)**: cat graphic verified on panel (3/3 captures), marker line `BTT-CAM-TEST-4821` verified after tty1 write, LED lit/off states verified as above.

Redaction (constitution VI): sudo password not recorded.

## Deep-scan addendum (same day, 00:45-00:52)

| Area | Finding |
|------|---------|
| WLAN | SDIO mmc1 function = Realtek RTL8189FS (vendor 024c device f179), driver `8189fs`, rails vcc33-wifi/vcc-wifi-io up, wifi_power/wifi_wake GPIOs (166/207) high; wlan0 present, unassociated |
| Bluetooth | **No BT hardware enumerated anywhere**: single SDIO function (8189FS is WiFi-only), no BT USB interface, no BT device-tree node, no BT rfkill, no hci device, `bluetooth.service` enabled-but-never-started, no hci_uart module. BlueZ + bluealsa + full rtl_bt firmware set are image carry-overs with nothing to drive |
| GPIO | gpiochip0 = sunxi 288 pins: spi1 CS0/1/2 (75/71/77), CAN INT (73), soft-I2C scl/sda (74/76), **ws2812-gpio (78)**, led_work (229, active-low), reset (210); gpiochip1 = R_PIO 32 pins |
| WS2812 | `leds_ws2812` module live and gpio-78 claimed as consumer; no led-class entry surfaced - control path untested |
| CPU | 9 OPPs 480 MHz-1512 MHz, governor ondemand |
| Ethernet | sunxi-gmac + internal ephy, 100 Mb/s full-duplex link up |
| HDMI/panel | modes 1024x600 + 640x480; EDID Lontium; touch input "BIQU BTT-HDMI7" via usbhid (panel is a TOUCHSCREEN); dw_hdmi_cec + dw_hdmi_i2s_audio modules loaded (CEC + HDMI audio graph present but stream-open fails, see finding 9) |
| Misc | pwmchip0, rtc0, watchdog0, hwmon0-3 (= 4 thermal zones), 8x sunxi UART (ttyS0-7) + CH340 ttyUSB0, 2 mmc hosts (SD + WiFi SDIO), musb_hdrc OTG, camera = USB camera with 2 audio interfaces (mic) |
| LAN env (ARP) | 192.168.178.1 (router, RA present, ULA fd30::/64 + public 2a02:: prefix), 192.168.178.2 |
| Vision state check | screen still shows cat graphic; red LED lit, blue not lit - matches restored system state (wifi_power=1, led_work heartbeat/brightness 0) |
