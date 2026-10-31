# USB

## Verified facts

| Item | Finding | Evidence |
|------|---------|----------|
| Hosts | 8 root hubs: ehci-platform bus1-4 (USB 2.0, 480 M, 5101000/5200000/5310000/5311000.usb), ohci-platform bus5-8 (12 M, 5200400/5310400/5311400/5101400.usb) | dmesg 2026-10-31 |
| Bus 2 | Terminus 1a40:0101 hub at 2-1; full-speed panel at 2-1.1 | dmesg 2026-10-31 |
| Panel | 04d9:8030 BTT-HDMI7 (Holtek Semiconductor), usbhid, full-speed 12 M; input0 + hidraw0 | dmesg 2026-10-31 |
| CH340 serial | 1a86:7523, ch341-uart -> `/dev/ttyUSB0`; present 2026-10-28, **absent** 2026-10-31 (dmesg: disconnected at 2181 s into boot) | 2026-10-28 survey, 2026-10-31 reverify |
| Camera | 1415:2000 (gspca/ov534), 2 audio interfaces incl. mic; present 2026-10-28 (YUYV only, 640x480, fixed focus - see `logs/2026-10-28-camera-quality.md`), **absent** 2026-10-31 (gspca not loaded, no `/dev/video0`) | 2026-10-28 survey, 2026-10-31 reverify |
| OTG | musb_hdrc module loaded | modules 2026-10-31 |

## Online resources

- Linux USB drivers: <https://docs.kernel.org/driver-api/usb.html>
- gspca: https://github.com/mbailey/gspca
- ch341-uart: https://github.com/torvalds/linux/tree/master/drivers/tty/serial

## Drift and notes

- CH340 and camera are optional accessories; both unconnected at the 2026-10-31 re-verify.
- gspca is not auto-loaded when the camera is absent (module loaded only on demand).
