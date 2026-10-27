# 2026-10-28 - camera quality research + autofocus attempt (CB1)

| Field | Value |
|-------|-------|
| what | camera quality experiments on `/dev/video0`: exposure calibration (manual lock), multi-frame averaging, 2x upscale, digital-sharpening A/B (sharpness 0 vs 63), autofocus probe |
| where | bttpad7 CB1, camera 1415:2000 "USB Camera-B4.09.24.1" (USB 2-1.4, gspca ov534, sensor OmniVision OV7721) |
| when | 2026-10-28 00:10-00:24 (board clock) |
| why | user request: best possible resolution and quality; "try to autofocus" |
| result | see findings below |

## Findings

1. **Resolution ceiling**: sensor OV7721 = VGA native (research: kernel ov534 driver + web sources); gspca exposes only 320x240 and 640x480 YUYV. 640x480 is the maximum; anything above is post-processing (synthetic pixels).
2. **No UVC**: camera interfaces are Vendor-Specific + Audio (lsusb -v), so uvcvideo is not an option; gspca is the only driver path.
3. **Autofocus: not possible.** `v4l2-ctl -L` full control list: brightness, contrast, saturation, hue, white_balance_automatic, exposure, gain_automatic, gain, horizontal/vertical_flip, power_line_frequency, sharpness, auto_exposure. No `V4L2_CID_FOCUS`/pan-tilt. Fixed-focus lens; the camera has no focus actuator.
4. **Digital sharpening does not fix defocus**: sharpness 0 vs 63 both read 1/5 sharpness in vision analysis; the softness is optical (fixed lens at the current distance), not sensor-side.
5. **What helps**: manual exposure lock (auto_exposure=1, gain=4, exposure=240, Y-mean ~137 - no clipping), 10-frame raw averaging (noise), 2x Lanczos upscale (readability 2/5 vs 1/5).
6. Camera content reads: panel shows tty1 boot-log tail + agetty prompt; a marker write to `/dev/tty1` (via sudo, b0t cannot open the root-owned tty node) was verified on camera.

## Control state left behind (rollback values in parentheses)

| Control | Left | Default |
|---------|------|---------|
| auto_exposure | 1 (Manual) | 0 (Auto) |
| gain_automatic | 0 | 1 |
| gain | 4 | 20 |
| exposure | 240 | 120 |
| contrast | 48 | 32 |
| saturation | 96 | 64 |
| sharpness | 63 | 0 |

Redaction (constitution VI): the sudo password used is a documented test value and is not recorded here.
