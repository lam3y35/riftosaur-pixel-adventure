"""
Reference Asset Generator for Riftosaur.
Produces visual assets directly replicating the reference photos in gini/:
- bg_sky: Bright vibrant daytime sky (480x270) with fluffy clouds
- bg_mountains: Majestic snow-capped mountains (480x160)
- bg_hills: Rolling green hills (480x120)
- ground_tile: Rich green grass with earth underlayer (16x16)
- obstacle_low: Classic cactus cluster (16x24)
- obstacle_crate: Wooden stepping crate (24x24) that player can land on
- obstacle_high: Hanging jungle vine barrier to slide under (24x32)
"""

import math
from PIL import Image

def generate_reference_assets():
    width = 480
    height = 270

    # 1. Sky: Vibrant daytime blue with fluffy clouds
    sky = Image.new("RGBA", (width, height))
    # Soft vertical blue gradient: top (115, 185, 245) -> horizon (175, 218, 252)
    for y in range(height):
        t = y / float(height)
        r = int(115 + t * (175 - 115))
        g = int(185 + t * (218 - 185))
        b = int(245 + t * (252 - 245))
        for x in range(width):
            sky.putpixel((x, y), (r, g, b, 255))

    # Fluffy cartoon clouds (white with light cyan-blue bottom shadow)
    def draw_cloud(img, cx, cy, radius):
        CLOUD_WHITE = (255, 255, 255, 255)
        CLOUD_SHADOW = (215, 235, 250, 255)
        # 3 overlapping bubbles
        bubbles = [(cx - radius, cy + 2, radius * 0.7), (cx, cy - 2, radius), (cx + radius, cy + 2, radius * 0.8)]
        for bx, by, br in bubbles:
            for y in range(int(by - br), int(by + br + 1)):
                for x in range(int(bx - br * 1.5), int(bx + br * 1.5 + 1)):
                    dx = (x - bx) / 1.5
                    dy = (y - by)
                    if dx * dx + dy * dy <= br * br:
                        if 0 <= x < width and 0 <= y < height:
                            if dy > br * 0.4:
                                img.putpixel((x, y), CLOUD_SHADOW)
                            else:
                                img.putpixel((x, y), CLOUD_WHITE)

    draw_cloud(sky, 90, 45, 16)
    draw_cloud(sky, 220, 60, 20)
    draw_cloud(sky, 380, 40, 18)
    draw_cloud(sky, 450, 75, 14)
    sky.save("assets/sprites/bg_sky.png")

    # 2. Distant Snow-Capped Mountains (480x160 px)
    mountains = Image.new("RGBA", (width, 160), (0, 0, 0, 0))
    M_BODY = (115, 147, 167, 255)      # Slate blue-gray mountain
    M_SHADOW = (92, 122, 140, 255)     # Mountain shadow side
    SNOW = (255, 255, 255, 255)        # Pure white snow peak
    SNOW_SHADOW = (220, 235, 245, 255) # Snow shadow

    # Mountain peak centers: x=100, x=280, x=430
    peaks = [(90, 110, 85), (260, 135, 95), (420, 120, 90)]
    for px, pw, ph in peaks:
        for x in range(px - pw, px + pw + 1):
            if 0 <= x < width:
                dist = abs(x - px)
                t = dist / float(pw)
                if t <= 1.0:
                    peak_top = 160 - int((1.0 - t) * ph)
                    for y in range(peak_top, 160):
                        is_shadow = (x > px)
                        snow_depth = ph * 0.35
                        if y <= peak_top + snow_depth:
                            mountains.putpixel((x, y), SNOW_SHADOW if is_shadow else SNOW)
                        else:
                            mountains.putpixel((x, y), M_SHADOW if is_shadow else M_BODY)
    mountains.save("assets/sprites/bg_mountains.png")

    # 3. Midground Rolling Green Hills (480x120 px)
    hills = Image.new("RGBA", (width, 120), (0, 0, 0, 0))
    HILL_COLOR = (106, 176, 76, 255)
    HILL_HIGHLIGHT = (126, 196, 96, 255)
    for x in range(width):
        h = int(35 + 18 * math.sin(x * 0.02) + 10 * math.cos(x * 0.045))
        peak_y = 120 - h
        for y in range(peak_y, 120):
            if y == peak_y or y == peak_y + 1:
                hills.putpixel((x, y), HILL_HIGHLIGHT)
            else:
                hills.putpixel((x, y), HILL_COLOR)
    hills.save("assets/sprites/bg_hills.png")

    # 4. Ground Tile (16x16)
    # Vibrant green grass top with dark soil underneath
    gt = Image.new("RGBA", (16, 16))
    GRASS_TOP = (126, 196, 96, 255)
    GRASS_BODY = (106, 176, 76, 255)
    DIRT_LIGHT = (110, 80, 50, 255)
    DIRT_DARK = (85, 60, 38, 255)
    for y in range(16):
        for x in range(16):
            if y == 0:
                gt.putpixel((x, y), GRASS_TOP)
            elif y in (1, 2):
                gt.putpixel((x, y), GRASS_BODY)
            elif y == 3 and (x % 3 == 0):
                gt.putpixel((x, y), GRASS_BODY) # Grass root fringe
            else:
                gt.putpixel((x, y), DIRT_LIGHT if (x + y) % 2 == 0 else DIRT_DARK)
    gt.save("assets/sprites/ground_tile.png")

    # 5. Classic Cactus Hazard (16x24) matching reference photo
    cactus = Image.new("RGBA", (16, 24), (0, 0, 0, 0))
    C_MAIN = (56, 102, 41, 255)       # Rich green cactus body
    C_LIGHT = (74, 133, 54, 255)      # Sunlit rib
    C_OUTLINE = (30, 58, 22, 255)     # Dark outline

    # Center stalk: x=6..9, y=4..23
    for y in range(4, 24):
        for x in range(6, 10):
            cactus.putpixel((x, y), C_LIGHT if x == 7 else C_MAIN)
    # Rounded top
    cactus.putpixel((7, 3), C_MAIN); cactus.putpixel((8, 3), C_MAIN)

    # Left arm: x=2..4, y=9..15
    for y in range(9, 15):
        cactus.putpixel((2, y), C_MAIN)
        cactus.putpixel((3, y), C_LIGHT)
    # Left arm horizontal branch: x=3..6, y=14..15
    for x in range(3, 7):
        cactus.putpixel((x, 14), C_MAIN)
        cactus.putpixel((x, 15), C_MAIN)

    # Right arm: x=11..13, y=7..13
    for y in range(7, 13):
        cactus.putpixel((12, y), C_LIGHT)
        cactus.putpixel((13, y), C_MAIN)
    # Right arm horizontal branch: x=9..12, y=12..13
    for x in range(9, 13):
        cactus.putpixel((x, 12), C_MAIN)
        cactus.putpixel((x, 13), C_MAIN)

    # Dark crisp outline
    cactus_outlined = Image.new("RGBA", (16, 24), (0, 0, 0, 0))
    for y in range(24):
        for x in range(16):
            if cactus.getpixel((x, y))[3] > 0:
                cactus_outlined.putpixel((x, y), cactus.getpixel((x, y)))
            else:
                has_pixel = False
                for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < 16 and 0 <= ny < 24 and cactus.getpixel((nx, ny))[3] > 0:
                        has_pixel = True
                        break
                if has_pixel:
                    cactus_outlined.putpixel((x, y), C_OUTLINE)
    cactus_outlined.save("assets/sprites/obstacle_low.png")

    # 6. Wooden Crate Stepping Block (24x24 px) matching Image 1 & 4
    crate = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
    WOOD_LIGHT = (185, 119, 55, 255)
    WOOD_MID = (145, 90, 40, 255)
    WOOD_DARK = (90, 52, 20, 255)
    NAIL = (60, 40, 25, 255)

    # Fill crate plank background
    for y in range(1, 23):
        for x in range(1, 23):
            crate.putpixel((x, y), WOOD_LIGHT if y % 4 != 0 else WOOD_MID)

    # Outer border planks (top, bottom, left, right)
    for x in range(24):
        crate.putpixel((x, 0), WOOD_DARK)
        crate.putpixel((x, 1), WOOD_MID)
        crate.putpixel((x, 22), WOOD_MID)
        crate.putpixel((x, 23), WOOD_DARK)
    for y in range(24):
        crate.putpixel((0, y), WOOD_DARK)
        crate.putpixel((1, y), WOOD_MID)
        crate.putpixel((22, y), WOOD_MID)
        crate.putpixel((23, y), WOOD_DARK)

    # Diagonal X brace
    for i in range(2, 22):
        crate.putpixel((i, i), WOOD_DARK)
        crate.putpixel((i, 23 - i), WOOD_DARK)
        if i + 1 < 22:
            crate.putpixel((i + 1, i), WOOD_MID)
            crate.putpixel((i + 1, 23 - i), WOOD_MID)

    # Corner nails
    crate.putpixel((2, 2), NAIL)
    crate.putpixel((21, 2), NAIL)
    crate.putpixel((2, 21), NAIL)
    crate.putpixel((21, 21), NAIL)

    crate.save("assets/sprites/obstacle_crate.png")

    # 7. Overhead Jungle / Bramble Vine to slide under (24x32 px)
    overhang = Image.new("RGBA", (24, 32), (0, 0, 0, 0))
    VINE_DARK = (35, 45, 30, 255)
    VINE_MID = (55, 80, 45, 255)
    VINE_LIGHT = (85, 125, 65, 255)
    # Upper log/vine body: y=0..16
    for y in range(16):
        for x in range(24):
            overhang.putpixel((x, y), VINE_MID if (x + y) % 3 == 0 else VINE_DARK)
    # Leaves & hanging tendrils: y=16..20 (leaves bottom 12px clear for sliding dinosaur)
    for x in range(24):
        tendril_len = int(2 + 3 * math.sin(x * 1.2))
        for ty in range(16, 16 + tendril_len):
            overhang.putpixel((x, ty), VINE_LIGHT if ty == 16 else VINE_MID)
    overhang.save("assets/sprites/obstacle_high.png")

    print("Successfully generated all reference matching assets (sky, mountains, hills, ground, cactus, crate, overhang).")

if __name__ == "__main__":
    generate_reference_assets()
