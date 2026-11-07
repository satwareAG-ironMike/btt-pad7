#!/usr/bin/env python3
"""Omarchy screensaver for the BTT PAD 7 (CB1).

Runs the Omarchy ttfx terminal effects in console/TTY mode and renders them
to the 7-inch HDMI panel via /dev/fb0. Each of the 37 effects plays for a
fixed duration with a fresh seed.

Render path:
  * ttfx spawns into a 128x37 pty (winsize row-first).
  * the differential ANSI stream is decoded by a small terminal emulator.
  * only changed cells are rasterized to /dev/fb0 using a pre-rendered glyph
    atlas (bin/atlas.json); the pad has no PIL.

Modes:
  default       : live fb0 screensaver (rotate all 37 effects)
  --render-once : decode the stream and rasterize the final frame to a PNG
                  (dev-host, requires PIL) for decoder/rasterization checks
  --raw-capture : also dump the raw ANSI stream to a file
  --bgra        : framebuffer byte order is BGRA instead of RGBA (default)

Usage:
  omarchy-screensaver.py [--ttfx PATH] [--duration N] [--seed N]
                         [--effect NAME] [--render-once OUT.png]
                         [--raw-capture FILE] [--bgra] [--atlas PATH]
"""
import argparse, base64, fcntl, json, os, pty, random, struct, sys, termios, time
from pathlib import Path

CELL_W, CELL_H = 8, 16
W, H = 128, 37
TEXT = "BTT7 PAD"
FILL_MASK = bytes([255] * (CELL_W * CELL_H))

EFFECTS = [
    'beams', 'binarypath', 'blackhole', 'bouncyballs', 'bubbles', 'burn',
    'colorshift', 'crumble', 'decrypt', 'errorcorrect', 'expand', 'fireworks',
    'highlight', 'laseretch', 'matrix', 'middleout', 'orbittingvolley',
    'overflow', 'pour', 'print', 'rain', 'randomsequence', 'rings',
    'scattered', 'slice', 'slide', 'smoke', 'spotlights', 'spray', 'swarm',
    'sweep', 'synthgrid', 'thunderstorm', 'unstable', 'vhstape', 'waves',
    'wipe',
]

# --- xterm-256 palette ------------------------------------------------------
_BASIC16 = [
    (0, 0, 0), (192, 0, 0), (0, 192, 0), (192, 192, 0),
    (0, 0, 192), (192, 0, 192), (0, 192, 192), (255, 255, 255),
    (128, 128, 128), (192, 128, 128), (128, 192, 128), (192, 192, 128),
    (128, 128, 255), (192, 128, 255), (128, 192, 255), (255, 255, 255),
]


def _xterm256(i):
    if i < 16:
        return _BASIC16[i]
    if i < 232:
        idx = i - 16
        return (9 + (idx // 36) * 6) * 11, (9 + (idx // 6 % 6) * 6) * 11, (9 + (idx % 6) * 6) * 11
    v = (i - 232) * 255 // 16
    return v, v, v


XTERM256 = tuple(_xterm256(i) for i in range(256))


# --- mini terminal emulator --------------------------------------------------
def _is_final_letter(b):
    return 65 <= b <= 90 or 97 <= b <= 122


class Term:
    def __init__(self, width, height, blit=None):
        self.width, self.height = width, height
        self.grid = [[' '] * width for _ in range(height)]
        self.attrs = [[dict() for _ in range(width)] for _ in range(height)]
        self.row, self.col = 0, 0
        self.saved = None
        self.cur = dict()
        self.blit = blit
        self.pending = b''

    def _parse_params(self, raw):
        params = []
        for part in raw.split(b';'):
            if part:
                try:
                    params.append(int(part))
                except ValueError:
                    pass
        return params

    def _csi(self, params, term):
        if term == 'A':  # cursor up (bare => 1)
            n = params[0] if params and params[0] > 0 else 1
            self.row = max(0, self.row - n)
        elif term == 'B':  # cursor down (bare => 1)
            n = params[0] if params and params[0] > 0 else 1
            self.row = min(self.height - 1, self.row + n)
        elif term == 'M':  # cursor up (alias of A, bare => 1)
            n = params[0] if params and params[0] > 0 else 1
            self.row = max(0, self.row - n)
        elif term == 'C':  # cursor left (bare => 1)
            n = params[0] if params and params[0] > 0 else 1
            self.col = max(0, self.col - n)
        elif term == 'D':  # cursor right (bare => 1)
            n = params[0] if params and params[0] > 0 else 1
            self.col = max(0, min(self.width - 1, self.col + n))
        elif term == 'G':  # cursor to column (bare => col 0)
            if params:
                self.col = max(0, min(params[0] - 1, self.width - 1))
            else:
                self.col = 0
        elif term == 'H':  # cursor to row;col (absolute, bare => row only)
            if len(params) >= 2:
                self.row = max(0, min(self.height - 1, params[0] - 1))
                self.col = max(0, min(params[1] - 1, self.width - 1))
            elif params:
                self.row = max(0, min(self.height - 1, params[0] - 1))
        elif term == 'm':
            self._apply_sgr(params)

    def _apply_sgr(self, params):
        if not params or 0 in params:
            self.cur = dict()
            return
        i, n = 0, len(params)
        while i < n:
            p = params[i]
            if p == 1:
                self.cur['bold'] = True
            elif p == 2:
                self.cur['dim'] = True
            elif p == 3:
                self.cur['italic'] = True
            elif p == 4:
                self.cur['underline'] = True
            elif p == 5:
                self.cur['blink'] = True
            elif p == 7:
                self.cur['reverse'] = True
            elif 30 <= p <= 37:
                self.cur['fg'] = _BASIC16[p - 30]
            elif 40 <= p <= 47:
                self.cur['bg'] = _BASIC16[p - 40]
            elif p in (38, 48):
                target = 'fg' if p == 38 else 'bg'
                if i + 2 < n and params[i + 1] == 5:
                    self.cur[target] = XTERM256[params[i + 2]]
                    i += 3
                elif i + 4 < n and params[i + 1] == 2:
                    self.cur[target] = (params[i + 2], params[i + 3], params[i + 4])
                    i += 5
                else:
                    i += 1
            else:
                i += 1

    def _dec(self, code):
        if code == 7:  # DEC_RESTORE_CURSOR
            if self.saved is not None:
                self.row, self.col = self.saved
        elif code == 8:  # DEC_SAVE_CURSOR
            self.saved = (self.row, self.col)

    def write_char(self, ch):
        r, c = self.row, self.col
        if c >= self.width:
            c, r = 0, self.row + 1
        r = min(r, self.height - 1)
        c = min(c, self.width - 1)
        self.grid[r][c] = ch
        self.attrs[r][c] = dict(self.cur)
        if self.blit:
            self.blit(r, c, ch)
        c += 1
        # Park at col=width when a line is filled; do NOT advance the row here.
        # ttfx repositions each line with G and advances with B, so an extra
        # auto-wrap would double-advance and skip every other row. The row
        # advances only on an explicit line move (B/LF/H) or on the NEXT char
        # (handled by the top c >= width check), which preserves natural
        # wrapping for text that overflows without repositioning.
        if c > self.width:
            c, r = 0, r + 1
        self.row, self.col = min(r, self.height - 1), c

    def decode(self, data):
        buf = self.pending
        if buf:
            data = buf + data
        self.pending = b''
        n = len(data)
        i = 0
        while i < n:
            b = data[i]
            if b == 0x1b:  # ESC
                start = i
                i += 1
                if i >= n:
                    self.pending = data[start:]
                    return
                b2 = data[i]
                if b2 == 0x5b:  # ESC [  ... ESC <letter>
                    i += 1
                    j = i
                    while j < n and not _is_final_letter(data[j]):
                        j += 1
                    if j >= n:
                        # incomplete CSI sequence: buffer it for the next chunk
                        self.pending = data[start:]
                        return
                    term = chr(data[j])
                    params = self._parse_params(data[i:j])
                    i = j + 1
                    self._csi(params, term)
                elif b2 in (0x37, 0x38):  # ESC 7 / ESC 8
                    self._dec(b2 - 0x30)
                    i += 1
                elif b2 in (0x28, 0x29):  # ESC ( / ESC )  char set
                    j = i + 1
                    while j < n and not _is_final_letter(data[j]):
                        j += 1
                    if j >= n:
                        self.pending = data[start:]
                        return
                    i = j + 1
                else:
                    i += 1  # lone ESC + other control: skip
            elif b == 0x0d:
                self.col = 0
                i += 1
            elif b == 0x0a:
                self.row = min(self.height - 1, self.row + 1)
                i += 1
            elif 32 <= b < 127:
                self.write_char(chr(b))
                i += 1
            else:
                i += 1
        self.pending = b''

    def final_grid(self):
        # flat (width*height) list of (ch, attrs)
        return [(self.grid[r][c], self.attrs[r][c]) for r in range(self.height)
                for c in range(self.width)]


# --- fb0 rasterizer ---------------------------------------------------------
class Fb0:
    def __init__(self, bgra=False, atlas=None):
        base = Path('/sys/devices/platform/display-engine/graphics/fb0')
        if not base.exists():
            raise SystemExit(
                "not an Allwinner display-engine host "
                "(no /sys/devices/platform/display-engine/graphics/fb0); "
                "use --render-once for dev-host checks")
        self.stride = int((base / 'stride').read_text().strip())
        parts = (base / 'virtual_size').read_text().strip()
        parts = parts.replace('x', ' ').replace(',', ' ').split()
        self.vheight, self.vwidth = int(parts[0]), int(parts[1])
        fd = os.open('/dev/fb0', os.O_RDWR)
        import mmap
        self.size = self.stride * self.vheight
        self.mm = mmap.mmap(fd, self.size)
        self.fd = fd
        self.bgra = bgra
        self.atlas = atlas or {}
        self.patterns = {}
        self.zeros = b'\0' * self.size

    def close(self):
        try:
            self.mm.close()
        except Exception:
            pass
        try:
            os.close(self.fd)
        except Exception:
            pass

    def _pattern(self, mask, R, G, B):
        key = (mask, R, G, B)
        p = self.patterns.get(key)
        if p is None:
            out = bytearray(512)
            if self.bgra:
                for i, m in enumerate(mask):
                    out[i * 4] = (B * m) // 255
                    out[i * 4 + 1] = (G * m) // 255
                    out[i * 4 + 2] = (R * m) // 255
                    out[i * 4 + 3] = 255
            else:
                for i, m in enumerate(mask):
                    out[i * 4] = (R * m) // 255
                    out[i * 4 + 1] = (G * m) // 255
                    out[i * 4 + 2] = (B * m) // 255
                    out[i * 4 + 3] = 255
            p = bytes(out)
            self.patterns[key] = p
        return p

    def blit(self, r, c, ch, attrs):
        x0, y0 = c * CELL_W, r * CELL_H
        off = y0 * self.stride + x0
        if off + 512 > self.size:
            return
        if ch == ' ':
            # A space clears the cell: paint the current background color (the
            # black default when no bg is set) so old pixels do not ghost.
            bg = attrs.get('bg')
            if bg is None:
                bg = (0, 0, 0)
            self.mm[off:off + 512] = self._pattern(FILL_MASK, bg[0], bg[1], bg[2])
            return
        mask = self.atlas.get(ch)
        if mask is None:
            return  # out-of-atlas -> leave blank
        color = cell_color(attrs)
        if not color:
            return
        R, G, B, _A = color
        self.mm[off:off + 512] = self._pattern(mask, R, G, B)

    def clear(self):
        self.mm[0:self.size] = self.zeros


def cell_color(attrs):
    fg = attrs.get('fg')
    bg = attrs.get('bg')
    if attrs.get('reverse'):
        fg, bg = bg, fg
    color = fg if fg is not None else bg
    if color is None:
        return (255, 255, 255, 255)
    if attrs.get('dim'):
        color = (color[0] * 2 // 5, color[1] * 2 // 5, color[2] * 2 // 5)
    return color + (255,)


def build_atlas(atlas_json):
    data = json.load(open(atlas_json))
    return {k: base64.b64decode(v) for k, v in data['atlas'].items()}


# --- capture / driver -------------------------------------------------------
def run_effect(effect, seed, duration, term, fb=None, raw_capture=None,
               ttfx='/usr/bin/ttfx', frame_rate=30):
    import subprocess
    inpath = '/tmp/btt_in.txt'
    with open(inpath, 'w') as f:
        f.write(TEXT + '\n')
    master, slave = pty.openpty()
    fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack('hh', H, W))  # row, col
    fcntl.fcntl(master, fcntl.F_SETFL, os.O_NONBLOCK)
    err = open('/tmp/btt_err.txt', 'w')
    fin = open(inpath, 'rb')
    proc = subprocess.Popen(
        [ttfx, '--seed', str(seed), '--canvas-width', str(W),
         '--canvas-height', str(H), '--frame-rate', str(frame_rate), effect],
        stdin=fin, stdout=slave, stderr=err)
    t0 = time.monotonic()
    while True:
        if time.monotonic() - t0 >= duration:
            break
        try:
            b = os.read(master, 262144)
        except OSError:
            b = b''
        if b:
            if raw_capture:
                raw_capture.write(b)
                raw_capture.flush()
            term.decode(b)
        else:
            if proc.poll() is not None:
                break
            time.sleep(0.0004)
    try:
        proc.kill()
    except ProcessLookupError:
        pass
    proc.wait()
    err.close()
    fin.close()
    os.close(master)
    os.close(slave)


def render_png(term, atlas, out):
    try:
        from PIL import Image
    except ImportError:
        sys.exit("PIL is required for --render-once (dev host only)")
    pw = W * CELL_W  # image pixel width
    buf = bytearray(pw * H * CELL_H * 3)
    for r in range(H):
        for c in range(W):
            ch = term.grid[r][c]
            mask = atlas.get(ch)
            if mask is None:
                continue
            color = cell_color(term.attrs[r][c])
            R, G, B, _A = color
            base = r * CELL_H * pw + c * CELL_W  # flat pixel index of cell top-left
            for dy in range(CELL_H):
                for dx in range(CELL_W):
                    m = mask[dy * CELL_W + dx]
                    o = (base + dy * pw + dx) * 3
                    buf[o] = (R * m) // 255
                    buf[o + 1] = (G * m) // 255
                    buf[o + 2] = (B * m) // 255
    img = Image.frombytes('RGB', (W * CELL_W, H * CELL_H), buf)
    img.save(out)
    print(f"[screensaver] rendered {out}", flush=True)


def _atlas_path():
    return str(Path(__file__).resolve().parent / 'atlas.json')


def main():
    ap = argparse.ArgumentParser(description="Omarchy ttfx screensaver -> /dev/fb0")
    ap.add_argument('--duration', type=float, default=10.0)
    ap.add_argument('--seed', type=int, default=None)
    ap.add_argument('--frame-rate', type=int, default=30)
    ap.add_argument('--effect', type=str, default=None)
    ap.add_argument('--ttfx', default='/usr/bin/ttfx')
    ap.add_argument('--render-once', type=str, default=None)
    ap.add_argument('--raw-capture', type=str, default=None)
    ap.add_argument('--atlas', default=_atlas_path())
    ap.add_argument('--bgra', action='store_true')
    args = ap.parse_args()

    atlas = build_atlas(args.atlas)

    effects = [args.effect] if args.effect else EFFECTS

    if args.render_once:
        term = Term(W, H)
        raw = open(args.raw_capture, 'wb') if args.raw_capture else None
        run_effect(args.effect or EFFECTS[0], args.seed or 1, args.duration,
                   term, fb=None, raw_capture=raw, ttfx=args.ttfx)
        if raw:
            raw.close()
        render_png(term, atlas, args.render_once)
        return

    fb = Fb0(bgra=args.bgra, atlas=atlas)

    def _blit(r, c, ch):
        fb.blit(r, c, ch, term.attrs[r][c])

    term = Term(W, H, blit=_blit)

    if fb:
        fb.clear()
    base = args.seed
    idx = 0
    try:
        for effect in effects:
            seed = (base + idx) if base is not None else random.getrandbits(32)
            print(f"[screensaver] {idx + 1}/{len(effects)} {effect} seed={seed}", flush=True)
            if fb:
                fb.clear()
            raw = open(args.raw_capture, 'wb') if args.raw_capture else None
            run_effect(effect, seed, args.duration, term, fb=fb,
                       raw_capture=raw, ttfx=args.ttfx)
            if raw:
                raw.close()
            if fb:
                fb.clear()
            idx += 1
    except KeyboardInterrupt:
        print("[screensaver] interrupted", flush=True)
    finally:
        fb.close()


if __name__ == '__main__':
    main()
