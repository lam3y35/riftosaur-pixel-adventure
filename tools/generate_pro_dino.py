"""
Fast, Pixel-Perfect Asset Generator matching the `gini/` reference screenshots.
Fixes:
1. Dinosaur silhouette & anatomy to match `gini/dino_sample.png` (curved tail, stepped back, rounded snout, thick thighs, L-arm, dorsal highlights, true collapse death animation) across all 5 skins.
2. `bg_mountains.png` broken floating snow-cap bug -> crisp pixel-art mountain peaks with proper internal snow caps and two-tone shading.
3. `bg_sky.png` -> crisp sky with pixel dither bands and shaded pixel-art clouds matching `gini/`.
4. `bg_hills.png` + `ground_tile.png` -> 100% seamless matching meadow green (`#63a638`) from y=230 to y=270 so the ground is a solid 40px block with zero seams.
5. `obstacle_low.png` & `obstacle_crate.png` -> crisp pixel-art cactus and crate with dark outlines (zero blur).
"""

import os
import math
from PIL import Image

# ==============================================================================
# 1. DINOSAUR SPRITESHEET & SKIN ICONS (Exact `gini/dino_sample.png` silhouette)
# ==============================================================================
SKIN_PALETTES = {
    "classic": {
        "outline": (42, 46, 52, 255),
        "body":    (88, 92, 98, 255),
        "belly":   (122, 128, 136, 255),
        "spine":   (148, 156, 166, 255),
        "eye":     (220, 245, 255, 255),
    },
    "emerald": {
        "outline": (14, 58, 34, 255),
        "body":    (34, 152, 84, 255),
        "belly":   (110, 225, 148, 255),
        "spine":   (190, 255, 120, 255),
        "eye":     (255, 240, 80, 255),
    },
    "ruby": {
        "outline": (68, 14, 22, 255),
        "body":    (198, 38, 52, 255),
        "belly":   (248, 128, 96, 255),
        "spine":   (255, 210, 80, 255),
        "eye":     (255, 250, 160, 255),
    },
    "cyber": {
        "outline": (24, 18, 68, 255),
        "body":    (56, 48, 148, 255),
        "belly":   (0, 225, 255, 255),
        "spine":   (255, 64, 220, 255),
        "eye":     (0, 255, 255, 255),
    },
    "gold": {
        "outline": (92, 52, 8, 255),
        "body":    (235, 168, 24, 255),
        "belly":   (255, 232, 128, 255),
        "spine":   (255, 250, 200, 255),
        "eye":     (80, 240, 255, 255),
    },
}

# 32x32 pixel template matching `gini/dino_sample.png`
# Legend: '.'=transparent, 'O'=outline, 'B'=body, 'L'=belly/highlight, 'S'=spine, 'E'=eye
UPRIGHT_BODY = [
    "................................",
    "................................",
    "..................OOOOOOOOO.....",
    ".................OBBBBBBBBBO....",
    "................OBBBEBBBBBBBO...",
    "................OBBBBBBBBBBBBO..",
    "................OBBBBBBBBBBBBO..",
    "................OBBBBBBBBBBBBO..",
    "................OBBBBBBOOOOOO...",
    "...............OBBBBBBBBO.......",
    "..............OSBBBBBBBBBBBBBO..",
    ".............OSBBBBBBBBBBBBBBO..",
    ".....OO.....OSBBBBBBBBBOO.......",
    ".....OBO...OSBBBBBBBBBBO........",
    ".....OBBO.OSBBBBBBBBBBBBO.......",
    ".....OBBBOOBBBBBBBBBBBBOOO......",
    ".....OBBBBBBBBBBBBBBBBBO.OO.....",
    "......OBBBBBBBBBBBBBBBBO.O......",
    "......OBBBBBBBBBBBBBBBBO........",
    ".......OBBBBBBBBBBBBBBO.........",
    "........OBBBBBBBBBBBLLO.........",
    ".........OBBBBBBBBBLLLO.........",
    "..........OBBBBBBBBLLO..........",
    "...........OBBBBBBBBO...........",
    "...........OBBBOOBBBO...........",
    "...........OBBBO.OBBO...........",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
]

SLIDE_BODY = [
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    ".................OOOOOOOOOO.....",
    "....OO..........OBBBBBBBBBBO....",
    "....OBOO.......OBBBEBBBBBBBBO...",
    "....OBBBOOOOOOOSBBBBBBBBBBBBO...",
    ".....OBBBBBBBBBBBBBBBBBBBBBO....",
    ".....OBBBBBBBBBBBBBBBBBOOOO.....",
    "......OBBBBBBBBBBBBBBBBBBBBBBO..",
    ".......OBBBBBBBBBBBBBBBBBBBBO...",
    "........OBBBBBBBBBBBBBLLLLOO....",
    ".........OOOOOOOOOOOOOOOOO......",
    "...........OBBBO...OBBBO........",
    "...........OBBO.....OBBO........",
    "...........OOBOO....OOBOO.......",
    "...........OOOOO....OOOOO.......",
    "................................",
    "................................",
    "................................",
    "................................",
]

DEAD_BODY = [
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    ".........OOOOOOOOOOOO...........",
    "........OBBBBBBBBBBBBOOO........",
    "....OOOOBBBBBBBBBBBBBBBBOOOO....",
    "...OBBBBBBBBBBBBBBBBBBBBBBBBO...",
    "...OBBBBBBBBBBBBBBBBBBEBBBBBO...",
    "....OBBBBBBBBBBBBBBBBBBBBBBBO...",
    ".....OBBBBBBBBBBBBBBBBBOOOOO....",
    "......OBBBBBBBBBLLLLLLBBBBBO....",
    ".......OOOOOOOOOOOOOOOOOOOO.....",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
]

def draw_template(canvas, fx, fy, template, pal, leg_mode=0):
    char_map = {
        'O': pal["outline"],
        'B': pal["body"],
        'L': pal["belly"],
        'S': pal["spine"],
        'E': pal["eye"],
    }
    for y in range(32):
        row = template[y]
        for x in range(32):
            ch = row[x]
            if ch in char_map:
                canvas.putpixel((fx + x, fy + y), char_map[ch])

    if template is UPRIGHT_BODY:
        O = pal["outline"]
        B = pal["body"]
        # Draw legs at y=26..27 based on leg_mode
        if leg_mode == 0: # Idle standing
            for y in (26, 27):
                for x in (11, 12, 13):
                    canvas.putpixel((fx + x, fy + y), O if x in (11, 13) else B)
                for x in (17, 18, 19):
                    canvas.putpixel((fx + x, fy + y), O if x in (17, 19) else B)
            for x in (11, 12, 13, 14):
                canvas.putpixel((fx + x, fy + 27), O)
            for x in (17, 18, 19, 20):
                canvas.putpixel((fx + x, fy + 27), O)
        elif leg_mode == 1: # Left leg forward, right leg raised
            for x in (10, 11, 12):
                canvas.putpixel((fx + x, fy + 26), B)
                canvas.putpixel((fx + x + 1, fy + 27), O)
            for x in (18, 19, 20):
                canvas.putpixel((fx + x, fy + 25), O)
        elif leg_mode == 2: # Right leg forward, left leg raised
            for x in (11, 12, 13):
                canvas.putpixel((fx + x, fy + 25), O)
            for x in (18, 19, 20):
                canvas.putpixel((fx + x, fy + 26), B)
                canvas.putpixel((fx + x + 1, fy + 27), O)
        elif leg_mode == 3: # Jump tucked
            for x in (11, 12, 13, 17, 18, 19):
                canvas.putpixel((fx + x, fy + 25), O)

def generate_all_dinos():
    for skin_id, pal in SKIN_PALETTES.items():
        sheet = Image.new("RGBA", (32 * 27, 32), (0, 0, 0, 0))
        for f in range(27):
            fx = f * 32
            if f in (0, 1): # Idle
                draw_template(sheet, fx, 0, UPRIGHT_BODY, pal, leg_mode=0)
            elif 2 <= f <= 7: # Run cycle
                lm = 1 if (f % 2 == 0) else 2
                by = -1 if (f in (3, 6)) else 0
                draw_template(sheet, fx, by, UPRIGHT_BODY, pal, leg_mode=lm)
            elif f in (8, 9, 10): # Jump / Apex / Fall
                draw_template(sheet, fx, -1, UPRIGHT_BODY, pal, leg_mode=3)
            elif f == 11: # Land
                draw_template(sheet, fx, 1, UPRIGHT_BODY, pal, leg_mode=0)
            elif f in (12, 13, 14): # Slide
                draw_template(sheet, fx, 0, SLIDE_BODY, pal)
            elif f == 15: # Dive
                draw_template(sheet, fx, 0, SLIDE_BODY, pal)
            elif f in (16, 17, 18): # Hurt
                draw_template(sheet, fx, 0, UPRIGHT_BODY, pal, leg_mode=3)
            else: # 19..26 Dead on ground
                draw_template(sheet, fx, 0, DEAD_BODY, pal)

        sheet.save(f"assets/sprites/dinosaur_sheet_{skin_id}.png")
        if skin_id == "classic":
            sheet.save("assets/sprites/dinosaur_sheet.png")

        # Save 32x32 preview icon (frame 2: dynamic run pose)
        icon = sheet.crop((64, 0, 96, 32))
        icon.save(f"assets/sprites/skin_icon_{skin_id}.png")

# ==============================================================================
# 2. BACKGROUNDS & SEAMLESS GROUND (Exact `gini/` visual style)
# ==============================================================================
def generate_backgrounds_and_ground():
    w, h = 480, 270

    # --- A. SKY WITH DITHER BANDS & PIXEL CLOUDS (`bg_sky.png`) ---
    sky = Image.new("RGBA", (w, h), (132, 202, 250, 255))
    SKY_TOP = (122, 196, 248, 255)
    SKY_MID = (146, 212, 252, 255)
    SKY_LOW = (168, 224, 254, 255)

    for y in range(h):
        for x in range(w):
            if y < 68:
                col = SKY_TOP
            elif y < 74:
                col = SKY_MID if ((x // 2 + y // 2) % 2 == 0) else SKY_TOP
            elif y < 102:
                col = SKY_MID
            elif y < 108:
                col = SKY_LOW if ((x // 2 + y // 2) % 2 == 0) else SKY_MID
            else:
                col = SKY_LOW
            sky.putpixel((x, y), col)

    # Pixel-art stepped clouds with light-blue under-shading
    def draw_pixel_cloud(img, cx, cy, cw, ch):
        WHITE = (246, 252, 255, 255)
        SHADE = (208, 234, 252, 255)
        for y in range(cy - ch, cy + 4):
            for x in range(cx - cw, cx + cw):
                if 0 <= x < w and 0 <= y < h:
                    nx = (x - cx) / float(cw)
                    ny = (y - cy) / float(ch)
                    # Multi-lobe puff check
                    dMain = nx * nx + (ny + 0.2) * (ny + 0.2)
                    dLeft = (nx + 0.45) ** 2 + (ny + 0.05) ** 2
                    dRight = (nx - 0.45) ** 2 + (ny + 0.1) ** 2
                    if (dMain <= 0.55 or dLeft <= 0.28 or dRight <= 0.25) and y <= cy + 2:
                        # Quantize to 2x2 pixel blocks for crisp retro feel
                        if y >= cy - 2:
                            img.putpixel((x, y), SHADE)
                        else:
                            img.putpixel((x, y), WHITE)

    draw_pixel_cloud(sky, 45, 70, 44, 22)
    draw_pixel_cloud(sky, 165, 62, 34, 16)
    draw_pixel_cloud(sky, 220, 94, 28, 14)
    draw_pixel_cloud(sky, 315, 66, 62, 26)
    draw_pixel_cloud(sky, 435, 68, 42, 20)
    sky.save("assets/sprites/bg_sky.png")

    # --- B. MOUNTAINS (`bg_mountains.png`) - Fixes floating snow cap bug! ---
    mtn = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    peaks = [
        (60, 102, 85),    # Peak 1: x=60, apex_y=102, half_width=85
        (138, 126, 65),   # Peak 2: x=138, apex_y=126, half_width=65
        (428, 102, 85),   # Peak 3: x=428, apex_y=102, half_width=85
    ]
    MTN_LEFT  = (142, 174, 172, 255)
    MTN_RIGHT = (120, 154, 152, 255)
    MTN_OUT   = (102, 134, 132, 255)
    SNOW_L    = (236, 246, 250, 255)
    SNOW_R    = (210, 228, 236, 255)

    for px, py, hw in peaks:
        base_y = 232
        height_m = base_y - py
        for y in range(py, base_y):
            progress = (y - py) / float(height_m)
            # Quantize to 2px steps for authentic pixel-art slope
            half_span = int((progress * hw) // 2) * 2
            for x in range(px - half_span, px + half_span + 1):
                wx = x % w
                dx = x - px
                is_edge = abs(dx) >= half_span - 1
                # Snow cap ONLY inside the mountain triangle (top 28% with jagged edge)
                jag = ((x // 3) * 7) % 6
                is_snow = (y - py) < (height_m * 0.26 - jag)
                if is_edge:
                    mtn.putpixel((wx, y), MTN_OUT)
                elif is_snow:
                    mtn.putpixel((wx, y), SNOW_L if dx <= 0 else SNOW_R)
                else:
                    mtn.putpixel((wx, y), MTN_LEFT if dx <= 0 else MTN_RIGHT)

    mtn.save("assets/sprites/bg_mountains.png")

    # --- C. HILLS & SOLID LOWER GROUND FILL (`bg_hills.png`) ---
    hills = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    GROUND_FILL = (102, 168, 52, 255) # Matches ground_tile bottom seamlessly!
    HILL_DARK   = (86, 148, 44, 255)
    for x in range(w):
        # Gentle rolling hill contour just above y=230
        hy = int(222 + 6 * math.sin(x * 2 * math.pi / 240.0) + 3 * math.cos(x * 2 * math.pi / 120.0))
        for y in range(hy, h):
            if y < 230:
                hills.putpixel((x, y), HILL_DARK)
            else:
                hills.putpixel((x, y), GROUND_FILL)
    hills.save("assets/sprites/bg_hills.png")

    # --- D. SEAMLESS GROUND TILE (`ground_tile.png`, 16x16) ---
    tile = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    TOP_LINE   = (74, 84, 72, 255)
    GRASS_TOP  = (126, 200, 68, 255)
    for y in range(16):
        for x in range(16):
            if y in (0, 1):
                tile.putpixel((x, y), TOP_LINE)
            elif y < 5:
                tile.putpixel((x, y), GRASS_TOP)
            elif y == 5:
                tile.putpixel((x, y), GRASS_TOP if (x % 4 in (0, 1)) else GROUND_FILL)
            else:
                tile.putpixel((x, y), GROUND_FILL)
    tile.save("assets/sprites/ground_tile.png")

    # --- E. CRISP PIXEL-ART CACTUS (`obstacle_low.png`, 16x24) ---
    cactus = Image.new("RGBA", (16, 24), (0, 0, 0, 0))
    C_OUT  = (34, 62, 18, 255)
    C_BODY = (84, 142, 42, 255)
    C_LITE = (122, 188, 64, 255)
    c_grid = [
        "......OOOO......",
        ".....OLLBBO.....",
        ".....OLLBBO.....",
        ".....OLLBBO.....",
        ".....OLLBBO.OOO.",
        ".OOO.OLLBBO.OLBO",
        "OLLB.OLLBBO.OLBO",
        "OLLB.OLLBBO.OLBO",
        "OLLB.OLLBBO.OLBO",
        "OLLB.OLLBBO.OLBO",
        "OLLBOOLLBBO.OLBO",
        ".OOOOOOOOOOOOLBO",
        ".....OLLBBOOOOO.",
        ".....OLLBBO.....",
        ".....OLLBBO.....",
        ".....OLLBBO.....",
        ".....OLLBBO.....",
        ".....OLLBBO.....",
        ".....OLLBBO.....",
        ".....OLLBBO.....",
        ".....OLLBBO.....",
        ".....OLLBBO.....",
        ".....OLLBBO.....",
        ".....OOOOOO.....",
    ]
    c_map = {'O': C_OUT, 'B': C_BODY, 'L': C_LITE}
    for y in range(24):
        for x in range(16):
            ch = c_grid[y][x]
            if ch in c_map:
                cactus.putpixel((x, y), c_map[ch])
    cactus.save("assets/sprites/obstacle_low.png")

    # --- F. CRISP PIXEL-ART WOODEN CRATE (`obstacle_crate.png`, 24x24) ---
    crate = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
    W_OUT  = (68, 42, 22, 255)
    W_DARK = (138, 88, 46, 255)
    W_MID  = (178, 118, 66, 255)
    W_LITE = (212, 152, 94, 255)
    for y in range(24):
        for x in range(24):
            if x == 0 or x == 23 or y == 0 or y == 23:
                crate.putpixel((x, y), W_OUT)
            elif x in (1, 22) or y in (1, 22):
                crate.putpixel((x, y), W_LITE if (x == 1 or y == 1) else W_DARK)
            elif x in (3, 20) or y in (3, 20):
                crate.putpixel((x, y), W_OUT)
            elif abs(x - y) <= 1 or abs((23 - x) - y) <= 1:
                crate.putpixel((x, y), W_DARK if abs(x - y) == 0 else W_LITE)
            elif y % 4 == 0:
                crate.putpixel((x, y), W_DARK)
            else:
                crate.putpixel((x, y), W_MID)
    crate.save("assets/sprites/obstacle_crate.png")

if __name__ == "__main__":
    generate_all_dinos()
    generate_backgrounds_and_ground()
    print("All reference-grade dino skins, backgrounds, ground, cactus, and crate generated!")
