# GPU

## Verified facts

| Item | Finding | Evidence |
|------|---------|----------|
| Device | `/sys/class/drm/card1`; render node `renderD128`; render-only (no display connected) | 2026-10-31 reverify |
| Driver | panfrost 1.6.0 | dmesg 2026-10-31 |
| Silicon | Mali-G31 MP1, id 0x7093 | dmesg 2026-10-31 |
| Clocks at probe | GPU 432 MHz, bus 200 MHz | dmesg 2026-10-31 |
| Features (panfrost feature words) | L2 present, shader present, tiler present, MMU present; panfrost reports issues word 0x400 | dmesg 2026-10-31 |

## Online resources
- panfrost (sunxi community fork): https://github.com/sunxi-dev/panfrost
- Linux DRM docs: <https://docs.kernel.org/drm/>

## Notes
- Display path is card0 (sun4i-drm, soc-display.md); card1 is the render node for off-screen/OpenGL work.
