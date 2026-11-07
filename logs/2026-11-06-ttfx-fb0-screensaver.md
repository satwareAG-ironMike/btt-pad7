# 2026-11-06 - ttfx fb0 screensaver on CB1 (run + camera + vision verification)

| Field | Value |
|-------|-------|
| what | render all 37 Omarchy ttfx effects to the CB1 7" HDMI panel via `/dev/fb0` (console/TTY, no web tooling), verify visually via the dev-host webcam, and land the renderer as a PR |
| where | btt-pad7 CB1 (Allwinner H616, `/dev/fb0` 1024x600) + dev-host webcam (`/dev/video0`) |
| when | 2026-11-06 pad run + capture (cap 19:33); 2026-11-07 vision verification + commit |
| why | confirm the fb0 renderer + mini terminal emulator produce all 37 effects with correct BGRA color and a clean exit, before publishing |
| result | 37/37 effects ran with fresh seeds, no python3 left, fb0 zeroed; 37 effect segments confirmed from 571 frames; 27B vision check of 3 colorful frames shows both warm + cool colors; BGRA confirmed by band test + `--bgra` |

## Root cause + fixes (no-render bug)

An instrumented trace of the raw CSI stream (`raw_cs.txt`) showed ttfx emitted **128 chars/line** (auto-wrap, row+1) **plus** an explicit `B` (row+1) for the same line → double row-advance → only even rows inked. Three fixes in `bin/omarchy-screensaver.py`:

| # | Fix | Location |
|---|-----|----------|
| 1 | line wrap: `if c >= self.width` → `if c > self.width` (sole line-advancer is now `B`/`H`/LF) | `Term.write_char` (~L182) |
| 2 | added cursor ops: `H` (abs `r;c`), `D`, `M`, `C`, bare `A`/`B`/`G` defaults | `Term._csi` (~L92) |
| 3 | space-write paints background (black or `attrs['bg']`) via `FILL_MASK` to stop ghosting | `Fb0.blit` (~L312) |

## Pad run

- `ssh btt-pad7`: `python3 omarchy-screensaver.py --frame-rate 30 --ttfx ./ttfx --bgra`
- `btt-pad7:/home/b0t/bttsx/run.log`: 37/37, one line per effect `[screensaver] i/37 <effect> seed=N`, all seeds fresh (non-sequence)
- full cycle ~285 s (~7.7 s/effect; effects end at their own frame budget, not the 10 s cap)
- post-cycle: `ps -eo comm | grep -c python3` == 0; fb0 fully zero after `fb.clear()`/`fb.close()`

## Camera calibration (dev host, `/dev/video0`, 640x480)

| Item | Value |
|------|-------|
| Capture | 571 frames over 285.5 s (`cap_full.mp4`) |
| Lit region | camera y ≈ 78-349 of 480 px; top ~15% of frame is above the panel |
| True-black floor | ~27 (post-cycle cam); brightness range 24.8-30.4 during cycle |
| Panel "black" | reads ~50-90 during capture (ambient light + auto-exposure) |
| Artifact | **constant** blue reflection band at y ≈ 246-278 across all effects - an environmental reflection on the glossy panel, **not content**; excluded from BGRA judgment |

## Segments (MAD-boundary detection, p90 threshold)

| Metric | Value |
|--------|-------|
| Effect segments | 37 (raw detection over-split the `wipe` by 2) |
| Inter-frame change | 2.9-7.1 % per segment, all > 0 |
| Feature distance | 1.98-5.96 per segment |
| Order | beams, binarypath, blackhole, bouncyballs, bubbles, burn, colorshift, crumble, decrypt, errorcorrect, expand, fireworks, highlight, laseretch, matrix, middleout, orbittingvolley, overflow, pour, print, rain, randomsequence, rings, scattered, slice, slide, smoke, spotlights, spray, swarm, sweep, synthgrid, thunderstorm, unstable, vhstape, waves, wipe |

## BGRA correctness

- **Band test (on pad, camera-verified):** a solid red written to fb0 reads back **blue** via the webcam → byte order is **BGRA**, not RGBA.
- Full cycle therefore runs with `--bgra`.
- 27B vision check (endpoint `http://localhost:8080/v1/chat/completions`, model `Ternary-Bonsai-2-27B-PTQ1_0.gguf`) of 3 colorful frames, each shows **both warm (red/orange) and cool (blue) colors simultaneously** → palette renders correctly (not red↔blue swapped):
  - `vision_colorshift_111.png` (55.5 s): footer-only SGR dots (red/orange + blue), as designed
  - `vision_fireworks_170.png` (85.0 s): glowing particles, red/orange + blue
  - `vision_beams_10.png` (5.0 s): bright points, red/orange + blue + white

## Artifacts

- `btt-pad7:/home/b0t/bttsx/run.log` - 37/37 evidence
- `/tmp/btt-diag/` - `cap_full.mp4`, `frames/`, `segments.json`, `frames_stats.csv`, `vision_*.png` (dev-host, not committed)
