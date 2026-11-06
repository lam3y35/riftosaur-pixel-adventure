"""
Generates pixel-art visual assets for Session 4 (Vertical movement, platforms, spring objects).
"""
import os
from PIL import Image

PALETTE = {
    '.': (0, 0, 0, 0),
    '#': (16, 20, 32, 255),    # Outline / Dark Obsidian
    # Stone Platform
    'S': (45, 55, 75, 255),    # Dark Stone
    's': (75, 88, 115, 255),   # Mid Stone
    'l': (120, 138, 175, 255), # Stone Highlight
    'c': (56, 189, 248, 255),  # Cyan Rune Glow
    'C': (14, 116, 144, 255),  # Dark Cyan
    # One-Way Wood Platform
    'w': (120, 72, 36, 255),   # Dark Wood
    'W': (168, 102, 52, 255),  # Mid Wood
    'h': (212, 148, 88, 255),  # Wood Highlight
    'v': (34, 197, 94, 255),   # Moss / Vine Green
    'V': (21, 128, 61, 255),   # Dark Moss
    'r': (217, 119, 6, 255),   # Rope Amber
    # Bouncing Mushroom
    'm': (236, 72, 153, 255),  # Neon Pink / Magenta
    'M': (168, 24, 96, 255),   # Deep Purple/Magenta
    'y': (254, 240, 138, 255), # Mushroom Spots Yellow
    't': (226, 232, 240, 255), # Mushroom Stem White
    'T': (148, 163, 184, 255), # Mushroom Stem Shadow
    # Spring Stump
    'b': (101, 67, 33, 255),   # Bark Brown
    'B': (62, 39, 18, 255),    # Bark Shadow
    'k': (148, 163, 184, 255), # Coiled Spring Metal
    'K': (71, 85, 105, 255),   # Spring Shadow
    # Launchpad
    'g': (234, 179, 8, 255),   # Gold Accent
    'G': (161, 98, 7, 255),    # Dark Gold
    # Wind Vent
    'a': (255, 255, 255, 220), # Wind Swirl
    'A': (186, 230, 253, 180), # Cyan Breeze
    'f': (51, 65, 85, 255),    # Fissure Rock
}

def grid_to_image(grid):
    height = len(grid)
    width = len(grid[0])
    img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    pixels = img.load()
    for y in range(height):
        for x in range(width):
            ch = grid[y][x]
            pixels[x, y] = PALETTE.get(ch, (0, 0, 0, 0))
    return img

def create_solid_platform():
    # 48 x 16 solid stone slab with glowing cyan rune fissures
    w, h = 48, 16
    grid = []
    # Row 0: Top highlight edge
    grid.append('#' + 'l' * 46 + '#')
    # Row 1: Surface
    grid.append('#' + 's' * 20 + 'c' * 2 + 's' * 24 + '#')
    # Row 2: Rock layer with fissure
    grid.append('#' + 's' * 19 + 'c' * 3 + 's' * 24 + '#')
    # Row 3: Rock layer
    grid.append('#' + 's' * 18 + 'C' * 2 + 's' * 10 + 'c' * 2 + 's' * 14 + '#')
    # Row 4-10: Main body stone textures
    for row in range(7):
        line = '#'
        for col in range(46):
            if (row == 2 and col in [15, 16, 30]) or (row == 4 and col in [16, 28, 29]):
                line += 'c'
            elif (row + col) % 7 == 0:
                line += 'S'
            elif (row * 3 + col) % 11 == 0:
                line += 'l'
            else:
                line += 's'
        line += '#'
        grid.append(line)
    # Row 11-14: Lower darker stone
    for row in range(4):
        line = '#'
        for col in range(46):
            if (row + col) % 3 == 0:
                line += 'S'
            else:
                line += 's'
        line += '#'
        grid.append(line)
    # Row 15: Bottom dark outline
    grid.append('#' * 48)
    return grid_to_image(grid)

def create_oneway_platform():
    # 48 x 12 wooden beam with ropes and hanging vines (clearly pass-through)
    w, h = 48, 12
    grid = []
    # Row 0: Top edge with rope wraps and wood grain
    row0 = '#r' + 'h' * 18 + 'rr' + 'h' * 24 + 'r#'
    grid.append(row0)
    # Row 1: Upper plank
    row1 = '#r' + 'W' * 18 + 'rr' + 'W' * 24 + 'r#'
    grid.append(row1)
    # Row 2: Mid plank
    row2 = '#r' + 'w' * 8 + 'W' * 10 + 'rr' + 'w' * 12 + 'W' * 12 + 'r#'
    grid.append(row2)
    # Row 3: Lower plank
    row3 = '#r' + 'w' * 18 + 'rr' + 'w' * 24 + 'r#'
    grid.append(row3)
    # Row 4: Bottom plank edge
    row4 = '##' + '#' * 18 + '##' + '#' * 24 + '##'
    grid.append(row4)
    # Rows 5-11: Hanging vines and rope ends
    for r in range(7):
        line = ['.'] * 48
        # Rope knots
        if r < 3:
            line[1] = 'r'
            line[20] = 'r'
            line[21] = 'r'
            line[46] = 'r'
        # Hanging vines
        if r < 5:
            line[8] = 'v'
            line[9] = 'V'
            line[35] = 'v'
        if r < 6:
            line[8] = 'V'
            line[36] = 'v'
        if r < 4:
            line[28] = 'v'
        grid.append("".join(line))
    return grid_to_image(grid)

def create_boost_mushroom():
    # 24 x 24 springy neon mushroom
    grid = [
        "........########........",
        ".....###mmmmmmmm###.....",
        "....#mmmmmyyyymmmmm#....",
        "...#mmmmyyyyyyyymmmm#...",
        "..#mmmyyyyyyyyymmmmmm#..",
        ".#mmmyyyyyyyymmmmmmmmm#.",
        ".#mmmmmyyyymmmmmmyyyym#.",
        "#mmmmmmmmmmmmmmmyyyyymm#",
        "#mmmmmmmmmmmmmmmyyyyymm#",
        "#MMMMMMMMMMMMMMMMMMMMMM#",
        "##MMMMMMMMMMMMMMMMMMMM##",
        "..#wwwwwwwwwwwwwwwwww#..",
        "...##################...",
        "........#tttttt#........",
        "........#tttttt#........",
        "........#ttTTtt#........",
        "........#ttTTtt#........",
        "........#ttTTtt#........",
        ".......#tttTTttt#.......",
        ".......#tttTTttt#.......",
        "......#ttttTTtttt#......",
        ".....#vvvvvvvvvvvv#.....",
        "....#VVVVVVVVVVVVVV#....",
        "....################...."
    ]
    return grid_to_image(grid)

def create_boost_stump():
    # 24 x 24 mechanical spring-loaded stump
    grid = [
        "....################....",
        "....#kkkkkkkkkkkkkk#....",
        "....#KKKKKKKKKKKKKK#....",
        "....################....",
        "........#kkkkkk#........",
        "........#KKKKKK#........",
        ".........#kkkk#.........",
        "........#kkkkkk#........",
        "........#KKKKKK#........",
        ".........#kkkk#.........",
        "...##################...",
        "..#bbbbbbbbbbbbbbbbbb#..",
        ".#bbbbbbbbvvbbbbbbbbbb#.",
        ".#bbbbbbbbvvbbbbbbbbbb#.",
        "#bbbbbbbbbbbbbbbbbbbbbb#",
        "#bbbbBBbbbbbbbbBBbbbbbb#",
        "#bbbbBBbbbbbbbbBBbbbbbb#",
        "#bbbbBBbbbbbbbbBBbbbbbb#",
        "#bbbbBBbbbbbbbbBBbbbbbb#",
        "#BBBBBBBBBBBBBBBBBBBBBB#",
        "#BBBBBBBBBBBBBBBBBBBBBB#",
        ".#BBBBBBBBBBBBBBBBBBBB#.",
        "..#BBBBBBBBBBBBBBBBBB#..",
        "...##################..."
    ]
    return grid_to_image(grid)

def create_boost_launchpad():
    # 32 x 16 ancient stone launch pad with glowing glyphs
    grid = [
        "....########################....",
        "...#gggggggggggggggggggggggg#...",
        "..#gccccccccccccccccccccccccg#..",
        ".#gccccccccccccccccccccccccccg#.",
        "#gcccccc##cccccc##ccccccccccccg#",
        "#gccccc####cccc####cccccccccccg#",
        "#gcccc######cc######ccccccccccg#",
        "#gcccc######cc######ccccccccccg#",
        "#gccccc####cccc####cccccccccccg#",
        "#gcccccc##cccccc##ccccccccccccg#",
        "#GGGGGGGGGGGGGGGGGGGGGGGGGGGGGG#",
        "#SSSSSSSSSSSSSSSSSSSSSSSSSSSSSS#",
        "#ssssssssssssssssssssssssssssss#",
        "#ssssssssssssssssssssssssssssss#",
        "#SSSSSSSSSSSSSSSSSSSSSSSSSSSSSS#",
        "################################"
    ]
    return grid_to_image(grid)

def create_boost_wind_vent():
    # 24 x 32 geothermal wind fissure with swirling air currents
    grid = [
        "....AA............AA....",
        "...aaaa..........aaaa...",
        "....AA............AA....",
        "........AAAAAAA.........",
        ".......aaaaaaaaa........",
        "........AAAAAAA.........",
        ".....AA..........AA.....",
        "....aaaa........aaaa....",
        ".....AA..........AA.....",
        ".........AAAAA..........",
        "........aaaaaaa.........",
        ".........AAAAA..........",
        "....AA............AA....",
        "...aaaa..........aaaa...",
        "....AA............AA....",
        "........AAAAAAA.........",
        ".......aaaaaaaaa........",
        "........AAAAAAA.........",
        "....#ffffffffffffff#....",
        "...#ffffffffffffffff#...",
        "..#ffffffffffffffffff#..",
        ".#ffffffffffffffffffff#.",
        "#ffffffffffffffffffffff#",
        "#ffff###ffffffff###ffff#",
        "#fff#####ffffff#####fff#",
        "#fff#####ffffff#####fff#",
        "#ffff###ffffffff###ffff#",
        "#ffffffffffffffffffffff#",
        "#ffffffffffffffffffffff#",
        ".#ffffffffffffffffffff#.",
        "..#ffffffffffffffffff#..",
        "...##################..."
    ]
    return grid_to_image(grid)

def main():
    os.makedirs("assets/sprites", exist_ok=True)
    assets = {
        "platform_solid.png": create_solid_platform(),
        "platform_oneway.png": create_oneway_platform(),
        "boost_mushroom.png": create_boost_mushroom(),
        "boost_stump.png": create_boost_stump(),
        "boost_launchpad.png": create_boost_launchpad(),
        "boost_wind_vent.png": create_boost_wind_vent(),
    }
    for filename, img in assets.items():
        path = os.path.join("assets/sprites", filename)
        img.save(path)
        print(f"Generated {path} ({img.size[0]}x{img.size[1]})")

if __name__ == "__main__":
    main()
