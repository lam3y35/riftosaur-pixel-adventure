import math
import os
import random
from PIL import Image, ImageDraw

OUT_DIR = "assets/sprites"
W, H = 480, 270


def clamp_byte(v: float) -> int:
    return max(0, min(255, int(round(v))))


def lerp_color(c1, c2, t: float):
    t = max(0.0, min(1.0, t))
    a1 = 255 if len(c1) < 4 else c1[3]
    a2 = 255 if len(c2) < 4 else c2[3]
    return (
        clamp_byte(c1[0] + (c2[0] - c1[0]) * t),
        clamp_byte(c1[1] + (c2[1] - c1[1]) * t),
        clamp_byte(c1[2] + (c2[2] - c1[2]) * t),
        clamp_byte(a1 + (a2 - a1) * t),
    )


def periodic_fbm(x: float, period: float, harmonics: list[tuple[int, float, float]]) -> float:
    a = (x % period) / period * math.tau
    val = 0.0
    for freq, amp, phase in harmonics:
        val += amp * math.sin(a * freq + phase)
    return val


def ordered_dither_gradient(w: int, h: int, stops: list[tuple[float, tuple[int, int, int]]]) -> Image.Image:
    bayer = [
        [0 / 16, 8 / 16, 2 / 16, 10 / 16],
        [12 / 16, 4 / 16, 14 / 16, 6 / 16],
        [3 / 16, 11 / 16, 1 / 16, 9 / 16],
        [15 / 16, 7 / 16, 13 / 16, 5 / 16],
    ]
    img = Image.new("RGBA", (w, h))
    px = img.load()
    for y in range(h):
        ny = y / max(1, h - 1)
        idx = 0
        while idx < len(stops) - 2 and ny > stops[idx + 1][0]:
            idx += 1
        t0, c0 = stops[idx]
        t1, c1 = stops[idx + 1]
        local_t = (ny - t0) / max(1e-5, t1 - t0)
        for x in range(w):
            d = (bayer[y & 3][x & 3] - 0.5) * 0.16
            px[x, y] = lerp_color(c0, c1, local_t + d)
    return img


def composite_glow(base: Image.Image, fn) -> Image.Image:
    overlay = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay, "RGBA")
    fn(draw, overlay)
    return Image.alpha_composite(base, overlay)


def draw_pixel_cloud(draw: ImageDraw.ImageDraw, cx: int, cy: int, scale: int, col_body, col_hi, col_sh):
    puffs = [
        (0, 0, int(18 * scale), int(7 * scale)),
        (-int(10 * scale), 2, int(11 * scale), int(5 * scale)),
        (int(11 * scale), 2, int(12 * scale), int(5 * scale)),
        (-int(4 * scale), -int(4 * scale), int(9 * scale), int(6 * scale)),
        (int(5 * scale), -int(3 * scale), int(8 * scale), int(5 * scale)),
    ]
    for dx_wrap in (-W, 0, W):
        # Shadow bottom slice
        for ox, oy, rx, ry in puffs:
            draw.ellipse([cx + dx_wrap + ox - rx, cy + oy - ry + 2, cx + dx_wrap + ox + rx, cy + oy + ry + 2], fill=col_sh)
        # Main body
        for ox, oy, rx, ry in puffs:
            draw.ellipse([cx + dx_wrap + ox - rx, cy + oy - ry, cx + dx_wrap + ox + rx, cy + oy + ry], fill=col_body)
        # Highlight upper crown
        for ox, oy, rx, ry in puffs[:3]:
            draw.ellipse([cx + dx_wrap + ox - rx + 2, cy + oy - ry, cx + dx_wrap + ox + rx - 2, cy + oy], fill=col_hi)


def draw_organic_canopy(draw: ImageDraw.ImageDraw, cx: int, top_y: int, w: int, h: int, c_dark, c_mid, c_hi, seed: int):
    rng = random.Random(seed)
    blobs = []
    for _ in range(9):
        bx = cx + rng.randint(-w // 2, w // 2)
        by = top_y + rng.randint(0, max(4, h // 2))
        rx = rng.randint(max(5, w // 4), max(8, w // 2))
        ry = rng.randint(max(4, h // 4), max(7, h // 2))
        blobs.append((bx, by, rx, ry))
    for dx_wrap in (-W, 0, W):
        for bx, by, rx, ry in blobs:
            draw.ellipse([bx + dx_wrap - rx, by - ry + 3, bx + dx_wrap + rx, by + ry + 3], fill=c_dark)
        for bx, by, rx, ry in blobs:
            draw.ellipse([bx + dx_wrap - rx, by - ry, bx + dx_wrap + rx, by + ry], fill=c_mid)
        for bx, by, rx, ry in blobs[:5]:
            draw.ellipse([bx + dx_wrap - rx + 2, by - ry, bx + dx_wrap + rx - 2, by + ry // 3], fill=c_hi)


# ==========================================
# PLAINS BIOME
# ==========================================

def make_sky_plains() -> Image.Image:
    img = ordered_dither_gradient(W, H, [
        (0.0, (16, 26, 68)),
        (0.32, (38, 78, 142)),
        (0.66, (108, 174, 218)),
        (0.88, (226, 178, 134)),
        (1.0, (246, 148, 108)),
    ])
    def overlay(d, _o):
        rng = random.Random(101)
        for _ in range(42):
            sx, sy = rng.randint(0, W - 1), rng.randint(4, 82)
            d.point((sx, sy), fill=(235, 248, 255, rng.randint(60, 170)))
        # Subtle glowing rift moon top-left
        mx, my = 96, 52
        d.ellipse([mx - 14, my - 14, mx + 14, my + 14], fill=(95, 230, 255, 40))
        d.arc([mx - 19, my - 6, mx + 19, my + 8], 185, 355, fill=(140, 245, 255, 85), width=2)
        # Warm sun glow
        cx, cy = 368, 78
        for r, a, col in [(42, 26, (255, 200, 120)), (28, 56, (255, 224, 150)), (16, 140, (255, 242, 185)), (10, 255, (255, 252, 220))]:
            d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(col[0], col[1], col[2], a))
        draw_pixel_cloud(d, 72, 66, 1.3, (236, 232, 242, 150), (255, 252, 248, 195), (176, 168, 204, 135))
        draw_pixel_cloud(d, 228, 48, 1.5, (242, 238, 246, 165), (255, 254, 250, 210), (186, 180, 212, 145))
        draw_pixel_cloud(d, 412, 92, 1.1, (246, 226, 224, 130), (255, 244, 232, 170), (195, 166, 182, 125))
    return composite_glow(img, overlay)


def make_mountains_plains() -> Image.Image:
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = img.load()

    far_harm = [(2, 26, 0.2), (3, 17, 1.4), (5, 9, 2.7), (9, 3, 0.8)]
    near_harm = [(2, 20, 1.1), (4, 14, 0.3), (7, 6, 2.1)]

    far_h = [int(134 - abs(periodic_fbm(x, W, far_harm))) for x in range(W)]
    near_h = [int(164 - abs(periodic_fbm(x, W, near_harm))) for x in range(W)]

    for x in range(W):
        fh = far_h[x]
        fslope = far_h[(x + 4) % W] - far_h[(x - 4) % W]
        # Asymmetric diagonal geological ridge seam instead of vertical stripes
        for y in range(fh, H):
            dy = y - fh
            ridge_x = (x + dy // 2) % W
            alt_slope = far_h[(ridge_x + 4) % W] - far_h[(ridge_x - 4) % W]
            is_lit = (fslope <= 0) if dy < 16 else (alt_slope <= 0)
            if dy < 10 and fh < 114:
                px[x, y] = (218, 232, 250, 230) if is_lit else (154, 178, 218, 230)
            else:
                px[x, y] = (82, 102, 152, 238) if is_lit else (56, 72, 118, 238)

        nh = near_h[x]
        nslope = near_h[(x + 4) % W] - near_h[(x - 4) % W]
        for y in range(nh, H):
            dy = y - nh
            t = min(1.0, dy / 80.0)
            ridge_x = (x + (dy * 2) // 3) % W
            alt_slope = near_h[(ridge_x + 4) % W] - near_h[(ridge_x - 4) % W]
            is_lit = (nslope <= 0) if dy < 14 else (alt_slope <= 0)
            if dy <= 1:
                px[x, y] = (140, 176, 224, 255) if nslope <= 0 else (68, 88, 134, 255)
            elif dy < 9 and nh < 142:
                px[x, y] = (204, 228, 250, 255) if is_lit else (128, 156, 200, 255)
            else:
                lit = lerp_color((74, 94, 142, 255), (40, 52, 90, 255), t)
                shd = lerp_color((44, 58, 98, 255), (26, 36, 66, 255), t)
                px[x, y] = lit if is_lit else shd

    def mist_fn(d, _o):
        for y in range(195, 270):
            a = int(68 * ((y - 195) / 75.0))
            d.line([(0, y), (W - 1, y)], fill=(195, 218, 242, a))
    return composite_glow(img, mist_fn)


def make_hills_plains() -> Image.Image:
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = img.load()
    back_harm = [(2, 12, 0.3), (3, 7, 1.8), (6, 3, 0.7)]
    front_harm = [(1, 10, 1.2), (3, 9, 0.1), (5, 4, 2.3)]
    back_y = [int(188 - periodic_fbm(x, W, back_harm)) for x in range(W)]
    front_y = [int(206 - periodic_fbm(x, W, front_harm)) for x in range(W)]

    for x in range(W):
        for y in range(back_y[x], H):
            t = min(1.0, (y - back_y[x]) / 45.0)
            px[x, y] = lerp_color((48, 124, 78, 255), (32, 86, 56, 255), t)
    d = ImageDraw.Draw(img, "RGBA")
    # Background oaks/scrub clumps (wrapped mod W)
    for cx, seed in [(48, 11), (138, 22), (244, 33), (350, 44), (432, 55)]:
        ty = back_y[cx % W]
        for dxw in (-W, 0, W):
            draw_organic_canopy(d, cx + dxw, ty - 14, 34, 22, (28, 82, 52, 255), (42, 116, 68, 255), (68, 152, 86, 255), seed)

    # Foreground rolling meadow & organic boulder + tree silhouettes
    for x in range(W):
        fy = front_y[x]
        for y in range(fy, H):
            dy = y - fy
            if dy < 2:
                px[x, y] = (104, 198, 98, 255)
            elif dy < 6:
                px[x, y] = (58, 152, 74, 255)
            else:
                px[x, y] = lerp_color((36, 108, 60, 255), (22, 68, 42, 255), min(1.0, dy / 50.0))

    # Twisted foreground trees & boulders (wrapped mod W)
    for tx, th, seed in [(86, 32, 71), (204, 26, 72), (312, 34, 73), (446, 28, 74)]:
        gy = front_y[tx % W]
        for dxw in (-W, 0, W):
            d.rectangle([tx + dxw - 3, gy - th // 2, tx + dxw + 2, gy + 2], fill=(64, 42, 30, 255))
            d.rectangle([tx + dxw - 2, gy - th // 2, tx + dxw - 1, gy + 1], fill=(96, 66, 44, 255))
            draw_organic_canopy(d, tx + dxw, gy - th, 36, 22, (24, 76, 44, 255), (44, 128, 66, 255), (86, 182, 88, 255), seed)
    rng = random.Random(204)
    for _ in range(44):
        gx = rng.randint(0, W - 1)
        gy = front_y[gx]
        d.line([(gx, gy), (gx - 1, gy - rng.randint(2, 4))], fill=(92, 188, 92, 255))
        if rng.random() < 0.25:
            col = rng.choice([(255, 225, 95, 255), (120, 240, 255, 255)])
            d.point((gx, gy - 2), fill=col)
    return img


# ==========================================
# JUNGLE BIOME
# ==========================================

def make_sky_jungle() -> Image.Image:
    img = ordered_dither_gradient(W, H, [
        (0.0, (10, 38, 34)),
        (0.42, (22, 82, 64)),
        (0.78, (56, 144, 102)),
        (1.0, (124, 198, 140)),
    ])
    def beams(d, _o):
        for rx in [32, 148, 280, 398]:
            d.polygon([(rx, 0), (rx + 24, 0), (rx + 96, H), (rx + 46, H)], fill=(195, 255, 210, 26))
            d.polygon([(rx + 8, 0), (rx + 16, 0), (rx + 74, H), (rx + 56, H)], fill=(230, 255, 220, 18))
    return composite_glow(img, beams)


def make_canopy_jungle() -> Image.Image:
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    # Ancient moss-covered stepped ruin temple centered around x=230
    tx, base_y = 228, 225
    tiers = [(126, 26), (92, 24), (62, 22), (38, 18)]
    cy = base_y
    for tw, th in tiers:
        cy -= th
        d.rectangle([tx - tw // 2, cy, tx + tw // 2, cy + th], fill=(28, 72, 60, 235))
        d.rectangle([tx - tw // 2, cy, tx - tw // 2 + 8, cy + th], fill=(42, 104, 82, 235))
        d.line([(tx - tw // 2, cy), (tx + tw // 2, cy)], fill=(68, 146, 98, 240), width=2)
    # Stone archway top
    d.rectangle([tx - 10, cy + 4, tx + 10, cy + 18], fill=(14, 38, 32, 245))
    d.point((tx, cy + 9), fill=(95, 255, 225, 220))
    # Distant misty cliff waterfall on right side
    d.rectangle([386, 118, 404, 235], fill=(125, 228, 214, 120))
    for wy in range(122, 232, 6):
        d.line([(390, wy), (400, wy + 3)], fill=(215, 255, 248, 175), width=1)
    # Layered misty mid-ground canopies (no stray polygons!)
    for cx, ty, cw, seed in [(52, 86, 86, 31), (154, 102, 74, 32), (336, 92, 92, 33), (440, 88, 78, 34)]:
        for dxw in (-W, 0, W):
            d.rectangle([cx + dxw - 9, ty + 20, cx + dxw + 9, 270], fill=(16, 56, 42, 225))
        draw_organic_canopy(d, cx, ty, cw, 44, (18, 66, 48, 235), (28, 94, 66, 235), (46, 128, 84, 235), seed)
    return img


def make_trees_jungle() -> Image.Image:
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    rng = random.Random(305)
    for idx, tx in enumerate([26, 116, 212, 304, 396]):
        top_y = 26 + (idx % 2) * 18
        for dxw in (-W, 0, W):
            # Gnarled trunk + roots
            d.polygon([(tx + dxw - 11, H), (tx + dxw - 6, top_y), (tx + dxw + 7, top_y), (tx + dxw + 13, H)], fill=(14, 42, 28, 255))
            d.rectangle([tx + dxw - 4, top_y, tx + dxw - 1, H], fill=(28, 72, 46, 255))
            # Hanging curved vines
            for vx in [tx - 16, tx + 15]:
                vy_end = top_y + rng.randint(55, 110)
                for y in range(top_y + 18, vy_end):
                    ox = int(2.5 * math.sin((y - top_y) * 0.08))
                    d.point((vx + dxw + ox, y), fill=(48, 138, 72, 240))
            draw_organic_canopy(d, tx + dxw, top_y - 12, 76, 46, (16, 58, 34, 255), (26, 88, 50, 255), (52, 138, 72, 255), 310 + idx)

    # Undergrowth ridge + broad fern fronds
    pts = [(x, int(210 - periodic_fbm(x, W, [(4, 6, 0.2), (9, 4, 1.3)]))) for x in range(W + 1)]
    d.polygon(pts + [(W, H), (0, H)], fill=(14, 52, 30, 255))
    for fx in range(10, W, 24):
        fy = pts[fx][1]
        for angle in (-0.6, 0.0, 0.6):
            ex, ey = int(fx + math.sin(angle) * 12), int(fy - math.cos(angle) * 10)
            d.line([(fx, fy), (ex, ey)], fill=(54, 152, 76, 255), width=2)
    def fireflies(df, _o):
        for _ in range(32):
            gx, gy = rng.randint(6, W - 6), rng.randint(65, 228)
            df.ellipse([gx - 2, gy - 2, gx + 2, gy + 2], fill=(130, 255, 200, 60))
            df.point((gx, gy), fill=(210, 255, 220, 240))
    return composite_glow(img, fireflies)


# ==========================================
# FROZEN BIOME
# ==========================================

def make_sky_ice() -> Image.Image:
    img = ordered_dither_gradient(W, H, [
        (0.0, (8, 16, 42)),
        (0.42, (18, 48, 96)),
        (0.78, (54, 118, 174)),
        (1.0, (148, 212, 238)),
    ])
    def aurora(d, _o):
        # Vertical shimmering pixel aurora curtains
        for x in range(W):
            a = x / float(W) * math.tau
            base_y = int(42 + 16 * math.sin(a * 2.0 + 0.4) + 7 * math.cos(a * 5.0))
            curtain_h = int(28 + 14 * abs(math.sin(a * 3.0 + 1.1)))
            if (x % 2) == 0:
                d.line([(x, base_y), (x, base_y + curtain_h)], fill=(70, 245, 205, 36))
            d.line([(x, base_y + curtain_h // 2), (x, base_y + curtain_h)], fill=(115, 200, 255, 28))
        rng = random.Random(404)
        for i in range(65):
            sx, sy = rng.randint(2, W - 3), rng.randint(4, 128)
            al = rng.randint(100, 245)
            d.point((sx, sy), fill=(235, 250, 255, al))
            if i % 9 == 0:
                for ox, oy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                    d.point((sx + ox, sy + oy), fill=(170, 235, 255, al // 2))
    return composite_glow(img, aurora)


def make_peaks_ice() -> Image.Image:
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = img.load()
    harm = [(2, 34, 0.5), (3, 22, 2.0), (5, 11, 0.9), (9, 5, 1.5)]
    heights = [int(156 - abs(periodic_fbm(x, W, harm))) for x in range(W)]
    for x in range(W):
        top = heights[x]
        slope = heights[(x + 4) % W] - heights[(x - 4) % W]
        for y in range(top, H):
            dy = y - top
            t = min(1.0, dy / 90.0)
            ridge_x = (x + dy // 2) % W
            alt_slope = heights[(ridge_x + 4) % W] - heights[(ridge_x - 4) % W]
            is_lit = (slope <= 0) if dy < 18 else (alt_slope <= 0)
            if dy <= 1:
                px[x, y] = (232, 250, 255, 255) if slope <= 0 else (126, 178, 224, 255)
            elif is_lit:
                px[x, y] = lerp_color((152, 216, 248, 250), (88, 146, 198, 245), t)
            else:
                px[x, y] = lerp_color((72, 122, 176, 250), (42, 78, 126, 245), t)
    def snow_mist(d, _o):
        for y in range(185, 270):
            d.line([(0, y), (W - 1, y)], fill=(195, 235, 255, int(72 * (y - 185) / 85.0)))
    return composite_glow(img, snow_mist)


def make_ruins_ice() -> Image.Image:
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = img.load()
    snow_y = [int(204 - periodic_fbm(x, W, [(2, 9, 0.3), (5, 5, 1.9)])) for x in range(W)]
    for x in range(W):
        sy = snow_y[x]
        for y in range(sy, H):
            dy = y - sy
            px[x, y] = (224, 246, 255, 255) if dy < 3 else lerp_color((146, 206, 238, 255), (86, 144, 192, 255), min(1.0, dy / 45.0))
    d = ImageDraw.Draw(img, "RGBA")
    # Frosted pines & carved crystalline obsidian-ice monoliths
    for cx, h in [(52, 68), (168, 86), (296, 74), (414, 80)]:
        top = 208 - h
        d.polygon([(cx - 11, 216), (cx - 8, top + 8), (cx, top), (cx + 8, top + 8), (cx + 11, 216)], fill=(58, 96, 140, 255))
        d.polygon([(cx - 11, 216), (cx - 8, top + 8), (cx, top), (cx, 216)], fill=(104, 162, 208, 255))
        # Snow cap & glowing rift runes
        d.polygon([(cx - 8, top + 8), (cx, top), (cx + 8, top + 8)], fill=(224, 248, 255, 255))
        for ry in [top + 22, top + 34, top + 46]:
            d.rectangle([cx - 2, ry, cx + 1, ry + 5], fill=(90, 248, 255, 235))
    for px_pine in [106, 236, 354]:
        gy = snow_y[px_pine]
        for tier in range(3):
            w = 14 - tier * 3
            ty = gy - 10 - tier * 8
            d.polygon([(px_pine, ty - 10), (px_pine - w, ty), (px_pine + w, ty)], fill=(38, 78, 108, 255))
            d.line([(px_pine, ty - 10), (px_pine - w // 2, ty - 5)], fill=(215, 245, 255, 255), width=2)
    return img


# ==========================================
# VOLCANIC BIOME
# ==========================================

def make_sky_volcano() -> Image.Image:
    img = ordered_dither_gradient(W, H, [
        (0.0, (20, 10, 24)),
        (0.38, (64, 18, 30)),
        (0.74, (148, 42, 24)),
        (1.0, (242, 112, 34)),
    ])
    def embers(d, _o):
        # Soft vertical horizon glow (no hard horizontal seam) & rising embers
        for hy in range(145, H):
            alpha = int(38 * (((hy - 145) / float(H - 145)) ** 1.6))
            d.line([(0, hy), (W - 1, hy)], fill=(255, 110, 28, alpha))
        rng = random.Random(505)
        for _ in range(58):
            ex, ey = rng.randint(4, W - 5), rng.randint(24, H - 15)
            col = rng.choice([(255, 224, 96, 210), (255, 130, 42, 185)])
            d.point((ex, ey), fill=col)
            if ey > 120:
                d.point((ex + 1, ey + 2), fill=(255, 95, 24, 90))
    return composite_glow(img, embers)


def make_mountains_volcano() -> Image.Image:
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = img.load()
    harm = [(2, 32, 0.8), (3, 24, 2.2), (6, 11, 0.3), (11, 4, 1.7)]
    heights = [int(150 - abs(periodic_fbm(x, W, harm))) for x in range(W)]
    for x in range(W):
        top = heights[x]
        slope = heights[(x + 4) % W] - heights[(x - 4) % W]
        for y in range(top, H):
            dy = y - top
            t = min(1.0, dy / 95.0)
            ridge_x = (x + dy // 2) % W
            alt_slope = heights[(ridge_x + 4) % W] - heights[(ridge_x - 4) % W]
            is_lit = (slope <= 0) if dy < 16 else (alt_slope <= 0)
            if dy <= 1:
                px[x, y] = (158, 62, 42, 255) if slope <= 0 else (64, 26, 32, 255)
            elif is_lit:
                px[x, y] = lerp_color((68, 30, 36, 255), (34, 16, 22, 255), t)
            else:
                px[x, y] = lerp_color((42, 18, 24, 255), (22, 10, 16, 255), t)

    def lava_plumes(d, _o):
        for target_x in [86, 252, 410]:
            best_x = min(range(target_x - 24, target_x + 24), key=lambda k: heights[k % W]) % W
            top_y = heights[best_x]
            # Glowing jagged crater rim & winding magma veins
            d.rectangle([best_x - 7, top_y, best_x + 7, top_y + 3], fill=(255, 165, 42, 255))
            d.line([(best_x - 2, top_y + 3), (best_x - 7, top_y + 22), (best_x - 14, top_y + 44), (best_x - 19, 228)], fill=(255, 92, 20, 235), width=2)
            d.line([(best_x + 3, top_y + 3), (best_x + 8, top_y + 28), (best_x + 15, top_y + 52), (best_x + 17, 228)], fill=(255, 172, 48, 215), width=2)
            # Soft clustered drifting ash plumes (subtle, cohesive smoke)
            for k in range(1, 4):
                sy = top_y - 6 - k * 11
                sx = best_x + k * 5
                rx, ry = 10 + k * 5, 5 + k * 2
                d.ellipse([sx - rx, sy - ry, sx + rx, sy + ry], fill=(64, 34, 42, 58 - k * 10))
                d.ellipse([sx - rx + 4, sy - ry + 2, sx + rx - 2, sy + ry], fill=(165, 62, 34, 24))
    return composite_glow(img, lava_plumes)


def make_caves_volcano() -> Image.Image:
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = img.load()
    heights = [int(206 - abs(periodic_fbm(x, W, [(4, 14, 0.4), (7, 8, 1.7), (13, 3, 0.9)]))) for x in range(W)]
    for x in range(W):
        top = heights[x]
        slope = heights[(x + 3) % W] - heights[(x - 3) % W]
        for y in range(top, H):
            dy = y - top
            if dy <= 2:
                px[x, y] = (196, 78, 36, 255) if slope <= 0 else (76, 28, 24, 255)
            else:
                px[x, y] = lerp_color((44, 18, 22, 255), (22, 8, 12, 255), min(1.0, dy / 40.0))
    d = ImageDraw.Draw(img, "RGBA")
    for sx in [74, 218, 344, 444]:
        by = heights[sx]
        for dxw in (-W, 0, W):
            d.polygon([(sx + dxw - 8, by + 10), (sx + dxw, by - 22), (sx + dxw + 8, by + 10)], fill=(28, 12, 16, 255))
            d.line([(sx + dxw - 7, by + 8), (sx + dxw, by - 22)], fill=(224, 88, 36, 255), width=2)
    return img


def make_ground_tile() -> Image.Image:
    # 16x16 strictly seamless pixel-art ground block (wraps identically on x=0..15)
    img = Image.new("RGBA", (16, 16), (92, 58, 36, 255))
    d = ImageDraw.Draw(img, "RGBA")
    # Crisp topsoil highlight + beveled grass/moss rim + soil sublayers
    d.line([(0, 0), (15, 0)], fill=(198, 224, 134, 255))
    d.line([(0, 1), (15, 1)], fill=(116, 178, 86, 255))
    d.line([(0, 2), (15, 2)], fill=(72, 134, 62, 255))
    d.line([(0, 3), (15, 3)], fill=(54, 88, 42, 255))
    d.rectangle([0, 4, 15, 9], fill=(116, 74, 46, 255))
    d.rectangle([0, 10, 15, 15], fill=(86, 52, 32, 255))
    # Interior pebbles safely inset from x=0 and x=15 so edge_diff == 0
    d.rectangle([3, 6, 6, 7], fill=(144, 96, 62, 255))
    d.rectangle([10, 5, 12, 7], fill=(78, 46, 28, 255))
    d.rectangle([5, 11, 8, 13], fill=(64, 38, 22, 255))
    d.rectangle([11, 12, 13, 14], fill=(134, 88, 56, 255))
    return img


# ==========================================
# PROPS, COLLECTIBLES & HAZARDS
# ==========================================

def make_lava_pit() -> Image.Image:
    # 96x16 (2 frames x 48x16) bubbling magma hazard
    sheet = Image.new("RGBA", (96, 16), (0, 0, 0, 0))
    for frame_idx in range(2):
        img = Image.new("RGBA", (48, 16), (0, 0, 0, 0))
        d = ImageDraw.Draw(img, "RGBA")
        d.rectangle([3, 4, 44, 15], fill=(168, 32, 12, 255))
        d.rectangle([4, 5, 43, 13], fill=(238, 86, 18, 255))
        d.rectangle([5, 5, 42, 9], fill=(255, 162, 34, 255))
        shift = frame_idx * 4
        for bx, by, w in [(8 + shift, 6, 6), (20 - shift // 2, 5, 8), (32 + shift // 2, 6, 5)]:
            d.rectangle([bx, by, bx + w, by + 2], fill=(255, 238, 118, 255))
        if frame_idx == 0:
            d.ellipse([12, 1, 17, 6], fill=(255, 198, 48, 255))
            d.point((14, 2), fill=(255, 252, 196, 255))
            d.ellipse([32, 3, 35, 6], fill=(255, 174, 38, 255))
        else:
            d.ellipse([13, 3, 16, 6], fill=(255, 174, 38, 255))
            d.ellipse([29, 0, 35, 6], fill=(255, 206, 54, 255))
            d.point((31, 2), fill=(255, 252, 196, 255))
        d.polygon([(0, 15), (2, 4), (7, 4), (9, 15)], fill=(44, 22, 26, 255))
        d.polygon([(39, 15), (41, 4), (46, 4), (47, 15)], fill=(44, 22, 26, 255))
        d.line([(2, 4), (6, 4)], fill=(120, 52, 38, 255))
        d.line([(41, 4), (45, 4)], fill=(120, 52, 38, 255))
        d.rectangle([0, 14, 47, 15], fill=(28, 12, 16, 255))
        sheet.paste(img, (frame_idx * 48, 0))
    return sheet


def make_pterodactyl() -> Image.Image:
    # 64x24 (2 frames x 32x24): wing UP + wing DOWN swoop
    sheet = Image.new("RGBA", (64, 24), (0, 0, 0, 0))
    outline = (30, 12, 18, 255)
    body = (212, 62, 54, 255)
    shade = (146, 36, 38, 255)
    wing_hi = (244, 126, 74, 255)
    beak = (246, 198, 72, 255)
    for fi in range(2):
        img = Image.new("RGBA", (32, 24), (0, 0, 0, 0))
        d = ImageDraw.Draw(img, "RGBA")
        if fi == 0:
            # Wing UP
            d.polygon([(12, 12), (18, 1), (28, 3), (22, 13)], fill=outline)
            d.polygon([(13, 11), (18, 3), (26, 4), (21, 12)], fill=body)
            d.line([(18, 3), (25, 4)], fill=wing_hi, width=2)
        else:
            # Wing DOWN swoop
            d.polygon([(12, 13), (18, 23), (28, 20), (22, 13)], fill=outline)
            d.polygon([(13, 13), (18, 21), (26, 19), (21, 13)], fill=shade)
            d.line([(18, 21), (25, 19)], fill=body, width=1)
        d.ellipse([10, 10, 24, 18], fill=outline)
        d.ellipse([11, 11, 23, 17], fill=body)
        d.polygon([(22, 13), (30, 11), (25, 16)], fill=outline)
        d.polygon([(22, 14), (29, 12), (24, 15)], fill=shade)
        head_y = 0 if fi == 0 else 1
        d.polygon([(6, 11 + head_y), (14, 7 + head_y), (18, 12 + head_y), (12, 15 + head_y)], fill=outline)
        d.polygon([(7, 11 + head_y), (14, 8 + head_y), (17, 12 + head_y), (12, 14 + head_y)], fill=body)
        d.polygon([(1, 12 + head_y), (9, 10 + head_y), (9, 14 + head_y)], fill=outline)
        d.polygon([(2, 12 + head_y), (9, 11 + head_y), (9, 13 + head_y)], fill=beak)
        d.point((10, 11 + head_y), fill=(255, 255, 120, 255))
        sheet.paste(img, (fi * 32, 0))
    return sheet


def make_crawler() -> Image.Image:
    # 48x16 (2 frames x 24x16): alternating scurrying legs & bobbing spikes
    sheet = Image.new("RGBA", (48, 16), (0, 0, 0, 0))
    for fi in range(2):
        img = Image.new("RGBA", (24, 16), (0, 0, 0, 0))
        d = ImageDraw.Draw(img, "RGBA")
        bob = 0 if fi == 0 else -1
        d.pieslice([2, 3 + bob, 22, 18 + bob], 180, 360, fill=(26, 22, 34, 255))
        d.pieslice([3, 4 + bob, 21, 17 + bob], 180, 360, fill=(78, 72, 98, 255))
        d.pieslice([5, 5 + bob, 19, 15 + bob], 190, 350, fill=(116, 108, 144, 255))
        for sx in [7, 12, 17]:
            d.polygon([(sx - 2, 5 + bob), (sx, 1 + bob), (sx + 2, 5 + bob)], fill=(255, 112, 54, 255))
        d.rectangle([5, 10 + bob, 7, 11 + bob], fill=(255, 68, 68, 255))
        legs = [5, 10, 15, 19] if fi == 0 else [4, 11, 14, 20]
        for idx, lx in enumerate(legs):
            ly = 13 if (idx + fi) % 2 == 0 else 12
            d.rectangle([lx, ly, lx + 1, 15], fill=(240, 185, 90, 255))
        sheet.paste(img, (fi * 24, 0))
    return sheet


def make_gem() -> Image.Image:
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    d.polygon([(8, 1), (14, 6), (8, 15), (2, 6)], fill=(16, 36, 56, 255))
    d.polygon([(8, 2), (13, 6), (8, 14), (3, 6)], fill=(36, 210, 255, 255))
    d.polygon([(8, 2), (10, 6), (8, 14), (5, 6)], fill=(120, 245, 255, 255))
    d.polygon([(8, 2), (5, 6), (3, 6)], fill=(235, 255, 255, 255))
    d.polygon([(8, 14), (13, 6), (10, 6)], fill=(18, 138, 215, 255))
    d.line([(3, 6), (13, 6)], fill=(205, 252, 255, 255), width=1)
    return img


def make_storm_cloud() -> Image.Image:
    # 72x24 (2 frames x 36x24): alternating crackling electric bolt
    sheet = Image.new("RGBA", (72, 24), (0, 0, 0, 0))
    for fi in range(2):
        img = Image.new("RGBA", (36, 24), (0, 0, 0, 0))
        d = ImageDraw.Draw(img, "RGBA")
        c_dark = (42, 46, 72, 255) if fi == 0 else (56, 62, 92, 255)
        c_mid = (58, 66, 102, 255) if fi == 0 else (76, 86, 128, 255)
        d.ellipse([2, 6, 16, 17], fill=c_dark)
        d.ellipse([10, 2, 26, 16], fill=c_mid)
        d.ellipse([20, 6, 34, 17], fill=c_dark)
        d.ellipse([12, 4, 22, 12], fill=(108, 122, 168, 255))
        if fi == 0:
            d.polygon([(18, 14), (13, 19), (17, 19), (14, 23), (22, 17), (18, 17)], fill=(255, 238, 86, 255))
        else:
            d.polygon([(20, 14), (24, 18), (20, 18), (23, 23), (15, 17), (19, 17)], fill=(140, 248, 255, 255))
            d.point((12, 16), fill=(255, 244, 120, 255))
        sheet.paste(img, (fi * 36, 0))
    return sheet


def make_wooden_barrier() -> Image.Image:
    # 16x28 dedicated spiked timber barricade with iron bands
    img = Image.new("RGBA", (16, 28), (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    outline = (28, 16, 10, 255)
    wood_dark = (94, 54, 28, 255)
    wood_mid = (142, 86, 44, 255)
    wood_hi = (182, 118, 64, 255)
    iron = (78, 88, 106, 255)
    iron_hi = (152, 170, 196, 255)
    # Twin vertical pointed stakes
    for sx in (2, 9):
        d.polygon([(sx, 27), (sx, 5), (sx + 2, 1), (sx + 5, 5), (sx + 5, 27)], fill=outline)
        d.polygon([(sx + 1, 26), (sx + 1, 6), (sx + 2, 2), (sx + 4, 6), (sx + 4, 26)], fill=wood_mid)
        d.line([(sx + 2, 3), (sx + 2, 25)], fill=wood_hi, width=1)
        d.line([(sx + 4, 6), (sx + 4, 25)], fill=wood_dark, width=1)
    # Iron cross-bars + rivets
    for by in (10, 20):
        d.rectangle([1, by, 14, by + 3], fill=outline)
        d.rectangle([2, by + 1, 13, by + 2], fill=iron)
        d.point((4, by + 1), fill=iron_hi)
        d.point((11, by + 1), fill=iron_hi)
    return img


def make_subground_strata() -> Image.Image:
    # 64x64 seamless subterranean sedimentary rock + fossil + quartz vein tile (tinted per biome)
    img = Image.new("RGBA", (64, 64), (176, 178, 186, 255))
    d = ImageDraw.Draw(img, "RGBA")
    # Stratified horizontal bands (neutral grayscale/stone so biome modulate tints cleanly)
    bands = [
        (0, 12, (168, 172, 180, 255)),
        (12, 26, (148, 152, 162, 255)),
        (26, 44, (132, 136, 148, 255)),
        (44, 64, (118, 122, 134, 255)),
    ]
    for y0, y1, col in bands:
        d.rectangle([0, y0, 63, y1], fill=col)
        d.line([(0, y0), (63, y0)], fill=(min(255, col[0] + 22), min(255, col[1] + 22), min(255, col[2] + 24), 255))
    # Chiseled basalt brick seams & pebbles (seamlessly wrapped mod 64)
    pebbles = [(6, 5, 7, 3), (28, 8, 9, 3), (48, 4, 8, 3), (14, 17, 10, 4), (40, 20, 12, 4),
               (4, 32, 11, 5), (26, 36, 13, 4), (52, 31, 9, 4), (18, 50, 14, 5), (44, 53, 12, 4)]
    for px, py, pw, ph in pebbles:
        for ox in (0, -64, 64):
            rx = px + ox
            if rx + pw >= 0 and rx < 64:
                d.rounded_rectangle([rx, py, rx + pw, py + ph], radius=1, fill=(104, 108, 120, 255))
                d.line([(rx + 1, py), (rx + pw - 1, py)], fill=(196, 200, 210, 255))
    # Tiny glowing crystal specks + buried ammonite shell accent
    for sx, sy in [(11, 14), (35, 29), (56, 48), (22, 42)]:
        d.rectangle([sx, sy, sx + 1, sy + 1], fill=(224, 232, 244, 255))
    d.arc([30, 46, 39, 55], 0, 290, fill=(210, 214, 224, 255), width=1)
    d.arc([32, 48, 37, 53], 20, 260, fill=(156, 160, 172, 255), width=1)
    return img


def make_overhang_arch() -> Image.Image:
    # 32x240 carved ancient basalt ruin pillar & stalactite archway overhang
    img = Image.new("RGBA", (32, 240), (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    outline = (22, 24, 34, 255)
    stone_dark = (52, 58, 76, 255)
    stone_mid = (82, 92, 116, 255)
    stone_hi = (118, 130, 160, 255)
    moss = (64, 142, 78, 255)
    rune = (72, 236, 255, 255)
    # Main stone column narrowing into pointed stalactite lip at y=224..239
    d.rectangle([2, 0, 29, 224], fill=outline)
    d.rectangle([4, 0, 27, 222], fill=stone_mid)
    d.rectangle([4, 0, 7, 222], fill=stone_hi)
    d.rectangle([24, 0, 27, 222], fill=stone_dark)
    # Carved horizontal masonry blocks & beveled shadow seams every 24px
    for y in range(12, 220, 24):
        d.line([(4, y), (27, y)], fill=outline, width=2)
        d.line([(4, y + 2), (27, y + 2)], fill=stone_hi, width=1)
        if y >= 150:
            # Subtle ancient rift glyph near bottom eye-level where player slides under!
            d.rectangle([13, y + 7, 18, y + 15], fill=stone_dark)
            d.point((15, y + 9), fill=rune)
            d.point((16, y + 11), fill=rune)
            d.point((15, y + 13), fill=rune)
    # Hanging moss accents on side
    for my in (96, 144, 188):
        d.polygon([(3, my), (7, my), (5, my + 8)], fill=moss)
    # Bottom stalactite teeth & carved warning band (y=218..239)
    d.rectangle([2, 214, 29, 222], fill=stone_dark, outline=outline)
    d.line([(6, 218), (25, 218)], fill=rune, width=2)
    for tx in (4, 12, 20):
        d.polygon([(tx, 222), (tx + 8, 222), (tx + 4, 239)], fill=outline)
        d.polygon([(tx + 1, 222), (tx + 7, 222), (tx + 4, 237)], fill=stone_hi if tx == 12 else stone_mid)
    return img


def make_skill_bone_blade() -> Image.Image:
    # 32x32 gleaming obsidian-ivory primal crescent fang blade
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    outline = (24, 18, 22, 255)
    ivory_hi = (255, 248, 228, 255)
    ivory_mid = (228, 210, 178, 255)
    ivory_shade = (168, 144, 114, 255)
    hilt = (196, 62, 48, 255)
    gem = (64, 238, 255, 255)
    # Sweeping curved fang blade
    blade_outer = [(9, 24), (14, 16), (22, 7), (29, 3), (25, 13), (17, 22), (11, 26)]
    d.polygon(blade_outer, fill=outline)
    d.polygon([(11, 23), (15, 16), (22, 8), (27, 5), (23, 13), (16, 21)], fill=ivory_mid)
    d.line([(13, 21), (22, 9), (27, 5)], fill=ivory_hi, width=2)
    d.line([(16, 22), (24, 13)], fill=ivory_shade, width=1)
    # Crossguard + leather wrap handle + rift jewel
    d.line([(7, 19), (15, 27)], fill=outline, width=4)
    d.line([(8, 20), (14, 26)], fill=ivory_shade, width=2)
    d.line([(4, 28), (10, 22)], fill=outline, width=4)
    d.line([(5, 27), (9, 23)], fill=hilt, width=2)
    d.ellipse([9, 20, 13, 24], fill=gem, outline=outline)
    return img


def make_skin_icons() -> None:
    for skin_id, pal in SKIN_PALETTES.items():
        # 48x48 crisp crystal medallion bust matching hero spritesheet + app icon
        img = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
        d = ImageDraw.Draw(img, "RGBA")
        # Beveled crystal frame background
        d.rounded_rectangle([2, 2, 45, 45], radius=8, fill=(14, 20, 38, 255), outline=pal["crest"], width=2)
        d.rounded_rectangle([5, 5, 42, 42], radius=6, fill=(22, 32, 56, 255))
        # Subtle elemental radial glow behind bust
        d.ellipse([9, 9, 38, 38], fill=(pal["crest"][0], pal["crest"][1], pal["crest"][2], 42))
        # Render crisp 32x32 Idle hero centered & cropped into medallion at 1.4x pixel crispness
        pose = draw_dino_pose(pal, body_off=(0, 1), head_off=(0, 1), far_leg=(-2, 5), near_leg=(2, 5), jaw_open=True)
        bust = pose.crop((2, 1, 28, 27)).resize((36, 36), resample=Image.NEAREST)
        img.paste(bust, (6, 7), bust)
        out_path = os.path.join(OUT_DIR, f"skin_icon_{skin_id}.png")
        img.save(out_path)
        print(f"Generated unified skin portrait: {out_path} ({img.size})")


def make_cactus_low() -> Image.Image:
    img = Image.new("RGBA", (16, 24), (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    d.rectangle([5, 2, 11, 23], fill=(18, 44, 24, 255))
    d.rectangle([6, 3, 10, 23], fill=(48, 152, 64, 255))
    d.rectangle([7, 3, 8, 23], fill=(96, 206, 98, 255))
    d.rectangle([1, 8, 6, 14], fill=(18, 44, 24, 255))
    d.rectangle([2, 9, 6, 13], fill=(52, 162, 68, 255))
    d.rectangle([10, 6, 15, 12], fill=(18, 44, 24, 255))
    d.rectangle([10, 7, 14, 11], fill=(42, 136, 56, 255))
    for sy in [5, 11, 17]:
        d.point((5, sy), fill=(225, 250, 190, 255))
        d.point((10, sy + 1), fill=(225, 250, 190, 255))
    return img


# ==========================================
# CRISP 27-FRAME RIFTOSAUR SPRITESHEETS (864x32)
# ==========================================

SKIN_PALETTES = {
    "classic": {
        "outline": (18, 22, 34, 255),
        "body": (54, 176, 118, 255),
        "shade": (32, 118, 82, 255),
        "highlight": (110, 224, 156, 255),
        "belly": (228, 232, 178, 255),
        "crest": (44, 235, 255, 255),
        "crest_hi": (196, 255, 255, 255),
        "eye": (255, 224, 72, 255),
    },
    "emerald": {
        "outline": (14, 28, 22, 255),
        "body": (42, 196, 98, 255),
        "shade": (24, 130, 64, 255),
        "highlight": (122, 245, 146, 255),
        "belly": (212, 248, 176, 255),
        "crest": (186, 255, 68, 255),
        "crest_hi": (244, 255, 180, 255),
        "eye": (255, 245, 96, 255),
    },
    "ruby": {
        "outline": (34, 12, 18, 255),
        "body": (218, 58, 68, 255),
        "shade": (148, 32, 46, 255),
        "highlight": (248, 118, 98, 255),
        "belly": (252, 210, 154, 255),
        "crest": (255, 198, 52, 255),
        "crest_hi": (255, 246, 168, 255),
        "eye": (96, 245, 255, 255),
    },
    "cyber": {
        "outline": (14, 14, 30, 255),
        "body": (68, 88, 178, 255),
        "shade": (40, 52, 118, 255),
        "highlight": (118, 148, 236, 255),
        "belly": (132, 228, 246, 255),
        "crest": (255, 64, 214, 255),
        "crest_hi": (255, 192, 246, 255),
        "eye": (72, 255, 255, 255),
    },
    "gold": {
        "outline": (36, 22, 10, 255),
        "body": (238, 182, 42, 255),
        "shade": (176, 116, 22, 255),
        "highlight": (255, 228, 108, 255),
        "belly": (255, 246, 206, 255),
        "crest": (68, 242, 255, 255),
        "crest_hi": (215, 255, 255, 255),
        "eye": (255, 68, 86, 255),
    },
}


def add_pixel_outline(img: Image.Image, outline_col) -> Image.Image:
    w, h = img.size
    src = img.load()
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    dst = out.load()
    for y in range(h):
        for x in range(w):
            if src[x, y][3] > 0:
                dst[x, y] = src[x, y]
            else:
                touching = False
                for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                    if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3] > 180:
                        touching = True
                        break
                if touching:
                    dst[x, y] = outline_col
    return out


def draw_dino_pose(pal: dict, body_off=(0, 0), head_off=(0, 0), lean=0.0,
                   far_leg=(0, 0), near_leg=(0, 0), tail_wag=0, crouch=False,
                   dive=False, hurt=False, jaw_open=False, sparks=False) -> Image.Image:
    f = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(f, "RGBA")
    b = pal["body"]
    sh = pal["shade"]
    hi = pal["highlight"]
    bl = pal["belly"]
    cr = pal["crest"]
    crh = pal["crest_hi"]
    ey = pal["eye"]

    if crouch:
        # Ultra-sleek belly slide pose along bottom y=19..29
        # Tail streaming back
        d.polygon([(1, 23 + tail_wag), (9, 22), (9, 26)], fill=sh)
        d.polygon([(2, 23 + tail_wag), (9, 23), (9, 25)], fill=b)
        # Stretched low torso & belly skid
        d.ellipse([7, 20, 23, 28], fill=b)
        d.rectangle([9, 26, 22, 28], fill=bl)
        d.line([(10, 21), (20, 21)], fill=hi)
        # Spines glowing along back
        for sx in (10, 14, 18):
            d.polygon([(sx, 21), (sx - 2, 17), (sx + 2, 21)], fill=cr)
            d.point((sx - 1, 18), fill=crh)
        # Forward aerodynamic head
        d.rectangle([20, 19, 29, 25], fill=b)
        d.rectangle([21, 19, 28, 21], fill=hi)
        d.rectangle([23, 24, 29, 26], fill=bl)
        d.rectangle([25, 20, 26, 21], fill=ey)
        # Skidding legs tucked back
        d.line([(8, 27), (5, 29)], fill=sh, width=2)
        d.line([(12, 27), (9, 29)], fill=b, width=2)
        out = add_pixel_outline(f, pal["outline"])
        if sparks:
            do = ImageDraw.Draw(out, "RGBA")
            do.line([(0, 28), (5, 28)], fill=(120, 245, 255, 230), width=1)
            do.line([(2, 25), (6, 25)], fill=(255, 255, 255, 210), width=1)
        return out

    if dive:
        # Steep meteor dive pointing down-right
        d.polygon([(4, 7), (12, 11), (10, 14)], fill=sh)
        d.polygon([(10, 10), (22, 17), (18, 24), (8, 16)], fill=b)
        d.line([(12, 11), (21, 17)], fill=hi, width=2)
        d.polygon([(18, 17), (27, 24), (24, 28), (16, 22)], fill=b)
        d.point((22, 21), fill=ey)
        for sx, sy in [(11, 10), (14, 12), (17, 14)]:
            d.polygon([(sx, sy), (sx - 2, sy - 4), (sx + 2, sy - 1)], fill=cr)
        out = add_pixel_outline(f, pal["outline"])
        do = ImageDraw.Draw(out, "RGBA")
        do.line([(3, 3), (8, 8)], fill=(255, 220, 110, 235), width=1)
        do.line([(6, 2), (12, 8)], fill=(120, 245, 255, 220), width=1)
        return out

    bx, by = 14 + body_off[0], 17 + body_off[1]
    hx, hy = 18 + head_off[0] + int(lean * 2), 9 + head_off[1]

    # Far leg (shaded back limb)
    fl_x, fl_y = bx - 1 + far_leg[0], by + 6 + far_leg[1]
    d.line([(bx - 1, by + 3), (fl_x, fl_y)], fill=sh, width=3)
    d.rectangle([fl_x - 1, fl_y, fl_x + 3, fl_y + 1], fill=sh)

    # Tail with dynamic wag
    d.polygon([(bx - 11, by - 1 + tail_wag), (bx - 2, by - 1), (bx - 2, by + 4)], fill=sh)
    d.polygon([(bx - 10, by - 1 + tail_wag), (bx - 2, by), (bx - 2, by + 3)], fill=b)

    # Torso
    d.ellipse([bx - 5, by - 5, bx + 6, by + 6], fill=b)
    d.ellipse([bx - 2, by - 2, bx + 6, by + 5], fill=bl)
    d.arc([bx - 4, by - 5, bx + 4, by + 3], 180, 320, fill=hi, width=1)

    # Tiny fierce arm
    d.line([(bx + 4, by), (bx + 8, by + 2)], fill=b, width=2)
    d.point((bx + 9, by + 2), fill=crh)

    # Dorsal rift crystal spines down neck & back
    for sx, sy in [(hx - 2, hy), (bx - 3, by - 4), (bx - 6, by - 1)]:
        d.polygon([(sx, sy + 1), (sx - 3, sy - 3), (sx + 2, sy - 1)], fill=cr)
        d.point((sx - 2, sy - 2), fill=crh)

    # Expressive Head & Snout
    d.rectangle([hx - 4, hy - 4, hx + 8, hy + 2], fill=b)
    d.rectangle([hx - 3, hy - 4, hx + 7, hy - 3], fill=hi)
    # Lower jaw
    jaw_drop = 2 if jaw_open else 0
    d.rectangle([hx - 2, hy + 2 + jaw_drop, hx + 7, hy + 4 + jaw_drop], fill=sh if hurt else bl)
    if jaw_open:
        for tx in (hx + 2, hx + 5):
            d.point((tx, hy + 2), fill=(255, 255, 255, 255))
    # Eye + brow highlight
    d.rectangle([hx + 2, hy - 2, hx + 3, hy - 1], fill=ey)

    # Near leg (bright articulated limb)
    nl_x, nl_y = bx + 1 + near_leg[0], by + 6 + near_leg[1]
    d.line([(bx + 1, by + 2), (nl_x, nl_y)], fill=b, width=3)
    d.line([(bx + 1, by + 2), (nl_x - 1, nl_y - 1)], fill=hi, width=1)
    d.rectangle([nl_x - 1, nl_y, nl_x + 3, nl_y + 1], fill=b)
    d.point((nl_x + 3, nl_y + 1), fill=bl)

    return add_pixel_outline(f, pal["outline"])


def build_dinosaur_sheet(pal: dict) -> Image.Image:
    sheet = Image.new("RGBA", (27 * 32, 32), (0, 0, 0, 0))
    frames = [None] * 27

    # 0-1: Idle breathing
    frames[0] = draw_dino_pose(pal, body_off=(0, 2), head_off=(0, 2), far_leg=(-2, 5), near_leg=(2, 5), tail_wag=0)
    frames[1] = draw_dino_pose(pal, body_off=(0, 3), head_off=(0, 3), far_leg=(-2, 4), near_leg=(2, 4), tail_wag=1, jaw_open=True)

    # 2-7: Crisp 6-frame run stride cycle
    run_cfg = [
        ((1, 2), (2, 2), (-5, 3), (5, 4), -2, False),
        ((2, 1), (3, 1), (-2, 5), (3, 1), -1, False),
        ((2, 2), (3, 2), (3, 4), (-2, 5), 1, False),
        ((1, 2), (2, 2), (5, 4), (-5, 3), 2, True),
        ((2, 1), (3, 1), (2, 1), (-3, 5), 1, False),
        ((2, 2), (3, 2), (-3, 5), (2, 4), -1, False),
    ]
    for idx, (bo, ho, fl, nl, tw, jw) in enumerate(run_cfg):
        frames[2 + idx] = draw_dino_pose(pal, body_off=bo, head_off=ho, lean=1.0, far_leg=fl, near_leg=nl, tail_wag=tw, jaw_open=jw)

    # 8: Jump Rise (upward leap!)
    frames[8] = draw_dino_pose(pal, body_off=(0, -1), head_off=(1, -3), lean=0.5, far_leg=(-3, 5), near_leg=(-1, 6), tail_wag=4)
    # 9: Jump Apex (tucked mid-air)
    frames[9] = draw_dino_pose(pal, body_off=(0, -1), head_off=(2, -1), lean=1.0, far_leg=(-2, 1), near_leg=(4, 1), tail_wag=0, jaw_open=True)
    # 10: Jump Fall (talons out!)
    frames[10] = draw_dino_pose(pal, body_off=(0, 1), head_off=(1, 1), lean=0.5, far_leg=(2, 5), near_leg=(5, 4), tail_wag=-4)
    # 11: Land Squash
    frames[11] = draw_dino_pose(pal, body_off=(0, 5), head_off=(1, 6), lean=0.5, far_leg=(-3, 2), near_leg=(4, 2), tail_wag=2)
    # 12: Recover
    frames[12] = draw_dino_pose(pal, body_off=(0, 3), head_off=(1, 3), lean=0.5, far_leg=(-2, 4), near_leg=(2, 4), tail_wag=0)
    # 13-14: Slide (ground belly skid + spark trails)
    frames[13] = draw_dino_pose(pal, crouch=True, tail_wag=0, sparks=False)
    frames[14] = draw_dino_pose(pal, crouch=True, tail_wag=-1, sparks=True)
    # 15: Dive (meteor drop)
    frames[15] = draw_dino_pose(pal, dive=True)
    # 16-18: Slash / Attack frames
    frames[16] = draw_dino_pose(pal, body_off=(2, 2), head_off=(3, 1), lean=1.5, far_leg=(-3, 4), near_leg=(4, 4), jaw_open=True)
    frames[17] = frames[16]
    frames[18] = frames[16]
    # 19-20: Hurt recoil
    h_base = draw_dino_pose(pal, body_off=(-1, 2), head_off=(-2, 0), lean=-1.0, far_leg=(0, 4), near_leg=(3, 3), hurt=True, jaw_open=True)
    frames[19] = h_base
    h_rot = h_base.rotate(12, resample=Image.NEAREST)
    frames[20] = h_rot

    # 21-26: Progressive Knockback & KO Collapse
    for k in range(6):
        fr = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
        if k == 0:
            fr.paste(h_base.rotate(24, resample=Image.NEAREST), (-1, 1))
        elif k == 1:
            fr.paste(h_base.rotate(58, resample=Image.NEAREST), (0, 4))
        else:
            collapsed = h_base.rotate(86, resample=Image.NEAREST)
            sq_h = max(14, 28 - k * 2)
            collapsed = collapsed.resize((32, sq_h), resample=Image.NEAREST)
            fr.paste(collapsed, (0, 32 - sq_h), collapsed)
            df = ImageDraw.Draw(fr, "RGBA")
            if k == 2:
                df.point((8, 12), fill=(255, 240, 110, 255))
                df.point((22, 11), fill=(255, 130, 60, 255))
            elif k >= 4:
                # KO dizzy orbit pixels above fallen hero
                ox = 14 + (k % 2) * 3
                df.point((ox, 11), fill=(255, 240, 96, 255))
                df.point((ox + 5, 13), fill=(120, 245, 255, 255))
        frames[21 + k] = fr

    for i, fr in enumerate(frames):
        if fr is not None:
            sheet.paste(fr, (i * 32, 0))
    return sheet


def enhance_dinosaur_sheets() -> None:
    mapping = {
        "dinosaur_sheet.png": "classic",
        "dinosaur_sheet_classic.png": "classic",
        "dinosaur_sheet_emerald.png": "emerald",
        "dinosaur_sheet_ruby.png": "ruby",
        "dinosaur_sheet_cyber.png": "cyber",
        "dinosaur_sheet_gold.png": "gold",
    }
    for fname, pal_key in mapping.items():
        path = os.path.join(OUT_DIR, fname)
        if not os.path.exists(path):
            continue
        sheet = build_dinosaur_sheet(SKIN_PALETTES[pal_key])
        sheet.save(path)
        print(f"Crafted crisp 27-frame spritesheet: {path} ({sheet.size})")


def main() -> None:
    generators = {
        "bg_sky.png": make_sky_plains,
        "bg_mountains.png": make_mountains_plains,
        "bg_hills.png": make_hills_plains,
        "bg_jungle_sky.png": make_sky_jungle,
        "bg_jungle_canopy.png": make_canopy_jungle,
        "bg_jungle_trees.png": make_trees_jungle,
        "bg_ice_sky.png": make_sky_ice,
        "bg_ice_peaks.png": make_peaks_ice,
        "bg_ice_ruins.png": make_ruins_ice,
        "bg_volcano_sky.png": make_sky_volcano,
        "bg_volcano_mountains.png": make_mountains_volcano,
        "bg_volcano_caves.png": make_caves_volcano,
        "hazard_lava_pit.png": make_lava_pit,
        "obstacle_pterodactyl.png": make_pterodactyl,
        "obstacle_crawler.png": make_crawler,
        "collectible_gem.png": make_gem,
        "obstacle_storm_cloud.png": make_storm_cloud,
        "obstacle_low.png": make_cactus_low,
        "obstacle_wooden_barrier.png": make_wooden_barrier,
        "subground_strata.png": make_subground_strata,
        "ground_tile.png": make_ground_tile,
        "obstacle_high.png": make_overhang_arch,
        "skill_bone_blade.png": make_skill_bone_blade,
    }
    for fname, fn in generators.items():
        img = fn()
        out_path = os.path.join(OUT_DIR, fname)
        img.save(out_path)
        print(f"Generated {out_path} ({img.size})")

    enhance_dinosaur_sheets()
    make_skin_icons()
    print("Enhanced pixel art generation completed!")


if __name__ == "__main__":
    main()
