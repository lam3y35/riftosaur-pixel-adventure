import math
from PIL import Image


def generate_overhang_arch():
    width = 32
    height = 56
    img = Image.new("RGBA", (width, height), (0, 0, 0, 0))

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

    # Floating mossy stone arch beam (y = 2..38) so the upper sky is open for flight
    for y in range(2, 38):
        edge_indent_l = 2 if y in (2, 3, 36, 37) else 1
        edge_indent_r = 2 if y in (2, 3, 36, 37) else 1

        for x in range(edge_indent_l, width - edge_indent_r):
            pattern = (x * 7 + y * 13) % 17
            color = STONE_MID
            if y <= 5:
                color = MOSS_LIGHT if (x + y) % 3 == 0 else MOSS_MID
            elif y == 6:
                color = MOSS_DARK
            else:
                if pattern in (0, 1):
                    color = STONE_LIGHT
                elif pattern in (2, 3):
                    color = STONE_DARK
                elif pattern == 4 and x in (6, 18, 24):
                    color = STONE_HIGHLIGHT
                if x in (8, 20) and (y % 10) not in (0, 1):
                    color = STONE_DARK
                if x in (9, 21) and (y % 10) not in (0, 1):
                    color = STONE_HIGHLIGHT

            img.putpixel((x, y), color)

        img.putpixel((edge_indent_l, y), OUTLINE)
        img.putpixel((width - 1 - edge_indent_r, y), OUTLINE)

    # Top outline cap
    for x in range(2, width - 2):
        img.putpixel((x, 2), OUTLINE)

    # Archway underside curve from y = 38 to y = 48
    for x in range(1, width - 1):
        arch_cut = int(42 - 4.0 * math.cos((x - 16) / 16.0 * math.pi * 0.5))
        for y in range(38, arch_cut):
            img.putpixel((x, y), STONE_MID if (x + y) % 2 == 0 else STONE_DARK)
        img.putpixel((x, arch_cut - 1), OUTLINE)

    # Short hanging vines above the crawlspace (y = 40..54)
    vines = [
        (4, 40, 6), (7, 39, 9), (11, 38, 7), (14, 38, 10),
        (17, 38, 9), (20, 39, 6), (24, 40, 8), (27, 41, 5)
    ]
    for vx, vy_start, vlen in vines:
        for offset in range(vlen):
            vy = vy_start + offset
            if vy < height - 1:
                vcolor = VINE_MID if offset % 2 == 0 else VINE_DARK
                if offset == vlen - 1:
                    vcolor = VINE_LIGHT
                img.putpixel((vx, vy), vcolor)
                if offset in (2, 5) and vx + 1 < width - 2:
                    img.putpixel((vx + 1, vy), VINE_LIGHT)

    img.save("assets/sprites/obstacle_high.png")
    print("Generated 32x56 floating stone archway obstacle_high.png successfully.")


if __name__ == "__main__":
    generate_overhang_arch()
