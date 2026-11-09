# /// script
# requires-python = ">=3.11"
# dependencies = ["pillow>=10", "numpy>=1.26"]
# ///
"""wallpaper.py - generate a wallpaper from the active palette.

  uv run wallpaper.py <palette.json> <out.png> <width> <height> [flavour]

Every flavour is line art built from mathematical curves, coloured only from
palette.json, and deterministic for a given theme + flavour (seeded), so a theme
always gets the same set of pictures:

  ridges     mountain ridges (sums of sines) fading into haze
  contours   a topographic map: level curves of a smooth height field, every 5th
             line thicker and in the accent, line width breathing across the map
  strands    a bundle of flowing curves that gathers and fans out along the long
             axis of the screen (a river delta / a braid)
  waves      stacked sine lines rolling from faint and tight at the top to bright
             and wide at the bottom (dunes / an ocean)
  peaks      jagged midpoint-displaced ridges as flat silhouettes in front of a
             ringed moon
  dunes      a desert: overlapping sand dunes with a lit and a shaded flank, crest
             lines, and a low sun
  orbits     concentric tilted orbits around an off-centre star, a few planets on
             them
  horizon    a synthwave evening: striped sun on the horizon, a perspective grid
             floor converging on it
  constellation  scattered stars joined to their nearest neighbours into
             constellations, a few bright named-looking nodes with halos
  strata     a canyon wall: dozens of near-horizontal sediment layers, each with
             its own tint, every few layers rimmed in the accent
  meteors    a meteor shower: tapered diagonal streaks of light across the sky

  pixel-<any of the above>   the same scene as retro pixel art: composed on a grid
             of ~212 cells along the short side, colours snapped to a small palette
             derived from the theme with ordered (Bayer) dithering, no blur, stars in
             the night sky, then scaled up with hard pixel edges.

Quality: the smooth flavours are drawn 1.5-2x larger than requested and downscaled
with a Lanczos filter (anti-aliased edges), gradients are drawn in float and
dithered, and a +-1 LSB grain is added at the end so dark gradients never band.
Portrait canvases (the vertical monitor) get a composition tuned for height: a
higher horizon, more ridges/lines, strands flowing top to bottom, and slightly
thicker strokes because that panel has fewer physical pixels per image pixel.
"""
import json, math, random, sys
from types import SimpleNamespace
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

WMIN = 0.0          # minimum stroke width (set to 1 px in pixel mode so thin lines never break up)

# ----------------------------------------------------------------------------- colour helpers
def hex2rgb(h):
    h = h.lstrip("#"); return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))

def mix(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))

def hue(rgb):
    r, g, b = (c / 255 for c in rgb)
    mx, mn = max(r, g, b), min(r, g, b); d = mx - mn
    if d < 0.08:
        return None                                   # (near-)grey: no usable hue
    if mx == r:   hh = ((g - b) / d) % 6
    elif mx == g: hh = (b - r) / d + 2
    else:         hh = (r - g) / d + 4
    return hh * 60

def harmony(p, accent, n=4):
    """accent + the ANSI colours nearest in hue to it (an analogous palette), so a
    green theme paints green/cyan hills and an orange theme orange/red ones. A grey
    accent falls back to the cool colours."""
    order = (4, 6, 12, 14, 2, 10, 5, 13, 1, 9, 3, 11)
    cands = [hex2rgb(p[f"C{i}"]) for i in order]
    ha = hue(accent)
    if ha is not None:
        def dist(c):
            hc = hue(c)
            if hc is None: return 999
            d = abs(hc - ha) % 360; return min(d, 360 - d)
        cands.sort(key=dist)
    out = [accent]
    for c in cands:
        if all(sum(abs(c[i] - o[i]) for i in range(3)) > 60 for o in out):
            out.append(c)
        if len(out) >= n: break
    while len(out) < n: out.append(out[-1])
    return out

# ----------------------------------------------------------------------------- drawing helpers
def noise(c, shape, amp):
    """Uniform noise in [-amp, amp] as float32 (float64 would double the memory)."""
    return (c.nprng.random(shape, dtype=np.float32) - 0.5) * (2 * amp)

def gradient(c, top, bottom):
    """Vertical gradient drawn in float with triangular dither before quantising, so a
    near-black sky never shows 8-bit bands."""
    t = np.linspace(0, 1, c.h, dtype=np.float32)[:, None, None]
    arr = np.array(top, np.float32) + (np.array(bottom, np.float32) - np.array(top, np.float32)) * t
    arr = np.broadcast_to(arr, (c.h, c.w, 3)) + noise(c, (c.h, c.w, 3), 0.5)
    rgba = np.empty((c.h, c.w, 4), np.uint8)
    rgba[..., :3] = np.clip(np.rint(arr), 0, 255); rgba[..., 3] = 255
    return Image.fromarray(rgba, "RGBA")

def layer(w, h):
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0)); return im, ImageDraw.Draw(im)

def comp(c, img, lay, blur=0.0):
    if blur > 0.05 and not c.pixel:                   # pixel art never blurs
        lay = lay.filter(ImageFilter.GaussianBlur(radius=blur))
    return Image.alpha_composite(img, lay)

def np_layer(rgb, alpha):
    """RGBA image from a colour (tuple, or (h,w,3) float array) and a (h,w) 0..1 alpha."""
    h, w = alpha.shape
    out = np.empty((h, w, 4), np.uint8)
    out[..., :3] = rgb if isinstance(rgb, tuple) else np.clip(rgb, 0, 255).astype(np.uint8)
    out[..., 3] = np.clip(alpha * 255, 0, 255).astype(np.uint8)
    return Image.fromarray(out, "RGBA")

def wave(x, w, parts):
    """Sum of sines: parts = [(amplitude, frequency, phase), ...]; x may be an array."""
    return sum(a * np.sin(2 * np.pi * f * x / w + ph) for a, f, ph in parts)

def ribbon(draw, pts, widths, color, vertical=False):
    """Variable-width stroke drawn as ONE filled polygon: the centre line offset by
    +-width/2 on each side. No per-segment joints, so no ladder artifacts.
    vertical=False offsets in y (a line running left-right); True offsets in x
    (a line running top-bottom)."""
    if len(pts) < 2: return
    widths = [max(WMIN, wd) for wd in widths]
    if vertical:
        left  = [(x - wd / 2, y) for (x, y), wd in zip(pts, widths)]
        right = [(x + wd / 2, y) for (x, y), wd in zip(pts, widths)]
    else:
        left  = [(x, y - wd / 2) for (x, y), wd in zip(pts, widths)]
        right = [(x, y + wd / 2) for (x, y), wd in zip(pts, widths)]
    draw.polygon(left + right[::-1], fill=color)

def ring(draw, cx, cy, r, widths, color, n=360):
    """A closed variable-width ring (outer loop + reversed inner loop; PIL's even-odd
    fill leaves the hole empty)."""
    ang = np.linspace(0, 2 * np.pi, n, endpoint=False)
    widths = [max(WMIN, wd) for wd in widths]
    outer = [(cx + (r + wd / 2) * math.cos(a), cy + (r + wd / 2) * math.sin(a)) for a, wd in zip(ang, widths)]
    inner = [(cx + (r - wd / 2) * math.cos(a), cy + (r - wd / 2) * math.sin(a)) for a, wd in zip(ang, widths)]
    draw.polygon(outer + inner[::-1], fill=color)

def breathing_widths(n, w_min, w_max, phase):
    """Width that swells and thins slowly along the stroke."""
    t = np.linspace(0, 1, n)
    k = 0.5 + 0.5 * np.sin(phase + t * 7.3) * np.sin(phase * 0.7 + t * 2.1)
    return (w_min + (w_max - w_min) * k).tolist()

def stars(c, img, sky_frac):
    """Pixel mode, dark themes only: single bright cells scattered over the sky."""
    if not (c.pixel and not c.light): return img
    lay, d = layer(c.w, c.h)
    for _ in range(int(c.w * c.h * sky_frac * 0.006)):
        x, y = c.rng.randrange(c.w), c.rng.randrange(max(1, int(c.h * sky_frac)))
        d.point((x, y), mix(c.bg, c.fg, c.rng.uniform(0.3, 0.9)) + (255,))
    return Image.alpha_composite(img, lay)

# ----------------------------------------------------------------------------- flavour: ridges
def ridge_points(w, h, base, amp, rng, step):
    parts = [(amp * rng.uniform(0.6, 1.0), rng.uniform(0.8, 1.6), rng.uniform(0, 6.28)),
             (amp * rng.uniform(0.25, 0.5), rng.uniform(2.5, 4.5), rng.uniform(0, 6.28)),
             (amp * rng.uniform(0.08, 0.18), rng.uniform(8, 14), rng.uniform(0, 6.28)),
             (amp * rng.uniform(0.02, 0.05), rng.uniform(30, 50), rng.uniform(0, 6.28))]
    xs = np.arange(-step, w + 2 * step, step)
    return list(zip(xs.tolist(), (base - wave(xs, w, parts)).tolist()))

def ridges(c):
    w, h, rng, s = c.w, c.h, c.rng, c.s
    tints = list(c.tints[1:]) + [c.accent]            # the nearest ridge gets the accent
    sky_top = c.bg if c.light else mix(c.bg, c.fg, 0.10)
    img = gradient(c, sky_top, mix(c.bg, tints[0], 0.08))
    step = max(1, w // 1500)
    n_ridges = rng.randint(7, 9) if c.portrait else rng.randint(5, 7)
    horizon = h * (rng.uniform(0.30, 0.38) if c.portrait else rng.uniform(0.40, 0.52))
    img = stars(c, img, horizon / h)
    for i in range(n_ridges):
        d = i / (n_ridges - 1)                        # 0 = farthest, 1 = nearest
        base = horizon + (h - horizon) * (0.05 + 0.80 * d ** 1.15)
        amp = h * (0.035 + 0.09 * d) * rng.uniform(0.8, 1.2) * (0.7 if c.portrait else 1)
        pts = ridge_points(w, h, base, amp, rng, step)
        tint = tints[i % len(tints)]
        if c.light: fill = mix(mix(c.bg, c.fg, 0.04 + 0.16 * d), tint, 0.10 + 0.18 * d)
        else:       fill = mix(mix(c.bg, (0, 0, 0), 0.10 + 0.45 * d), tint, 0.08 + 0.22 * d)
        lay, ld = layer(w, h)
        ld.polygon(pts + [(w + 2 * step, h + step), (-step, h + step)], fill=fill + (255,))
        line_col = mix(fill, tint, 0.55 + 0.35 * d) + (int(140 + 100 * d),)
        ribbon(ld, pts, breathing_widths(len(pts), (0.8 + 1.2 * d) * s, (1.5 + 5 * d) * s, rng.uniform(0, 6.28)), line_col)
        img = comp(c, img, lay, (0.5 - d) * 6 * s if d < 0.5 else 0)   # far ridges soften into haze
    return img

# ----------------------------------------------------------------------------- flavour: contours
def contours(c):
    w, h, rng, s = c.w, c.h, c.rng, c.s
    # Coordinates in "canvas heights" so wavelengths are isotropic on both monitors.
    x = np.linspace(0, w / h, w, dtype=np.float32)[None, :]
    y = np.linspace(0, 1, h, dtype=np.float32)[:, None]
    H = np.zeros((h, w), np.float32)
    for i in range(6):                                # rolling terrain: directional sines
        f, th = rng.uniform(0.5, 2.2) * (1 + 0.35 * i), rng.uniform(0, math.pi)
        H += (1.0 / (1 + 0.9 * i)) * np.sin(2 * np.pi * f * (x * math.cos(th) + y * math.sin(th)) + rng.uniform(0, 6.28))
    for _ in range(rng.randint(2, 4)):                # summits: Gaussian bumps -> closed rings
        cx, cy, sg = rng.uniform(0.1, w / h - 0.1), rng.uniform(0.15, 0.85), rng.uniform(0.10, 0.22)
        H += rng.uniform(1.0, 2.2) * np.exp(-((x - cx) ** 2 + (y - cy) ** 2) / (2 * sg * sg))
    H -= H.min(); H /= H.max()
    N = 26 if c.portrait else 22                      # number of levels
    v = H * N
    lvl = np.floor(v)
    frac = v - lvl
    dl = np.minimum(frac, 1 - frac)                   # distance to the nearest level, in levels
    gy, gx = np.gradient(v)
    g = np.hypot(gx, gy) + 1e-6; del gx, gy
    dpx = dl / g; del dl                              # ... and in pixels
    blob = np.clip(g / (0.12 * float(np.median(g))), 0, 1)   # no fat blobs where the field is flat
    del g
    wmod = 0.5 + 0.5 * np.sin(2 * np.pi * (rng.uniform(0.6, 1.2) * x + rng.uniform(0.6, 1.2) * y) + rng.uniform(0, 6.28))
    hw = (0.55 + 0.9 * wmod) * s; del wmod            # half-width breathes across the map
    if c.pixel: hw = np.full_like(hw, 0.5)            # 1-cell lines, 2-cell index lines
    index = (lvl % 5) == 4
    a_reg = np.clip(hw + 0.6 - dpx, 0, 1) * blob * (0.35 + 0.55 * H)
    a_idx = np.clip((1.5 if c.pixel else 2.0) * hw + 0.6 - dpx, 0, 1) * blob * 0.95
    del dpx, blob, hw
    t0, t1 = c.tints[1], c.tints[2]
    band = (0.03 + 0.09 * (lvl / N))[..., None]        # faint stepped fill climbs with height
    base = np.array(c.bg, np.float32) + (np.array(t0, np.float32) - np.array(c.bg, np.float32)) * band
    base += noise(c, base.shape, 0.5)
    img = Image.fromarray(np.clip(np.rint(base), 0, 255).astype(np.uint8), "RGB").convert("RGBA"); del base, band
    k = (0.45 + 0.45 * H)[..., None]
    reg_rgb = np.array(c.bg, np.float32) + (np.array(t1, np.float32) - np.array(c.bg, np.float32)) * k; del k, H
    img = Image.alpha_composite(img, np_layer(reg_rgb, np.where(index, 0, a_reg))); del reg_rgb, a_reg
    img = Image.alpha_composite(img, np_layer(c.accent, np.where(index, a_idx, 0)))
    return img

# ----------------------------------------------------------------------------- flavour: strands
def strands(c):
    w, h, rng, s = c.w, c.h, c.rng, c.s
    L, T = (h, w) if c.portrait else (w, h)           # along / across the long axis
    n, steps = (44, 1100) if c.portrait else (52, 900)
    if c.pixel: n //= 2
    ts = np.linspace(-0.02, 1.02, steps)
    def along(parts): return sum(a * np.sin(2 * np.pi * f * ts + ph) for a, f, ph in parts)
    centre = T * 0.5 + along([(T * 0.16, rng.uniform(0.5, 0.9), rng.uniform(0, 6.28)),
                              (T * 0.06, rng.uniform(1.4, 2.2), rng.uniform(0, 6.28))])
    spread = T * (0.05 + 0.30 * (0.5 + 0.5 * np.sin(2 * np.pi * rng.uniform(0.9, 1.6) * ts + rng.uniform(0, 6.28))))
    def to_xy(pos): return list(zip(pos.tolist(), (ts * L).tolist())) if c.portrait else list(zip((ts * L).tolist(), pos.tolist()))
    img = gradient(c, c.bg if c.light else mix(c.bg, c.fg, 0.06), mix(c.bg, c.tints[1], 0.06))
    if not c.pixel:                                   # soft accent haze under the bundle
        glow, gd = layer(w, h)
        ribbon(gd, to_xy(centre), (spread * 1.8).tolist(), c.accent + (28,), vertical=c.portrait)
        img = comp(c, img, glow, 40 * s)
    lay, d = layer(w, h)
    offsets = sorted(rng.uniform(-1, 1) for _ in range(n))
    offsets = [math.copysign(abs(o) ** 1.4, o) for o in offsets]   # denser near the middle
    for k, b in enumerate(offsets):
        pos = centre + b * spread + along([(T * 0.012, rng.uniform(2, 5), rng.uniform(0, 6.28))])
        near = 1 - abs(b)
        widths = breathing_widths(steps, (0.5 + 1.2 * near) * s, (1.4 + 3.5 * near) * s, rng.uniform(0, 6.28))
        tint = c.accent if (k % 9 == 4 or near > 0.85) else c.tints[1 + k % 3]
        ribbon(d, to_xy(pos), widths, mix(c.bg, tint, 0.45 + 0.5 * near) + (int(90 + 150 * near),), vertical=c.portrait)
    return comp(c, img, lay, 0.6 * s)

# ----------------------------------------------------------------------------- flavour: waves
def waves(c):
    w, h, rng, s = c.w, c.h, c.rng, c.s
    n = 64 if c.portrait else 50
    if c.pixel: n = n * 2 // 3                        # fewer, clearer lines on a small grid
    freqs = [rng.uniform(0.7, 1.2), rng.uniform(1.8, 2.8), rng.uniform(4.5, 7.0)]
    ph0 = [rng.uniform(0, 6.28) for _ in range(3)]
    dph = [rng.uniform(-0.25, 0.25) for _ in range(3)]   # phase drifts line to line: coherent rolling
    xs = np.arange(-4, w + 8, max(1, w // 1500))
    img = gradient(c, mix(c.bg, c.tints[1], 0.06), c.bg)
    groups = [layer(w, h) for _ in range(3)]          # far / mid / near, blurred differently
    for i in range(n):
        t = i / (n - 1)
        y0 = h * (0.10 + 0.88 * t ** 1.5)             # lines bunch up near the top (distance)
        A = h * (0.010 + 0.045 * t)
        parts = [(A, freqs[0], ph0[0] + i * dph[0]), (A * 0.45, freqs[1], ph0[1] + i * dph[1]), (A * 0.15, freqs[2], ph0[2] + i * dph[2])]
        pts = list(zip(xs.tolist(), (y0 - wave(xs, w, parts)).tolist()))
        lay, d = groups[0 if t < 0.3 else 1 if t < 0.65 else 2]
        fill = mix(c.bg, c.tints[1 + i % 2], 0.02 + (0.07 if c.light else 0.09) * t)
        d.polygon(pts + [(w + 8, h + 8), (-4, h + 8)], fill=fill + (255,))   # each sheet hides the ones behind
        accent_line = i % 7 == 3
        tint = c.accent if accent_line else c.tints[2 if i % 2 else 1]
        col = mix(c.bg, tint, 0.3 + 0.65 * t) + (235 if accent_line else int(80 + 170 * t),)
        ribbon(d, pts, breathing_widths(len(pts), (0.5 + 1.2 * t) * s, (1.2 + 3.5 * t) * s, rng.uniform(0, 6.28)), col)
    for (lay, _), blur in zip(groups, (1.6 * s, 0.7 * s, 0.4 * s)):
        img = comp(c, img, lay, blur)
    return img

# ----------------------------------------------------------------------------- flavour: peaks
def jagged(n, amp, rng, roughness=0.55):
    """1-D midpoint displacement: a rough skyline that stays rough at every zoom."""
    ys = np.zeros(n); step, a = n - 1, amp
    while step > 1:
        half = step // 2
        for i in range(half, n, step):
            ys[i] = 0.5 * (ys[i - half] + ys[i + half]) + rng.uniform(-a, a)
        a *= roughness; step = half
    return ys

def peaks(c):
    w, h, rng, s = c.w, c.h, c.rng, c.s
    img = gradient(c, c.bg if c.light else mix(c.bg, c.tints[1], 0.10), mix(c.bg, c.tints[2], 0.04))
    img = stars(c, img, 0.45)
    R = min(w, h) * rng.uniform(0.13, 0.19)
    mx, my = w * rng.uniform(0.22, 0.78), h * (0.26 if c.portrait else 0.36) * rng.uniform(0.85, 1.1)
    lay, d = layer(w, h)
    d.ellipse([mx - R, my - R, mx + R, my + R], fill=mix(c.bg, c.accent, 0.30 if c.light else 0.22) + (255,))
    ring(d, mx, my, R, breathing_widths(360, 1.0 * s, 2.5 * s, rng.uniform(0, 6.28)), c.accent + (230,))
    for j in range(1, 6):                             # halo rings, thinner and fainter outward
        ring(d, mx, my, R * (1 + 0.22 * j), breathing_widths(360, (0.4 + 0.3 / j) * s, (1.0 + 1.6 / j) * s, rng.uniform(0, 6.28)), c.accent + (int(160 / j),))
    img = comp(c, img, lay, 0.5 * s)
    n_l = 5 if c.portrait else 4
    n_pts = 513
    xs = np.linspace(-w * 0.02, w * 1.02, n_pts); u = np.linspace(0, 1, n_pts)
    for i in range(n_l):
        dd = i / (n_l - 1)                            # 0 = farthest, 1 = nearest
        base = h * ((0.46 if c.portrait else 0.50) + 0.40 * dd ** 1.2)
        amp = h * (0.05 + 0.10 * dd) * (0.75 if c.portrait else 1)
        ys = jagged(n_pts, amp * 0.55, rng, 0.62)
        for _ in range(rng.randint(3, 6)):            # a few big triangular summits
            px, pw, ph = rng.uniform(0.05, 0.95), rng.uniform(0.04, 0.16), amp * rng.uniform(0.7, 1.6)
            ys += ph * np.clip(1 - np.abs(u - px) / pw, 0, None)
        pts = list(zip(xs.tolist(), (base - ys).tolist()))
        if c.light: fill = mix(c.bg, c.fg, 0.10 + 0.55 * dd)                       # nearer = darker
        else:       fill = mix(mix(c.bg, c.tints[1], 0.22 * (1 - dd)), (0, 0, 0), 0.25 * dd)   # far hazy, near black
        lay, d = layer(w, h)
        d.polygon(pts + [(w * 1.02, h + 8), (-w * 0.02, h + 8)], fill=fill + (255,))
        rim = mix(fill, c.accent if i == n_l - 1 else c.tints[1 + i % 2], 0.6) + (int(120 + 120 * dd),)
        ribbon(d, pts, breathing_widths(n_pts, (0.6 + 0.8 * dd) * s, (1.2 + 3 * dd) * s, rng.uniform(0, 6.28)), rim)
        img = comp(c, img, lay, (1 - dd) * 3 * s)
    return img


# ----------------------------------------------------------------------------- flavour: dunes
def dunes(c):
    w, h, rng, s = c.w, c.h, c.rng, c.s
    sand, sky = c.tints[1], c.tints[2]
    img = gradient(c, c.bg if c.light else mix(c.bg, sky, 0.14), mix(c.bg, sand, 0.10))
    img = stars(c, img, 0.4)
    # low sun, slightly off centre
    R = min(w, h) * rng.uniform(0.07, 0.11)
    sx, sy = w * rng.uniform(0.25, 0.75), h * (0.30 if c.portrait else 0.38)
    lay, d = layer(w, h)
    d.ellipse([sx - R, sy - R, sx + R, sy + R], fill=mix(c.bg, c.accent, 0.55) + (255,))
    ring(d, sx, sy, R, breathing_widths(360, 0.8 * s, 2.0 * s, rng.uniform(0, 6.28)), c.accent + (220,))
    img = comp(c, img, lay, 0.4 * s)
    n = rng.randint(8, 11) if c.portrait else rng.randint(6, 8)
    xs = np.linspace(-0.05 * w, 1.05 * w, 700, dtype=np.float32)
    xcol = np.linspace(-0.05, 1.05, w, dtype=np.float32) * w          # x of every canvas column
    for i in range(n):
        dd = i / (n - 1)
        base = h * ((0.40 if c.portrait else 0.46) + 0.52 * dd ** 1.1)
        amp = h * (0.05 + 0.14 * dd) * (0.8 if c.portrait else 1)
        # a dune field, not one hump on a plateau: 2-3 humps of different widths plus
        # a slow swell, so the skyline never goes flat
        ys = np.full_like(xs, base) - amp * 0.15 * np.sin(xs / w * rng.uniform(4, 7) + rng.uniform(0, 6.28))
        humps = []
        for _ in range(rng.randint(2, 3)):
            cx, sig, a = w * rng.uniform(-0.05, 1.05), w * rng.uniform(0.12, 0.30), amp * rng.uniform(0.5, 1.0)
            skew = rng.choice([-1, 1]) * rng.uniform(0.7, 1.5)
            u = (xs - cx) / sig
            u = np.where(u * skew > 0, u * (1 + abs(skew)), u)        # one steep flank
            ys -= a * np.exp(-u * u)
            humps.append((cx, sig, skew, a))
        pts = list(zip(xs.tolist(), ys.tolist()))
        lit = mix(c.bg, sand, 0.18 + 0.40 * dd) if c.light else mix(c.bg, sand, 0.30 + 0.45 * dd)
        shade = mix(lit, c.fg if c.light else (0, 0, 0), 0.32)
        # two-tone fill: lit on the windward side of the tallest hump, shaded past
        # its crest, blended over a fraction of the hump width (a soft shadow, no
        # polygon edges). Applied through the dune's own silhouette as a mask.
        cx, sig, skew, _ = max(humps, key=lambda t: t[3])
        side = 1 if skew > 0 else -1
        k = 1 / (1 + np.exp(-(xcol - cx) * side / (0.18 * sig)))     # 0 lit -> 1 shade
        row = np.array(lit, np.float32)[None, :] + (np.array(shade, np.float32) - np.array(lit, np.float32))[None, :] * k[:, None]
        row = np.clip(np.rint(row), 0, 255).astype(np.uint8)         # 8-bit before broadcasting: keeps peak memory low
        mask = Image.new("L", (w, h), 0)
        ImageDraw.Draw(mask).polygon(pts + [(w * 1.05, h + 8), (-w * 0.05, h + 8)], fill=255)
        body = Image.fromarray(np.broadcast_to(row[None, :, :], (h, w, 3)).copy(), "RGB").convert("RGBA")
        body.putalpha(mask); del mask, row, k
        lay, d = layer(w, h)
        rim = (c.accent if i == n - 1 else mix(lit, c.accent, 0.5)) + (int(120 + 110 * dd),)
        ribbon(d, pts, breathing_widths(len(pts), (0.5 + 0.8 * dd) * s, (1.2 + 2.8 * dd) * s, rng.uniform(0, 6.28)), rim)
        img = comp(c, Image.alpha_composite(img, body), lay, (1 - dd) * 2.5 * s)
    return img

# ----------------------------------------------------------------------------- flavour: orbits
def ellipse_ring(draw, cx, cy, rx, ry, tilt, widths, color, n=480):
    """A tilted elliptical ring (outer + reversed inner loop)."""
    ang = np.linspace(0, 2 * np.pi, n, endpoint=False)
    widths = [max(WMIN, wd) for wd in widths]
    ct, st = math.cos(tilt), math.sin(tilt)
    def loop(k):
        pts = []
        for a, wd in zip(ang, widths):
            x, y = (rx + k * wd / 2) * math.cos(a), (ry + k * wd / 2) * math.sin(a)
            pts.append((cx + x * ct - y * st, cy + x * st + y * ct))
        return pts
    draw.polygon(loop(1) + loop(-1)[::-1], fill=color)

def orbits(c):
    w, h, rng, s = c.w, c.h, c.rng, c.s
    img = gradient(c, c.bg if c.light else mix(c.bg, c.tints[2], 0.08), c.bg)
    img = stars(c, img, 1.0)
    cx, cy = w * rng.uniform(0.3, 0.7), h * rng.uniform(0.35, 0.65)
    tilt = rng.uniform(-0.5, 0.5)
    squash = rng.uniform(0.38, 0.7)
    n = rng.randint(9, 13)
    rmax = math.hypot(w, h) * 0.62
    lay, d = layer(w, h)
    # the star
    R0 = min(w, h) * rng.uniform(0.035, 0.055)
    for k, a in ((3.2, 40), (2.2, 80), (1.0, 255)):
        d.ellipse([cx - R0 * k, cy - R0 * k, cx + R0 * k, cy + R0 * k], fill=c.accent + (a,))
    for i in range(1, n + 1):
        t = i / n
        r = R0 * 2.2 + (rmax - R0 * 2.2) * t ** 1.35
        tint = c.accent if i % 4 == 0 else c.tints[1 + i % 3]
        col = mix(c.bg, tint, 0.35 + 0.5 * (1 - t)) + (int(90 + 130 * (1 - t) ** 0.7),)
        ellipse_ring(d, cx, cy, r, r * squash, tilt, breathing_widths(480, (0.4 + 0.6 * (1 - t)) * s, (1.0 + 2.2 * (1 - t)) * s, rng.uniform(0, 6.28)), col)
        if rng.random() < 0.6:                                   # a planet on this orbit
            a = rng.uniform(0, 2 * math.pi)
            px, py = r * math.cos(a), r * squash * math.sin(a)
            x, y = cx + px * math.cos(tilt) - py * math.sin(tilt), cy + px * math.sin(tilt) + py * math.cos(tilt)
            pr = max(1.5 * s, min(w, h) * rng.uniform(0.004, 0.014))
            d.ellipse([x - pr * 2.2, y - pr * 2.2, x + pr * 2.2, y + pr * 2.2], fill=tint + (45,))
            d.ellipse([x - pr, y - pr, x + pr, y + pr], fill=mix(tint, c.fg, 0.25) + (255,))
    return comp(c, img, lay, 0.5 * s)

# ----------------------------------------------------------------------------- flavour: horizon
def horizon(c):
    w, h, rng, s = c.w, c.h, c.rng, c.s
    hy = h * (0.52 if c.portrait else 0.56)
    glow, floor = c.accent, c.tints[1]
    img = gradient(c, c.bg if c.light else mix(c.bg, c.tints[2], 0.10), mix(c.bg, glow, 0.22))
    img = stars(c, img, hy / h * 0.8)
    lay, d = layer(w, h)
    # striped sun sitting on the horizon
    R = min(w, h) * rng.uniform(0.16, 0.22)
    sx, sy = w * rng.uniform(0.35, 0.65), hy - R * 0.25
    sun = Image.new("RGBA", (w, h), (0, 0, 0, 0)); sd = ImageDraw.Draw(sun)
    sd.ellipse([sx - R, sy - R, sx + R, sy + R], fill=mix(c.bg, glow, 0.85) + (255,))
    for k in range(7):                                           # gaps widen toward the bottom
        y0 = sy + R * (0.05 + 0.13 * k) + R * 0.02 * k * k
        sd.rectangle([sx - R - 2, y0, sx + R + 2, y0 + R * (0.02 + 0.02 * k)], fill=(0, 0, 0, 0))
    sd.rectangle([0, hy, w, h], fill=(0, 0, 0, 0))               # nothing below the horizon
    img = Image.alpha_composite(img, sun)
    if not c.pixel:
        hl, hd = layer(w, h)
        hd.ellipse([sx - R * 1.6, sy - R * 1.6, sx + R * 1.6, sy + R * 1.6], fill=glow + (60,))
        img = comp(c, img, hl, 30 * s)
    # the floor
    d.rectangle([0, hy, w, h], fill=mix(c.bg, (0, 0, 0) if not c.light else c.fg, 0.25 if not c.light else 0.06) + (255,))
    vx = sx
    n_h = 14 if c.portrait else 12
    for i in range(1, n_h + 1):
        t = (i / n_h) ** 2.2
        y = hy + (h - hy) * t
        col = mix(c.bg, floor, 0.35 + 0.6 * t) + (int(110 + 140 * t),)
        ribbon(d, [(0, y), (w, y)], [(0.6 + 2.2 * t) * s] * 2, col)
    n_v = 26 if c.portrait else 34
    for j in range(-n_v, n_v + 1):
        x_far = vx + j * w * 0.06 * 0.12
        x_near = vx + j * w * 0.06 * 3.0
        col = mix(c.bg, floor, 0.55) + (150,)
        ribbon(d, [(x_far, hy), (x_near, h + 4)], [0.6 * s, 1.8 * s], col, vertical=True)
    ribbon(d, [(0, hy), (w, hy)], [1.5 * s] * 2, glow + (255,))
    return comp(c, img, lay, 0.4 * s)

# ----------------------------------------------------------------------------- flavour: constellation
def constellation(c):
    w, h, rng, s = c.w, c.h, c.rng, c.s
    img = gradient(c, c.bg if c.light else mix(c.bg, c.tints[2], 0.07), c.bg if c.light else mix(c.bg, c.tints[1], 0.05))
    img = stars(c, img, 1.0)
    n = 110 if c.portrait else 130
    if c.pixel: n = n * 3 // 5
    pts = np.array([(rng.uniform(0.02, 0.98) * w, rng.uniform(0.04, 0.96) * h) for _ in range(n)])
    lay, d = layer(w, h)
    # faint dust: tiny dots
    if not c.pixel:
        for _ in range(n * 6):
            x, y, r = rng.uniform(0, w), rng.uniform(0, h), rng.uniform(0.3, 0.9) * s
            d.ellipse([x - r, y - r, x + r, y + r], fill=mix(c.bg, c.fg, 0.5) + (rng.randint(40, 120),))
    # edges: each star to its 2-3 nearest, within reach, grouped by a random cluster id
    reach = min(w, h) * 0.17
    dist = np.hypot(pts[:, None, 0] - pts[None, :, 0], pts[:, None, 1] - pts[None, :, 1])
    np.fill_diagonal(dist, 1e9)
    cluster = [rng.randrange(4) for _ in range(n)]
    drawn = set()
    for i in range(n):
        for j in np.argsort(dist[i])[: rng.randint(2, 3)]:
            j = int(j)
            if dist[i, j] > reach or (min(i, j), max(i, j)) in drawn: continue
            drawn.add((min(i, j), max(i, j)))
            tint = c.tints[1 + cluster[i] % 3]
            ribbon(d, [tuple(pts[i]), tuple(pts[j])], [0.7 * s, 0.7 * s], mix(c.bg, tint, 0.55) + (140,))
    # nodes
    deg = np.zeros(n, int)
    for i, j in drawn: deg[i] += 1; deg[j] += 1
    for i in range(n):
        x, y = pts[i]
        bright = deg[i] >= 3 or rng.random() < 0.08
        r = (1.2 + 0.9 * deg[i]) * s * (1.6 if bright else 1)
        if c.pixel: r = 0.6 + 0.4 * deg[i] + (0.8 if bright else 0)   # a few cells, no halo
        col = c.accent if bright else mix(c.bg, c.fg, 0.75)
        if bright and not c.pixel: d.ellipse([x - r * 3, y - r * 3, x + r * 3, y + r * 3], fill=c.accent + (45,))
        d.ellipse([x - r, y - r, x + r, y + r], fill=col + (255,))
    return comp(c, img, lay, 0.4 * s)

# ----------------------------------------------------------------------------- flavour: strata
def strata(c):
    w, h, rng, s = c.w, c.h, c.rng, c.s
    img = gradient(c, c.bg, c.bg)
    n = rng.randint(30, 40) if c.portrait else rng.randint(22, 30)
    xs = np.linspace(-0.02 * w, 1.02 * w, 1025)    # 2^k + 1 points: what jagged() needs
    slope = rng.uniform(-0.08, 0.08) * h
    lay, d = layer(w, h)
    prev = None
    for i in range(n + 1):
        t = i / n
        y0 = h * (-0.02 + 1.06 * t ** rng.uniform(0.95, 1.05))
        ys = y0 + slope * (xs / w - 0.5) + wave(xs, w, [(h * 0.012, rng.uniform(0.6, 1.4), rng.uniform(0, 6.28)),
                                                       (h * 0.004, rng.uniform(3, 6), rng.uniform(0, 6.28))])
        ys += jagged(len(xs), h * 0.003, rng, 0.5)
        if prev is not None:
            tint = c.tints[1 + i % 3] if i % 5 else c.accent
            k = 0.06 + 0.26 * (0.5 + 0.5 * math.sin(i * 1.7 + rng.uniform(0, 0.5)))
            fill = mix(c.bg, tint, k) if not c.light else mix(c.bg, tint, k * 0.8)
            poly = list(zip(xs.tolist(), prev.tolist())) + list(zip(xs.tolist(), ys.tolist()))[::-1]
            d.polygon(poly, fill=fill + (255,))
            line = (c.accent + (220,)) if i % 5 == 0 else (mix(fill, c.fg, 0.18) + (120,))
            ribbon(d, list(zip(xs.tolist(), ys.tolist())), breathing_widths(len(xs), 0.5 * s, (1.0 if i % 5 else 2.4) * s, rng.uniform(0, 6.28)), line)
        prev = ys
    return comp(c, img, lay, 0.35 * s)

# ----------------------------------------------------------------------------- flavour: meteors
def meteors(c):
    w, h, rng, s = c.w, c.h, c.rng, c.s
    img = gradient(c, c.bg if c.light else mix(c.bg, c.tints[2], 0.09), c.bg)
    img = stars(c, img, 1.0)
    ang = math.radians(rng.uniform(-42, -28) if not c.portrait else rng.uniform(-62, -50))
    dx, dy = math.cos(ang), -math.sin(ang)           # streak direction (down-right or down-left)
    if rng.random() < 0.5: dx = -dx
    n = 70 if c.portrait else 60
    if c.pixel: n = n * 2 // 3
    lay, d = layer(w, h)
    glow, gd = layer(w, h)
    for i in range(n):
        near = rng.random() ** 1.2                   # mostly far and faint, a good share big
        L = min(w, h) * (0.08 + 0.55 * near) * rng.uniform(0.7, 1.3)
        x1, y1 = rng.uniform(-0.1, 1.1) * w, rng.uniform(-0.1, 1.0) * h
        x0, y0 = x1 - dx * L, y1 - dy * L
        steps = 40
        pts = [(x0 + (x1 - x0) * k / steps, y0 + (y1 - y0) * k / steps) for k in range(steps + 1)]
        wmax = (1.4 + 7.0 * near) * s
        widths = [wmax * (k / steps) ** 1.4 for k in range(steps + 1)]   # tapers from the tail to the head
        tint = c.accent if (near > 0.75 or i % 6 == 0) else c.tints[1 + i % 3]
        col = mix(c.bg, tint, 0.55 + 0.45 * near) + (int(120 + 135 * near),)
        ribbon(d, pts, widths, col, vertical=abs(dy) > abs(dx))
        hr = wmax * 0.9
        d.ellipse([x1 - hr, y1 - hr, x1 + hr, y1 + hr], fill=mix(tint, c.fg, 0.4) + (int(120 + 135 * near),))
        if near > 0.6 and not c.pixel:
            ribbon(gd, pts, [wd * 3 for wd in widths], tint + (40,), vertical=abs(dy) > abs(dx))
    img = comp(c, img, glow, 12 * s)
    return comp(c, img, lay, 0.4 * s)

# ----------------------------------------------------------------------------- pixel-art post-processing
BAYER8 = np.array([[ 0, 32,  8, 40,  2, 34, 10, 42], [48, 16, 56, 24, 50, 18, 58, 26],
                   [12, 44,  4, 36, 14, 46,  6, 38], [60, 28, 52, 20, 62, 30, 54, 22],
                   [ 3, 35, 11, 43,  1, 33,  9, 41], [51, 19, 59, 27, 49, 17, 57, 25],
                   [15, 47,  7, 39, 13, 45,  5, 37], [63, 31, 55, 23, 61, 29, 53, 21]], np.float32) / 64 - 0.5

def pixel_palette(c):
    """A small palette from the theme: bg, fg, accent, and each tint at a few levels."""
    cols = {c.bg, c.fg, c.accent}
    for t in c.tints + [c.fg]:
        for k in (0.06, 0.13, 0.22, 0.33, 0.46, 0.60, 0.76, 0.90, 1.0):
            cols.add(mix(c.bg, t, k))
    shade = (255, 255, 255) if c.light else (0, 0, 0)
    for k in (0.2, 0.45): cols.add(mix(c.bg, shade, k))
    return np.array(sorted(cols), np.float32)

def pixelate(c, small, w, h, cell):
    """Snap every cell to the nearest palette colour after adding an ordered-dither
    threshold (classic Bayer), then scale up with hard edges and centre on a bg canvas."""
    arr = np.asarray(small.convert("RGB")).astype(np.float32)
    gh, gw = arr.shape[:2]
    thr = np.tile(BAYER8, (gh // 8 + 1, gw // 8 + 1))[:gh, :gw][..., None] * 16.0
    pal = pixel_palette(c)
    d = ((arr + thr)[:, :, None, :] - pal[None, None, :, :]) ** 2
    idx = d.sum(-1).argmin(-1)
    out = Image.fromarray(pal[idx].astype(np.uint8), "RGB").resize((gw * cell, gh * cell), Image.NEAREST)
    canvas = Image.new("RGB", (w, h), c.bg)
    canvas.paste(out, ((w - out.width) // 2, (h - out.height) // 2))
    return canvas

# ----------------------------------------------------------------------------- main
FLAVOURS = {"ridges": ridges, "contours": contours, "strands": strands, "waves": waves, "peaks": peaks,
            "dunes": dunes, "orbits": orbits, "horizon": horizon, "constellation": constellation,
            "strata": strata, "meteors": meteors}

def main(palette_path, out, w, h, flavour="ridges"):
    global WMIN
    pixel = flavour.startswith("pixel-")
    base = flavour[6:] if pixel else flavour
    if base not in FLAVOURS:
        sys.exit(f"wallpaper.py: unknown flavour '{flavour}'; choose from: " +
                 " ".join(list(FLAVOURS) + ["pixel-" + f for f in FLAVOURS]))
    p = json.load(open(palette_path))
    seed = f"{p['THEME']}:{base}"                     # pixel-X is the same scene as X, re-styled
    c = SimpleNamespace(portrait=h > w, light=p["IS_LIGHT"] == "1", pixel=pixel,
                        rng=random.Random(seed), nprng=np.random.default_rng(abs(hash(seed)) % 2**32),
                        bg=hex2rgb(p["BG"]), fg=hex2rgb(p["FG"]), accent=hex2rgb(p["ACCENT"]))
    c.tints = harmony(p, c.accent)
    if pixel:
        # Compose on a coarse grid (~212 cells along the short side, like a retro screen),
        # 1-px strokes, no blur; then dither to the palette and scale up with hard edges.
        cell = max(1, round(min(w, h) / 212))
        c.w, c.h, c.s = w // cell, h // cell, 1.0
        WMIN = 1.0
        small = FLAVOURS[base](c)
        pixelate(c, small, w, h, cell).save(out, "PNG", compress_level=6)
        return
    # Smooth: draw 1.5x supersampled, then downscale with Lanczos for anti-aliased
    # edges. contours is drawn analytically anti-aliased in numpy, so it skips that
    # (and the memory it would cost at 46 MP).
    ss = 1.0 if base == "contours" else 1.5
    c.w, c.h = round(w * ss), round(h * ss)
    # Stroke scale: ~1.7 px at the 2x-rendered 4K size. The portrait 1080p panel shows
    # 2 image px per physical px, so it gets a nudge to keep lines visible.
    c.s = max(0.8, min(2.0, min(w, h) / 2000)) * (1.5 if c.portrait else 1.0) * ss
    img = FLAVOURS[base](c).convert("RGB")
    if ss != 1.0: img = img.resize((w, h), Image.LANCZOS)
    # +-1 LSB grain: invisible, but it breaks up any remaining 8-bit banding in dark gradients.
    arr = np.array(img, dtype=np.uint8); del img
    for y0 in range(0, h, 256):                       # row chunks keep peak memory down
        blk = arr[y0:y0 + 256].astype(np.float32) + noise(c, arr[y0:y0 + 256].shape, 1.0)
        arr[y0:y0 + 256] = np.clip(np.rint(blk), 0, 255)
    Image.fromarray(arr, "RGB").save(out, "PNG", compress_level=6)

if __name__ == "__main__":
    if len(sys.argv) not in (5, 6):
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), *sys.argv[5:])
