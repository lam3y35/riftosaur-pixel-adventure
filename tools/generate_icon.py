"""
Pro App Icon Generator for Riftosaur.
Creates a premium, eye-catching icon directly matching the reference visual style:
- Sky blue rounded squircle badge (#38bdf8 / #0284c7)
- The iconic pro charcoal dinosaur running
- The glowing blue ammonite fossil crest
- Clean white highlights and dark accent border
- Exported at 48, 72, 96, 144, 192, and 512 px
"""

import os
import math
from PIL import Image

def generate_pro_icon():
    os.makedirs("assets/icons/android", exist_ok=True)
    w, h = 48, 48
    base = Image.new("RGBA", (w, h), (0, 0, 0, 0))

    # Palette
    BORDER = (12, 74, 110, 255)        # Deep oceanic border
    SKY_TOP = (125, 211, 252, 255)     # Bright sky blue
    SKY_BOTTOM = (14, 165, 233, 255)   # Vibrant azure
    WHITE = (255, 255, 255, 255)
    DINO_BODY = (55, 65, 81, 255)      # Charcoal slate
    AMMONITE_LIGHT = (186, 230, 253, 255)
    AMMONITE_MID = (56, 189, 248, 255)
    AMMONITE_DARK = (3, 105, 161, 255)

    # 1. Rounded App Icon Squircle
    for y in range(h):
        for x in range(w):
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
                is_border = (dx >= 20.5 or dy >= 20.5)
                if is_border:
                    base.putpixel((x, y), BORDER)
                else:
                    t = y / float(h)
                    r = int(SKY_TOP[0] + t * (SKY_BOTTOM[0] - SKY_TOP[0]))
                    g = int(SKY_TOP[1] + t * (SKY_BOTTOM[1] - SKY_TOP[1]))
                    b = int(SKY_TOP[2] + t * (SKY_BOTTOM[2] - SKY_TOP[2]))
                    base.putpixel((x, y), (r, g, b, 255))

    # 2. Fluffy cloud in upper left (x=6..26, y=6..16)
    for cy in range(7, 15):
        for cx in range(7, 24):
            dx = (cx - 15) / 1.5
            dy = (cy - 11)
            if dx * dx + dy * dy <= 5 * 5:
                if base.getpixel((cx, cy))[3] > 0 and base.getpixel((cx, cy)) != BORDER:
                    base.putpixel((cx, cy), WHITE)

    # 3. Running Charcoal Dinosaur in Center (x=10..36, y=14..38)
    grid = [['.' for _ in range(w)] for _ in range(h)]

    # Head: x=24..37, y=14..23
    for y in range(14, 23):
        for x in range(24, 38):
            grid[y][x] = 'D'
    # Mouth notch
    for y in range(20, 22):
        for x in range(30, 38):
            grid[y][x] = '.'
    # Eye
    grid[16][27] = 'W'; grid[16][28] = 'W'
    grid[17][27] = 'W'; grid[17][28] = 'W'

    # Neck & Torso: x=17..29, y=21..32
    for y in range(21, 26):
        for x in range(21, 29):
            grid[y][x] = 'D'
    for y in range(24, 33):
        for x in range(16, 28):
            grid[y][x] = 'D'

    # Tail: starts at x=16, goes back up to x=11, y=20..25
    for y in range(25, 31):
        for x in range(14, 17):
            grid[y][x] = 'D'
    for y in range(22, 27):
        for x in range(12, 15):
            grid[y][x] = 'D'
    grid[20][11] = 'D'; grid[20][12] = 'D'; grid[21][11] = 'D'; grid[21][12] = 'D'

    # Little arm
    grid[25][28] = 'D'; grid[25][29] = 'D'
    grid[26][29] = 'D'

    # Running legs
    # Front leg forward
    grid[33][24] = 'D'; grid[33][25] = 'D'
    grid[34][25] = 'D'; grid[34][26] = 'D'
    grid[35][25] = 'D'; grid[35][26] = 'D'; grid[35][27] = 'D'
    # Back leg backward
    grid[33][17] = 'D'; grid[33][18] = 'D'
    grid[34][16] = 'D'; grid[34][17] = 'D'
    grid[35][15] = 'D'; grid[35][16] = 'D'

    # Render Dino to Base Image
    for y in range(h):
        for x in range(w):
            if grid[y][x] == 'D':
                base.putpixel((x, y), DINO_BODY)
            elif grid[y][x] == 'W':
                base.putpixel((x, y), WHITE)

    # 4. Glowing Blue Ammonite Fossil Badge in bottom-right corner (x=30..43, y=29..42)
    cx, cy = 36, 35
    for y in range(cy - 6, cy + 7):
        for x in range(cx - 6, cx + 7):
            dx = x - cx
            dy = y - cy
            dist = math.sqrt(dx * dx + dy * dy)
            if dist <= 6.0:
                angle = math.atan2(dy, dx)
                spiral_r = 2.0 + (angle + math.pi) / (2.0 * math.pi) * 3.5
                if dist <= 1.5:
                    base.putpixel((x, y), AMMONITE_DARK)
                elif abs(dist - spiral_r) <= 1.2:
                    base.putpixel((x, y), AMMONITE_LIGHT if (int(angle * 4)) % 2 == 0 else AMMONITE_MID)
                elif dist <= 5.0:
                    base.putpixel((x, y), AMMONITE_MID)
                else:
                    base.putpixel((x, y), AMMONITE_DARK)

    # Save 48x48 base
    base.save("assets/icons/android/icon_48.png")
    base.save("assets/icon.png")

    # Generate multi-resolution icons
    densities = {
        "icon_72.png": 72,
        "icon_96.png": 96,
        "icon_144.png": 144,
        "icon_192.png": 192,
        "icon_512.png": 512
    }
    for filename, sz in densities.items():
        scaled = base.resize((sz, sz), resample=Image.NEAREST)
        scaled.save(f"assets/icons/android/{filename}")

    print("Generated pro-grade Riftosaur app icon at all densities.")

if __name__ == "__main__":
    generate_pro_icon()
