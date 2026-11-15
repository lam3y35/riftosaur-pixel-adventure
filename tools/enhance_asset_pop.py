"""Asset 'pop' pass: richer shading, rim light, saturation and hand-redrawn gem / dust.
Keeps every sprite's exact size + frame layout so no scene needs changes.
Originals are backed up once to assets/sprites/_orig_before_pop/.
Run:  python tools/enhance_asset_pop.py
"""
import colorsys, os, shutil
from PIL import Image, ImageDraw

SP = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")
BK = os.path.join(SP, "_orig_before_pop")

TARGETS = """obstacle_crate obstacle_crawler obstacle_low obstacle_high obstacle_pterodactyl
obstacle_storm_cloud obstacle_wooden_barrier boost_launchpad boost_mushroom boost_stump
boost_wind_vent pickup_flight_rocket pickup_flight_wings pickup_skill_orb hazard_lava_pit
platform_solid platform_oneway skill_air_dash skill_bone_blade skill_boomerang skill_bounce_power
skill_ground_slam skill_magnet_relic skill_stone_shield skill_time_shard""".split()
# glowing / "collectible" things get a stronger boost
GLOW = {"pickup_flight_rocket", "pickup_flight_wings", "pickup_skill_orb", "boost_mushroom",
        "boost_launchpad", "boost_wind_vent", "hazard_lava_pit", "obstacle_storm_cloud"}


def adjust(c, sat, val):
    h, s, v = colorsys.rgb_to_hsv(c[0] / 255, c[1] / 255, c[2] / 255)
    s = min(1, s * sat)
    v = max(0, min(1, v * val))
    r, g, b = colorsys.hsv_to_rgb(h, s, v)
    return (int(r * 255), int(g * 255), int(b * 255))


def pop(img, strong):
    img = img.convert("RGBA")
    w, h = img.size
    src = img.load()
    out = img.copy()
    px = out.load()

    def opaque(x, y):
        return 0 <= x < w and 0 <= y < h and src[x, y][3] > 20

    for y in range(h):
        for x in range(w):
            r, g, b, a = src[x, y]
            if a <= 20:
                continue
            lum = (r * 299 + g * 587 + b * 114) / 1000
            is_outline = lum < 45
            if is_outline:
                # deeper, slightly cool outline reads cleaner on all backgrounds
                px[x, y] = (max(0, r - 6), max(0, g - 6), min(255, b + 6), a)
                continue
            c = adjust((r, g, b), 1.28 if strong else 1.18, 1.0)
            # light from top-left: rim highlight / underside shade
            top_edge = not opaque(x, y - 1) or (not opaque(x, y - 2) and y > 1 and lum > 90)
            left_edge = not opaque(x - 1, y)
            bot_edge = not opaque(x, y + 1) or not opaque(x + 1, y + 1)
            # vertical gradient across sprite
            t = y / max(1, h - 1)
            k = 1.10 - 0.26 * t
            c = tuple(min(255, int(v * k)) for v in c)
            if top_edge or left_edge:
                c = tuple(min(255, int(v * 1.22 + 22)) for v in c)
            elif bot_edge:
                c = tuple(int(v * 0.80) for v in c)
            px[x, y] = (*c, a)
    # inner highlight pixel pair on bright chunky sprites (gloss)
    if strong:
        for y in range(1, h - 1):
            for x in range(1, w - 1):
                if src[x, y][3] > 20 and not opaque(x - 1, y - 1) and opaque(x, y) and opaque(x + 1, y + 1):
                    r, g, b, a = px[x, y]
                    px[x, y] = (min(255, r + 45), min(255, g + 45), min(255, b + 45), a)
    return out


def make_gem():
    im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    OUT = (8, 24, 70, 255)
    # outline silhouette
    d.polygon([(8, 0), (13, 3), (15, 7), (8, 15), (1, 7), (3, 3)], fill=OUT)
    # facets
    d.polygon([(8, 1), (12, 3), (8, 5), (4, 3)], fill=(190, 250, 255, 255))      # crown top
    d.polygon([(4, 3), (8, 5), (7, 8), (2, 7)], fill=(70, 215, 255, 255))        # left crown
    d.polygon([(12, 3), (14, 7), (9, 8), (8, 5)], fill=(30, 150, 240, 255))      # right crown
    d.polygon([(2, 7), (7, 8), (8, 14)], fill=(20, 120, 225, 255))               # left pavilion
    d.polygon([(7, 8), (9, 8), (8, 14)], fill=(110, 230, 255, 255))              # centre
    d.polygon([(9, 8), (14, 7), (8, 14)], fill=(15, 80, 190, 255))               # right pavilion
    # sparkle
    for p in [(5, 3), (6, 2)]:
        im.putpixel(p, (255, 255, 255, 255))
    im.putpixel((4, 4), (255, 255, 255, 255))
    for p in [(13, 1), (14, 0), (12, 0), (14, 2), (13, 0)]:
        pass
    im.putpixel((14, 1), (255, 255, 255, 230))
    im.putpixel((15, 1), (170, 240, 255, 150))
    im.putpixel((14, 0), (170, 240, 255, 150))
    im.putpixel((14, 2), (170, 240, 255, 150))
    im.putpixel((13, 1), (170, 240, 255, 150))
    return im


def make_dust():
    # 4 frames 16x16: growing, fading, warm-white puffs with highlights
    im = Image.new("RGBA", (64, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for f in range(4):
        ox = f * 16
        a = [255, 220, 150, 70][f]
        r = [2, 3, 4, 5][f]
        spread = [1, 3, 5, 7][f]
        for dx, dy, rr in [(-spread, 0, r), (0, -f // 2, r + 1), (spread, 0, r), (-spread // 2, 1, r - 1 if r > 2 else 1), (spread // 2, 1, r - 1 if r > 2 else 1)]:
            cx, cy = ox + 8 + dx, 11 - r // 2 + dy
            d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=(226, 208, 176, a))
            d.ellipse([cx - rr + 1, cy - rr + 1, cx + rr - 1, max(cy - rr + 1, cy + rr - 2)], fill=(255, 246, 226, a))
        # little flying pebbles
        if f:
            for dx, dy in [(-spread - 3, -3 - f), (spread + 3, -2 - f)]:
                if 0 <= 8 + dx < 16:
                    d.point((ox + 8 + dx, 8 + dy), fill=(150, 120, 90, a))
    return im


def main():
    os.makedirs(BK, exist_ok=True)
    for n in TARGETS + ["collectible_gem", "dust_puff"]:
        p = os.path.join(SP, n + ".png")
        b = os.path.join(BK, n + ".png")
        if not os.path.exists(b):
            shutil.copy(p, b)
    for n in TARGETS:
        src = Image.open(os.path.join(BK, n + ".png"))  # always from original => idempotent
        pop(src, n in GLOW).save(os.path.join(SP, n + ".png"))
    make_gem().save(os.path.join(SP, "collectible_gem.png"))
    make_dust().save(os.path.join(SP, "dust_puff.png"))
    print("done")


if __name__ == "__main__":
    main()

