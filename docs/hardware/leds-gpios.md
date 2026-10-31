# LEDs and frame-buffer access

## Verified facts

| Item | Finding | Evidence |
|------|---------|----------|
| LED class | `led_work` (blue, gpio-229 active-low), `wifi_power`, `wifi_wake` in `/sys/class/leds` | 2026-10-28 survey, 2026-10-31 reverify |
| led_work | trigger none, brightness 0 (left over from 2026-10-28 trigger experiment; original was heartbeat/0) | 2026-10-28 survey, 2026-10-31 reverify |
| wifi LEDs | wifi_power=1, wifi_wake=1 (module LEDs; red is dim/off in captures - correlation below vision resolution) | 2026-10-28 survey |
| WS2812 | leds_ws2812 loaded, gpio-78 claimed as consumer; no LED-class entry surfaced (present-but-down case for US2); control path untested | 2026-10-28 deep-scan |
| Frame buffer | `/dev/fb0` crw-rw---- root:video (29:0); raw writes work for `video` group members without sudo; `/sys/class/fbdev/` directory absent | 2026-10-28 survey, 2026-10-31 reverify |

## Online resources

- DRM framebuffer: <https://docs.kernel.org/drm/>
- LED drivers: https://github.com/torvalds/linux/tree/master/drivers/leds
- WS2812: https://www.avnet.com/ (WS2812 datasheet)

## Drift and notes

- `/sys/class/fbdev/` absent since 2026-10-31 reverify; `/dev/fb0` unchanged.
- WS2812 has no `/sys/class/leds` entry: brightness control path untested
  (US2 "present-but-down" case).
