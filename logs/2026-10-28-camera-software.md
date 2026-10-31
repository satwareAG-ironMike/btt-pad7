# 2026-10-28 - camera software install (CB1)

| Field | Value |
|-------|-------|
| what | installed `v4l-utils` + `fswebcam` via apt (Debian 13 arm64); set V4L2 controls on `/dev/video0`: contrast=48, saturation=96, sharpness=32; captured stills with `fswebcam -r 640x480 -S 12 -D 1` |
| where | bttpad7 (BTT PAD 7 CB1, USB port 2-1.4, camera 1415:2000 "USB Camera-B4.09.24.1", driver gspca/ov534, node `/dev/video0`) |
| when | 2026-10-28 00:01 (board clock) |
| why | enable high-quality still capture on the CB1. Research outcome: the gspca ov534 driver exposes YUYV 320x240/640x480 only (no MJPG), max 640x480@60fps; `v4l-utils` provides control/format tooling, `fswebcam` still-captures and encodes JPEG locally (no MJPG passthrough needed). Neither tool was on the Armbian minimal image. |
| result | `v4l2-ctl` / `fswebcam` present at /usr/bin; still captured to `/tmp/shot.ppm` (JPEG, gd-jpeg quality=255, 640x480, 396,791 B); image transferred to workstation for review |

Redaction (constitution VI): the sudo password used for apt install is a documented test value and is deliberately not recorded here.
