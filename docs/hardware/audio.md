# Audio

## Verified facts

| Item | Finding | Evidence |
|------|---------|----------|
| card0 | "Codec", sun4i-codec, `/sys/class/sound/card0/device` -> platform/soc/5096000.codec (h616-audio-codec); playback works (1 kHz tone test) | 2026-10-28 survey, 2026-10-31 reverify |
| card1 | "HDMI", snd_soc_hdmi_codec (soc:ahub1_mach); PCM registered, stream open fails ("Channels count non available", audio graph not up) | 2026-10-28 survey, 2026-10-31 reverify |
| card2 | camera-mic card: present 2026-10-28 (capture registered, same stream-open failure); **absent** 2026-10-31 (camera unconnected) | 2026-10-28 survey, 2026-10-31 reverify |
| HDMI audio graph | dw_hdmi_cec + dw_hdmi_i2s_audio modules loaded; CEC input rc0 registered | dmesg 2026-10-31 |
| Modules | sunxi_ac200 + ac200_phy loaded; ac200-sunxi probe fails -22 (i2c-power.md) | dmesg 2026-10-31 |

## Online resources

- ALSA: <https://www.alsa-project.org/>
- snd_soc_hdmi_codec: https://github.com/torvalds/linux/tree/master/sound/soc/codecs/hdmi

## Drift and notes

- card2 disappears with the camera (see usb.md).
- HDMI audio graph present but unusable; stream open fails on both card1 and
  the 2026-10-28 camera card2 - suspected missing audio graph setup, not a
  hardware fault.
