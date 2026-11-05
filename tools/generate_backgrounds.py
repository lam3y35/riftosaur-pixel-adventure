"""
Background generator for Riftosaur.
Generates multi-layer parallax pixel art backgrounds:
- bg_sky: Deep cosmic/prehistoric twilight gradient (480x270)
- bg_mountains: Distant volcanic & rift mountains silhouette (480x160)
- bg_hills: Midground prehistoric crags & rift monoliths (480x120)
"""

import math
from PIL import Image

def generate_backgrounds():
    width = 480
    height = 270

    # 1. Sky Gradient (480x270)
    # Deep night purple/navy at top (16, 12, 36) -> Horizon amber/crimson twilight (72, 30, 68) -> (112, 48, 76)
    sky = Image.new("RGBA", (width, height))
    for y in range(height):
        t = y / float(height)
        # 3-stop gradient
        if t < 0.6:
            st = t / 0.6
            r = int(16 + st * (72 - 16))
            g = int(12 + st * (30 - 12))
            b = int(36 + st * (68 - 36))
        else:
            st = (t - 0.6) / 0.4
            r = int(72 + st * (120 - 72))
            g = int(30 + st * (55 - 30))
            b = int(68 + st * (82 - 68))
        for x in range(width):
            sky.putpixel((x, y), (r, g, b, 255))

    # Add subtle distant stars and a faint dimensional rift crack in the upper sky
    # Stars
    star_positions = [
        (45, 25), (82, 45), (140, 18), (195, 38), (260, 22), (310, 50),
        (375, 15), (420, 32), (460, 48), (25, 75), (160, 68), (340, 72)
    ]
    for sx, sy in star_positions:
        sky.putpixel((sx, sy), (230, 220, 255, 220))
        # subtle cross glow
        if 0 < sx < width - 1 and 0 < sy < height - 1:
            sky.putpixel((sx+1, sy), (200, 180, 240, 120))
            sky.putpixel((sx-1, sy), (200, 180, 240, 120))
            sky.putpixel((sx, sy+1), (200, 180, 240, 120))
            sky.putpixel((sx, sy-1), (200, 180, 240, 120))

    # Dimensional Rift in upper right sky (x=320..380, y=10..60)
    rift_points = [
        (330, 10), (336, 18), (345, 28), (342, 38), (355, 48), (368, 62)
    ]
    for i in range(len(rift_points) - 1):
        x1, y1 = rift_points[i]
        x2, y2 = rift_points[i+1]
        steps = max(abs(x2 - x1), abs(y2 - y1))
        for s in range(steps + 1):
            px = int(x1 + (x2 - x1) * (s / float(steps)))
            py = int(y1 + (y2 - y1) * (s / float(steps)))
            sky.putpixel((px, py), (245, 240, 255, 255)) # Pure rift core
            for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                sky.putpixel((px + dx, py + dy), (168, 85, 247, 200)) # Violet glow
            for dx, dy in [(-2, 0), (2, 0), (0, -2), (0, 2)]:
                sky.putpixel((px + dx, py + dy), (34, 211, 238, 120)) # Cyan edge

    sky.save("assets/sprites/bg_sky.png")

    # 2. Distant Mountains (480x160 px, transparent background)
    # Jagged peaks with volcanic silhouette and purple rim highlights
    mountains = Image.new("RGBA", (width, 160), (0, 0, 0, 0))
    # Height profile using sine harmonics + jagged noise
    m_color = (42, 28, 58, 255) # Deep plum silhouette
    m_highlight = (88, 52, 105, 255) # Upper rim light

    # Baseline peak height array
    peaks = []
    for x in range(width):
        nx = x / float(width) * 4.0 * math.pi
        h = 50 + 25 * math.sin(nx) + 15 * math.sin(nx * 2.5 + 1.2) + 8 * math.sin(nx * 5.0)
        # Ensure seamless wrap at boundaries x=0 and x=480
        wrap_blend = math.sin((x / float(width)) * math.pi)
        peaks.append(int(h * wrap_blend + 45 * (1.0 - wrap_blend)))

    for x in range(width):
        peak_y = 160 - peaks[x]
        for y in range(peak_y, 160):
            if y == peak_y or y == peak_y + 1:
                mountains.putpixel((x, y), m_highlight)
            else:
                mountains.putpixel((x, y), m_color)

    mountains.save("assets/sprites/bg_mountains.png")

    # 3. Midground Crags & Prehistoric Monoliths (480x120 px)
    hills = Image.new("RGBA", (width, 120), (0, 0, 0, 0))
    h_color = (32, 22, 44, 255) # Darker rock tone
    h_highlight = (62, 44, 80, 255) # Edge rim

    for x in range(width):
        nx = x / float(width) * 6.0 * math.pi
        h = 35 + 18 * math.cos(nx) + 10 * math.sin(nx * 2.1)
        wrap_blend = math.sin((x / float(width)) * math.pi)
        hill_h = int(h * wrap_blend + 32 * (1.0 - wrap_blend))
        peak_y = 120 - hill_h
        for y in range(peak_y, 120):
            if y == peak_y or y == peak_y + 1:
                hills.putpixel((x, y), h_highlight)
            else:
                hills.putpixel((x, y), h_color)

    # Add a few ancient stone monoliths / rift pillars rising up
    pillars = [(75, 55), (180, 65), (290, 50), (410, 60)]
    for px, p_height in pillars:
        for py in range(120 - p_height, 120):
            for dx in range(-4, 5):
                cur_x = (px + dx) % width
                if abs(dx) == 4 or py == (120 - p_height):
                    hills.putpixel((cur_x, py), (147, 51, 234, 255)) # Glowing ancient rift glyph
                else:
                    hills.putpixel((cur_x, py), h_color)

    hills.save("assets/sprites/bg_hills.png")

    print("Generated bg_sky.png (480x270), bg_mountains.png (480x160), bg_hills.png (480x120).")

if __name__ == "__main__":
    generate_backgrounds()
