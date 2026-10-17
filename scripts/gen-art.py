#!/usr/bin/env python3
"""Generate Cipher artwork: theme backgrounds, logo, boot splash, GRUB background.

Everything is drawn from the theme palettes, so adding a theme and re-running
this script gives it matching backgrounds. Needs Pillow (python3-pil).

  python3 scripts/gen-art.py            # all themes
  python3 scripts/gen-art.py nord       # just one
"""

import json
import math
import random
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
PKG = ROOT / "packages/cipher-desktop"
THEMES = PKG / "usr/share/cipher/themes"
BRANDING = PKG / "usr/share/cipher/branding"
W, H = 2560, 1440
SS = 2  # supersampling for smooth lines


def rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def mix(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def gradient(size, top, bottom, angle_mix=0.35):
    w, h = size
    img = Image.new("RGB", size)
    px = img.load()
    for y in range(h):
        for x in range(0, w, 4):
            t = min(1.0, max(0.0, (y / h) * (1 - angle_mix) + (x / w) * angle_mix))
            c = mix(top, bottom, t)
            for dx in range(4):
                if x + dx < w:
                    px[x + dx, y] = c
    return img


def glow(size, center, radius, color, strength):
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    cx, cy = center
    d.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], fill=color + (int(255 * strength),))
    return layer.filter(ImageFilter.GaussianBlur(radius * 0.55))


def hexagon(cx, cy, r, rot=-math.pi / 2):
    return [(cx + r * math.cos(rot + i * math.pi / 3), cy + r * math.sin(rot + i * math.pi / 3)) for i in range(6)]


def lattice(theme, seed):
    c = {k: rgb(v) for k, v in theme["colors"].items()}
    light = theme.get("light", False)
    base = gradient((W, H), c["bg"], mix(c["bg"], c["surface"], 0.9))
    base = base.convert("RGBA")
    base.alpha_composite(glow((W, H), (int(W * 0.18), int(H * 0.85)), 700, c["accent"], 0.20 if not light else 0.12))
    base.alpha_composite(glow((W, H), (int(W * 0.88), int(H * 0.12)), 520, c["accent2"], 0.14 if not light else 0.08))

    big = Image.new("RGBA", (W * SS, H * SS), (0, 0, 0, 0))
    d = ImageDraw.Draw(big)
    rnd = random.Random(seed)
    r = 46 * SS
    dx, dy = r * math.sqrt(3), r * 1.5
    rows, cols = int(H * SS / dy) + 2, int(W * SS / dx) + 2
    for row in range(rows):
        for col in range(cols):
            cx = col * dx + (dx / 2 if row % 2 else 0)
            cy = row * dy
            # fade the lattice in from the left-bottom glow
            fx, fy = cx / (W * SS), cy / (H * SS)
            fade = max(0.0, 1.0 - math.hypot(fx - 0.15, fy - 0.9) * 1.25)
            if fade <= 0.02:
                continue
            a = int(70 * fade) if not light else int(55 * fade)
            d.polygon(hexagon(cx, cy, r * 0.94), outline=c["accent"] + (a,), width=SS)
            if rnd.random() < 0.035 * fade * 3:
                d.polygon(hexagon(cx, cy, r * 0.94), fill=c["accent"] + (int(a * 0.7),))
    base.alpha_composite(big.resize((W, H), Image.LANCZOS))
    return base.convert("RGB")


def signal(theme, seed):
    c = {k: rgb(v) for k, v in theme["colors"].items()}
    light = theme.get("light", False)
    base = gradient((W, H), mix(c["bg"], c["surface"], 0.6), c["bg"], angle_mix=0.6).convert("RGBA")
    base.alpha_composite(glow((W, H), (int(W * 0.7), int(H * 0.55)), 820, c["accent2"], 0.12 if not light else 0.07))

    big = Image.new("RGBA", (W * SS, H * SS), (0, 0, 0, 0))
    d = ImageDraw.Draw(big)
    rnd = random.Random(seed)
    phases = [rnd.uniform(0, math.tau) for _ in range(4)]
    lines = 34
    for i in range(lines):
        t = i / (lines - 1)
        color = mix(c["accent"], c["accent2"], t)
        y0 = H * SS * (0.28 + 0.5 * t)
        pts = []
        for x in range(0, W * SS + 1, 6 * SS):
            u = x / (W * SS)
            y = (y0
                 + 90 * SS * math.sin(u * 5.2 + phases[0] + t * 1.6)
                 + 50 * SS * math.sin(u * 11.0 + phases[1] - t * 2.4)
                 + 26 * SS * math.sin(u * 23.0 + phases[2] + t * 4.0) * (1 - u))
            pts.append((x, y))
        alpha = int((40 + 70 * math.sin(math.pi * t)) * (0.75 if light else 1.0))
        d.line(pts, fill=color + (alpha,), width=SS + (1 if i % 6 == 0 else 0) * SS)
    base.alpha_composite(big.resize((W, H), Image.LANCZOS))
    return base.convert("RGB")


# ---- Aurora "silk" wallpaper -------------------------------------------------
# The same curves as the Cipher Aurora design (drawn in a 1440x900 space).

def _bezier(p0, p1, p2, p3, n=48):
    pts = []
    for i in range(n + 1):
        t = i / n
        u = 1 - t
        pts.append((u ** 3 * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t ** 3 * p3[0],
                    u ** 3 * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t ** 3 * p3[1]))
    return pts


def _curve(start, segs):
    """segs: list of (c1, c2, end) cubic segments, c1=None means smooth (reflect)."""
    pts, cur, prev_c2 = [start], start, None
    for c1, c2, end in segs:
        if c1 is None:
            c1 = (2 * cur[0] - prev_c2[0], 2 * cur[1] - prev_c2[1])
        pts += _bezier(cur, c1, c2, end)[1:]
        cur, prev_c2 = end, c2
    return pts


def _gradient_layer(size, stops, horizontal=False, diagonal=False):
    w, h = size
    stops = [rgb(s) for s in stops]
    img = Image.new("RGB", (w, h))
    px = img.load()
    for y in range(h):
        for x in range(0, w, 2):
            if diagonal:
                t = (x / w + y / h) / 2
            elif horizontal:
                t = x / w
            else:
                t = y / h
            seg = min(len(stops) - 2, int(t * (len(stops) - 1)))
            lt = t * (len(stops) - 1) - seg
            c = mix(stops[seg], stops[seg + 1], lt)
            px[x, y] = c
            if x + 1 < w:
                px[x + 1, y] = c
    return img


def silk(theme):
    """Layered silk ribbons with a glowing edge — the Cipher Aurora wallpaper."""
    a = theme["art"]
    W2, H2 = W, H
    sx, sy = W2 / 1440, H2 / 900

    def S(pts):
        return [(x * sx, y * sy) for x, y in pts]

    back = _curve((-60, 250), [((260, 110), (520, 410), (860, 320)), (None, (1300, 70), (1500, 140))])
    ribbon_top = _curve((-60, 420), [((240, 300), (560, 560), (900, 470)), (None, (1320, 260), (1500, 330))])
    ribbon_bot = _curve((1500, 420), [((1300, 360), (980, 600), (720, 610)), (None, (220, 470), (-60, 560))])
    silk_top = _curve((-60, 560), [((300, 430), (600, 760), (980, 640)), (None, (1340, 470), (1500, 540))])
    foot_top = _curve((-60, 720), [((260, 640), (640, 900), (1020, 800)), (None, (1360, 690), (1500, 740))])

    img = _gradient_layer((W2, H2), a["sky"])

    def fill(poly, layer, alpha=1.0, fade=None):
        mask = Image.new("L", (W2 * SS, H2 * SS), 0)
        ImageDraw.Draw(mask).polygon([(x * SS, y * SS) for x, y in S(poly)], fill=int(255 * alpha))
        mask = mask.resize((W2, H2), Image.LANCZOS).filter(ImageFilter.GaussianBlur(0.6))
        if fade:
            # horizontal opacity ramp (left, right) for a silk-like falloff
            ramp = Image.linear_gradient("L").rotate(90, expand=True).resize((W2, H2))
            ramp = ramp.point(lambda v: int(255 * (fade[1] + (fade[0] - fade[1]) * v / 255)))
            mask = Image.composite(mask, Image.new("L", (W2, H2), 0), mask)
            from PIL import ImageChops
            mask = ImageChops.multiply(mask, ramp)
        img.paste(layer, (0, 0), mask)

    fill(back + [(1500, 900), (-60, 900)], _gradient_layer((W2, H2), a["back"], diagonal=True))
    fill(ribbon_top + ribbon_bot, _gradient_layer((W2, H2), a["ribbon"], horizontal=True), 0.7, fade=(1.0, 0.25))
    # shade the lower half of the scene so the silk reads as folded fabric
    shade = Image.new("RGB", (W2, H2), rgb(a["foot"]))
    shade_mask = Image.linear_gradient("L").resize((W2, H2)).point(lambda v: int(v * 0.45))
    fill(silk_top + [(1500, 900), (-60, 900)], _gradient_layer((W2, H2), a["silk"], diagonal=True))
    img.paste(shade, (0, 0), shade_mask)
    fill(foot_top + [(1500, 900), (-60, 900)], Image.new("RGB", (W2, H2), rgb(a["foot"])), 0.85)

    # soft sheen on the main silk, then the glowing edge lines
    glow_layer = Image.new("RGBA", (W2, H2), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow_layer)
    gd.line(S(silk_top), fill=rgb(a["line"]) + (150,), width=int(16 * sx))
    glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(18))
    base = img.convert("RGBA")
    base.alpha_composite(glow_layer)

    lines = Image.new("RGBA", (W2 * SS, H2 * SS), (0, 0, 0, 0))
    ld = ImageDraw.Draw(lines)
    ld.line([(x * SS, y * SS) for x, y in S(silk_top)], fill=rgb(a["line"]) + (215,), width=int(2.6 * SS))
    ld.line([(x * SS, y * SS) for x, y in S(ribbon_top)], fill=rgb(a["line2"]) + (105,), width=int(1.6 * SS))
    base.alpha_composite(lines.resize((W2, H2), Image.LANCZOS))
    return base.convert("RGB")


def logo(size, color, bg=None, stroke_ratio=1 / 11):
    s = size * SS
    img = Image.new("RGBA", (s, s), (bg + (255,)) if bg else (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    stroke = max(2, int(s * stroke_ratio))
    cx = cy = s / 2
    r = s / 2 - stroke
    pts = hexagon(cx, cy, r)
    d.line(pts + [pts[0], pts[1]], fill=color + (255,), width=stroke, joint="curve")
    ir = r * 0.45
    d.arc([cx - ir, cy - ir, cx + ir, cy + ir], start=45, end=315, fill=color + (255,), width=stroke)
    dr = stroke * 0.75
    d.ellipse([cx + r * 0.05 - dr, cy - dr, cx + r * 0.05 + dr, cy + dr], fill=color + (255,))
    return img.resize((size, size), Image.LANCZOS)


def branding():
    cipher = json.loads((THEMES / "aurora/theme.json").read_text())
    c = {k: rgb(v) for k, v in cipher["colors"].items()}
    BRANDING.mkdir(parents=True, exist_ok=True)
    logo(256, c["accent"]).save(BRANDING / "logo.png")
    logo(96, c["accent"]).save(BRANDING / "logo-96.png")
    logo(512, c["accent"], bg=c["bg"]).save(BRANDING / "icon.png")
    # GRUB / isolinux background: the lattice wallpaper at 1920x1080 with the mark
    bg = silk(cipher).resize((1920, 1080), Image.LANCZOS).convert("RGBA")
    mark = logo(160, c["accent"])
    bg.alpha_composite(mark, (1920 // 2 - 80, 1080 // 2 - 220))
    bg.convert("RGB").save(BRANDING / "boot-background.png")
    # Plymouth needs the mark plus a progress-bar sprite
    Image.new("RGBA", (360, 4), c["accent"] + (255,)).save(BRANDING / "progress.png")
    Image.new("RGBA", (360, 4), c["overlay"] + (255,)).save(BRANDING / "progress-track.png")
    # Plymouth copies its theme folder into the initramfs, so real files, not symlinks
    plymouth = PKG / "usr/share/plymouth/themes/cipher"
    plymouth.mkdir(parents=True, exist_ok=True)
    for name in ("logo.png", "progress.png", "progress-track.png"):
        (plymouth / name).write_bytes((BRANDING / name).read_bytes())


def main(names):
    for d in sorted(THEMES.iterdir()):
        if names and d.name not in names:
            continue
        theme = json.loads((d / "theme.json").read_text())
        out = d / "backgrounds"
        out.mkdir(exist_ok=True)
        seed = sum(map(ord, d.name))
        if "art" in theme:
            silk(theme).save(out / "0-silk.png", optimize=True)
        lattice(theme, seed).save(out / "1-lattice.png", optimize=True)
        signal(theme, seed + 1).save(out / "2-signal.png", optimize=True)
        print("backgrounds:", d.name)
    if not names or "aurora" in names:
        branding()
        print("branding: done")


if __name__ == "__main__":
    main(sys.argv[1:])
