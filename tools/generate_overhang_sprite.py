import math
from PIL import Image

def generate_overhang_arch():
    width = 32
    height = 240
    img = Image.new("RGBA", (width, height), (0, 0, 0, 0))

    # Palette matching reference aesthetic
    OUTLINE = (28, 26, 32, 255)
    STONE_DARK = (52, 48, 58, 255)
    STONE_MID = (82, 78, 92, 255)
    STONE_LIGHT = (118, 112, 130, 255)
    STONE_HIGHLIGHT = (155, 150, 168, 255)
    MOSS_DARK = (42, 75, 32, 255)
    MOSS_MID = (65, 115, 48, 255)
    MOSS_LIGHT = (95, 155, 68, 255)
    VINE_DARK = (35, 55, 28, 255)
    VINE_MID = (58, 95, 42, 255)
    VINE_LIGHT = (88, 140, 62, 255)

    # 1. Solid Stone Pillar Body from y = 0 to y = 220
    for y in range(220):
        # Slight organic tapering on edges
        edge_indent_l = int(1 + math.sin(y * 0.12) * 0.8)
        edge_indent_r = int(1 + math.cos(y * 0.15) * 0.8)
        
        for x in range(edge_indent_l, width - edge_indent_r):
            # Base stone noise / strata
            pattern = (x * 7 + y * 13) % 17
            color = STONE_MID
            if pattern in (0, 1):
                color = STONE_LIGHT
            elif pattern in (2, 3):
                color = STONE_DARK
            elif pattern == 4 and x in (6, 18, 24):
                color = STONE_HIGHLIGHT
            
            # Vertical strata fissure lines
            if x in (8, 20) and (y % 14) not in (0, 1):
                color = STONE_DARK
            if x in (9, 21) and (y % 14) not in (0, 1):
                color = STONE_HIGHLIGHT

            # Moss shelves every ~35 pixels
            shelf_y = y % 38
            if shelf_y in (12, 13) and 4 <= x <= 27:
                color = MOSS_MID if (x + y) % 3 != 0 else MOSS_LIGHT
            elif shelf_y == 14 and 5 <= x <= 26:
                color = MOSS_DARK

            img.putpixel((x, y), color)

        # Left and right dark crisp outlines
        img.putpixel((edge_indent_l, y), OUTLINE)
        img.putpixel((width - 1 - edge_indent_r, y), OUTLINE)

    # 2. Archway underside curve from y = 220 to y = 232
    # Arch peaks at center (x=16) and arches slightly down towards edges
    for x in range(width):
        arch_cut = int(224 - 4.0 * math.cos((x - 16) / 16.0 * math.pi * 0.5))
        for y in range(220, arch_cut):
            img.putpixel((x, y), STONE_MID if (x + y) % 2 == 0 else STONE_DARK)
        if arch_cut < height:
            img.putpixel((x, arch_cut - 1), OUTLINE)

    # 3. Hanging prehistoric jungle vines and tendrils dangling down to y = 238
    # Leaves bottom 14px (y = 226..240) strictly clear for sliding dino
    vines = [
        (4, 222, 6), (7, 221, 10), (11, 220, 8), (14, 220, 12),
        (17, 220, 11), (20, 221, 7), (24, 222, 9), (27, 223, 5)
    ]
    for vx, vy_start, vlen in vines:
        for offset in range(vlen):
            vy = vy_start + offset
            if vy < 238: # strictly above crawlspace
                vcolor = VINE_MID if offset % 2 == 0 else VINE_DARK
                if offset == vlen - 1:
                    vcolor = VINE_LIGHT # vine leaf tip
                img.putpixel((vx, vy), vcolor)
                # occasional leaf side pixel
                if offset in (2, 5) and vx + 1 < width - 2:
                    img.putpixel((vx + 1, vy), VINE_LIGHT)

    # Top cap outline (for clean rendering off-screen)
    for x in range(width):
        if img.getpixel((x, 0))[3] > 0:
            img.putpixel((x, 0), OUTLINE)

    img.save("assets/sprites/obstacle_high.png")
    print("Generated 32x240 prehistoric stone archway obstacle_high.png successfully.")

if __name__ == "__main__":
    generate_overhang_arch()
