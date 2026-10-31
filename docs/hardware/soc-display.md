# SoC and display

## Verified facts

| Item | Finding | Evidence |
|------|---------|----------|
| SoC | Allwinner H616; device tree compatible `bigtreetech,cb1` | 2026-10-28 survey |
| CPU | 4x Cortex-A53; 9 OPPs 480 MHz-1512 MHz; governor ondemand | 2026-10-28 survey |
| Display driver | sun4i-drm 1.0.0 on `card0` (display-engine); bound mixers 1280000/12a0000, tcon-top 6510000, lcd-controller 6515000, hdmi 6000000 | dmesg 2026-10-31 |
| HDMI TX | sun8i-dw-hdmi 6000000.hdmi: DesignWare HDMI v2.12a with HDCP (DWC HDMI 2.0 TX PHY) | dmesg 2026-10-31 |
| Connector | `card0/card0-HDMI-A-1`, status `connected` | 2026-10-31 reverify |
| EDID | populated; `/sys/class/drm/card0/card0-HDMI-A-1/edid` (lowercase path, 4096 B block); product string "Lontium Semiconductor"; 2 preferred timing blocks; CEC + EDID-Aux blocks. Earlier probes reported "EDID empty" because they probed the wrong path (capital `card0/EDID`) | 2026-10-31 reverify (hex dump logged) |
| Modes | exposed: 1024x600, 640x480 | 2026-10-28 survey, 2026-10-31 reverify |
| Framebuffer | fb0 1024x600 @ 32 bpp (sun4i-drmdrmfb); raw `/dev/fb0` writes work without sudo (group video, `crw-rw----`; access detail in leds-gpios.md) | 2026-10-28 survey |
| fbdev sysfs | `/sys/class/fbdev/` absent (drift, see storage-serial.md) | 2026-10-31 reverify |
| Touch | USB HID "BIQU BTT-HDMI7" (04d9:8030) on bus 2-1.1, full-speed 12 M; input0 + hidraw0. The panel is a touchscreen; not a DSI/I2C touch controller | 2026-10-28 survey, 2026-10-31 reverify |
| CEC / HDMI audio | `dw_hdmi_cec`, `dw_hdmi_i2s_audio` modules loaded; HDMI audio stream-open fails (audio.md) | dmesg 2026-10-31 |

## Online resources
- Linux DRM docs: <https://docs.kernel.org/drm/>
- sunxi display driver: https://github.com/torvalds/linux/tree/master/drivers/gpu/drm/sunxi
- Armbian wiki: https://wiki.armbian.org/
- BTT vendor page: https://www.bigtreetech.com/

## Drift and notes
- EDID populated (Lontium Semiconductor); supersedes any earlier "EDID empty" note.
- `/sys/class/fbdev/` absent since the 2026-10-31 reverify; `/dev/fb0` unchanged.
