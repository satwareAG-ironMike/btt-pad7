# bin/ — BTT PAD 7 ttfx fb0 screensaver

## Purpose

Run Omarchy ttfx terminal effects in console/TTY mode on the BTT PAD 7
(CB1, Allwinner H616, 7" HDMI panel), rendering via `/dev/fb0`. Rotates all
37 ttfx effects, ~10 s each, fresh seed per effect. Repo-owned code:
`omarchy-screensaver.py` (render driver + mini terminal emulator) and
`atlas.json` (glyph atlas). `ttfx` itself is an external dependency (see
Local Contracts) and is **not** committed.

## Ownership

satware AG / AI Architect (Jane Alesi). On-pad deploy dir: `/home/b0t/bttsx/`.

## Local Contracts

**Files**

| File | Role |
|------|------|
| `omarchy-screensaver.py` | Python 3 (pad: Armbian 26.8.3 Trixie). Spawns `ttfx` into a 128x37 pty (winsize **row-first**), decodes the ANSI stream with a small terminal emulator, blits changed cells to `/dev/fb0` via the glyph atlas. CLI: `--ttfx`, `--duration` (default 10 s, a cap — effects end at their own frame budget), `--seed`, `--effect` (single), `--render-once OUT.png` (dev host, needs PIL), `--raw-capture FILE`, `--bgra`, `--atlas`. |
| `atlas.json` | `{"atlas": {char: base64}}`; 94 glyphs (AdwaitaMono 13, 8x16, 128 bytes each), generated on the dev host (pad has no PIL). |

**CB1 display facts (verified 2026-11-06, camera-tested)**

- fb0: `/sys/devices/platform/display-engine/graphics/fb0`; `virtual_size` is
  **comma-separated** `1024,600` (split on both `x` and `,`), stride 4096,
  bps 32. Panel 1024x600; grid 128x37 cells of 8x16 px = 1024x592.
- Byte order is **BGRA**, not RGBA. Camera band test: red written to fb0 read
  back blue; full cycle must run with `--bgra`.
- `pkill -f <pattern>` self-matches the remote shell's own cmdline — kill
  by pid (`ps -eo comm,pid | grep -w python3`).
- A background ssh job holds its pty and hangs the ssh call — detach with
  `setsid nohup ... < /dev/null &`.

**ttfx dependency**

- `omacom/ttfx` (MIT), commit `14ed274` (0.5.1); build checkout at
  `.ttfx-build/ttfx` (gitignored, has its own `.git`).
- Deployed binary: static, stripped, aarch64-unknown-linux-musl, ~2.4 MB at
  `.ttfx-build/ttfx/target/aarch64-unknown-linux-musl/release/ttfx`; on the
  pad at `/home/b0t/bttsx/ttfx`.

**On-pad run command**

```bash
python3 omarchy-screensaver.py --frame-rate 30 --ttfx ./ttfx --bgra
```

`run.log` lines: `[screensaver] i/37 <effect> seed=N`. Full cycle completes in
~285 s (~7.7 s/effect, effects end at their own frame budget, not the 10 s cap);
process exits cleanly with no python3 proc left.

## Work Guidance

- Deploy: `scp bin/omarchy-screensaver.py bin/atlas.json btt-pad7:/home/b0t/bttsx/`
  (keeps the static `ttfx` on the pad). Any hardware/state change on the CB1
  is recorded in `logs/2026-MM-DD-*.md` at execution time.
- Rebuild ttfx static: `cargo build --release --target aarch64-unknown-linux-musl`
  in the `.ttfx-build/ttfx` checkout.
- Decoder/rasterization checks on the dev host (no fb0):
  `python3 omarchy-screensaver.py --render-once /tmp/frame.png` (PIL needed).
- Camera verification: `ffmpeg -f v4l2 -video_size 640x480 -i /dev/video0 -frames:v 1 -y f.png`
  from the dev host; per-frame brightness/MAD, ~37 effect segments, vision-check
  2-3 colorful frames for `--bgra` color correctness.

## Verification

- Pad: `run.log` has 37 distinct effect lines with fresh (non-sequence) seeds;
  `ps -eo comm | grep -c python3` == 0 after exit.
- Camera: frames are not uniform grey across the cycle; inter-frame MAD > 0 in
  effect windows; segment count (MAD-boundary detection) ≈ 37; a colorful frame
  (e.g. colorshift) shows rainbow, not swapped red/blue (BGRA confirmed).
- Dev host: `--render-once` produces a non-empty 1024x592 PNG.

## Child DOX Index

(none)
