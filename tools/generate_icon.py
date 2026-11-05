"""
Badass App Icon generator for Riftosaur.
Generates an epic pixel-art icon:
- Fierce roaring Riftosaur dinosaur with glowing cyan rift eye & dorsal spines
- Jagged dimensional rift fissure bursting across deep twilight cosmic backdrop
- Metallic dark border with rounded app corners
- Exported at 48, 72, 96, 144, 192, and 512 px
"""

import os
from PIL import Image

def generate_icons():
    os.makedirs("assets/icons/android", exist_ok=True)
    w, h = 48, 48
    base = Image.new("RGBA", (w, h), (0, 0, 0, 0))

    # Palettes
    BG_DEEP = (15, 12, 28, 255)       # Cosmic dark void
    BG_MID = (38, 22, 54, 255)        # Twilight purple
    BORDER = (10, 8, 20, 255)         # Outer rim
    BORDER_HI = (88, 56, 112, 255)    # Outer rim highlight

    RIFT_CYAN = (34, 211, 238, 255)   # Neon cyan rift energy
    RIFT_VIOLET = (168, 85, 247, 255) # Electric violet
    RIFT_WHITE = (240, 253, 250, 255) # Blinding energy core

    DINO_BODY = (30, 41, 59, 255)     # Obsidian dark scales
    DINO_HI = (71, 85, 105, 255)      # Specular slate scale highlight
    DINO_DARK = (15, 23, 42, 255)     # Deep shadow
    DINO_TEETH = (255, 255, 255, 255) # Sharp fangs
    DINO_MOUTH = (159, 18, 57, 255)   # Dark crimson maw

    # 1. Rounded squircle background
    for y in range(h):
        for x in range(w):
            # Squircle distance approximation
            dx = abs(x - 23.5)
            dy = abs(y - 23.5)
            corner_r = 10.0
            in_shape = False
            if dx <= 22 and dy <= 22:
                if dx <= (22 - corner_r) or dy <= (22 - corner_r):
                    in_shape = True
                else:
                    cdx = dx - (22 - corner_r)
                    cdy = dy - (22 - corner_r)
                    if (cdx * cdx + cdy * cdy) <= corner_r * corner_r:
                        in_shape = True

            if in_shape:
                # Border ring
                is_outer = (dx >= 21 or dy >= 21) or (dx > 12 and dy > 12 and (dx-12)**2 + (dy-12)**2 >= 9*9)
                is_inner_border = (dx >= 19.5 or dy >= 19.5)

                if is_outer:
                    base.putpixel((x, y), BORDER)
                elif is_inner_border:
                    base.putpixel((x, y), BORDER_HI)
                else:
                    # Cosmic gradient background
                    t = (y + x * 0.3) / 55.0
                    r = int(BG_DEEP[0] + t * (BG_MID[0] - BG_DEEP[0]))
                    g = int(BG_DEEP[1] + t * (BG_MID[1] - BG_DEEP[1]))
                    b = int(BG_DEEP[2] + t * (BG_MID[2] - BG_DEEP[2]))
                    base.putpixel((x, y), (r, g, b, 255))

    # 2. Dimensional Rift tear in background (from top right to bottom center)
    rift_coords = [
        (38, 4), (36, 8), (37, 12), (34, 16), (35, 20), (32, 25), (30, 30), (28, 36), (26, 42)
    ]
    for i in range(len(rift_coords) - 1):
        x1, y1 = rift_coords[i]
        x2, y2 = rift_coords[i+1]
        steps = max(abs(x2 - x1), abs(y2 - y1))
        for s in range(steps + 1):
            rx = int(x1 + (x2 - x1) * (s / float(steps)))
            ry = int(y1 + (y2 - y1) * (s / float(steps)))
            if 0 <= rx < w and 0 <= ry < h and base.getpixel((rx, ry))[3] > 0:
                base.putpixel((rx, ry), RIFT_WHITE)
                for ox, oy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                    if 0 <= rx+ox < w and 0 <= ry+oy < h and base.getpixel((rx+ox, ry+oy))[3] > 0:
                        base.putpixel((rx+ox, ry+oy), RIFT_CYAN)
                for ox, oy in [(-2, 0), (2, 0), (0, -2), (0, 2)]:
                    if 0 <= rx+ox < w and 0 <= ry+oy < h and base.getpixel((rx+ox, ry+oy))[3] > 0:
                        base.putpixel((rx+ox, ry+oy), RIFT_VIOLET)

    # 3. Badass Dinosaur Head Profile (facing right, roaring)
    grid = [['.' for _ in range(w)] for _ in range(h)]

    # Neck: x=6..18, y=28..42
    for y in range(28, 43):
        for x in range(8, 20):
            grid[y][x] = 'D'
        grid[y][8] = 'H'

    # Glowing dorsal spines on back/neck: x=6..8
    spines = [(7, 30), (6, 31), (6, 32), (7, 35), (6, 36), (6, 37), (7, 40), (6, 41)]
    for sx, sy in spines:
        grid[sy][sx] = 'S'

    # Cranium / Crown: x=12..30, y=14..24
    for y in range(14, 25):
        for x in range(12, 30):
            grid[y][x] = 'B'
        grid[y][12] = 'H'

    # Upper Snout & Brow: x=24..40, y=16..24
    for y in range(16, 24):
        for x in range(28, 41):
            grid[y][x] = 'B'
        grid[16][x] = 'H' # Top snout highlight

    # Snout Tip / Nostril: x=39..42, y=18..23
    for y in range(18, 24):
        for x in range(39, 43):
            grid[y][x] = 'B'
    grid[19][39] = 'K' # Nostril

    # Open Roaring Maw / Jaw
    # Mouth cavity: x=25..39, y=24..28
    for y in range(24, 29):
        for x in range(25, 40):
            grid[y][x] = 'M'

    # Sharp Upper Teeth (hanging down into maw)
    for tx in [28, 31, 34, 37, 40]:
        grid[24][tx] = 'T'
        grid[25][tx] = 'T'

    # Lower Jaw: x=22..38, y=29..34
    for y in range(29, 34):
        for x in range(24, 38):
            grid[y][x] = 'B'
    # Lower Teeth (pointing up)
    for tx in [26, 29, 32, 35]:
        grid[28][tx] = 'T'

    # Under-jaw / Throat: x=18..26, y=28..36
    for y in range(28, 37):
        for x in range(18, 26):
            grid[y][x] = 'D'

    # Menacing Glowing Eye & Brow at x=25..27, y=18..20
    # Angry eye ridge / brow
    grid[17][24] = 'K'; grid[17][25] = 'K'; grid[17][26] = 'K'; grid[17][27] = 'K'
    # Glowing Eye
    grid[18][25] = 'E'; grid[18][26] = 'E'
    grid[19][25] = 'C'; grid[19][26] = 'E'

    # Render Dino Grid to Base Image
    dino_palette = {
        'B': DINO_BODY,
        'H': DINO_HI,
        'D': DINO_DARK,
        'K': (10, 10, 15, 255),
        'M': DINO_MOUTH,
        'T': DINO_TEETH,
        'E': RIFT_CYAN,
        'C': RIFT_WHITE,
        'S': RIFT_CYAN
    }

    # Dark silhouette outline for contrast
    for y in range(h):
        for x in range(w):
            if grid[y][x] != '.':
                base.putpixel((x, y), dino_palette[grid[y][x]])
            else:
                # Check for neighbor to add dark border outline
                has_dino = False
                for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and grid[ny][nx] != '.':
                        has_dino = True
                        break
                if has_dino and base.getpixel((x, y))[3] > 0:
                    base.putpixel((x, y), (10, 8, 18, 255))

    # Eye Glow Halo
    for ox, oy in [(-1, -1), (0, -1), (1, -1), (-1, 0), (1, 0), (-1, 1), (0, 1), (1, 1)]:
        ex, ey = 25 + ox, 18 + oy
        if grid[ey][ex] == 'B':
            base.putpixel((ex, ey), (45, 95, 120, 255))

    # Save 48x48 base
    base.save("assets/icons/android/icon_48.png")
    base.save("assets/icon.png")

    # Generate multi-resolution icons using high-quality resampling for larger sizes
    densities = {
        "icon_72.png": 72,
        "icon_96.png": 96,
        "icon_144.png": 144,
        "icon_192.png": 192,
        "icon_512.png": 512
    }
    for filename, sz in densities.items():
        # Scale with clean integer pixel enlargement
        scaled = base.resize((sz, sz), resample=Image.NEAREST)
        scaled.save(f"assets/icons/android/{filename}")

    print("Successfully generated badass Riftosaur app icons at all densities.")

if __name__ == "__main__":
    generate_icons()
