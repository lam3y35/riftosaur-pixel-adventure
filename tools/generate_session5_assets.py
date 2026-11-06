"""
Generates pixel-art visual assets for Session 5 (Skills, Collectibles, Pickups, and FX).
"""
import os
from PIL import Image

PALETTE = {
    '.': (0, 0, 0, 0),
    '#': (16, 20, 32, 255),    # Obsidian Outline
    'w': (255, 255, 255, 255), # White
    'g': (34, 197, 94, 255),   # Emerald Green
    'G': (21, 128, 61, 255),   # Dark Green
    'c': (56, 189, 248, 255),  # Cyan
    'C': (14, 116, 144, 255),  # Dark Cyan
    'y': (250, 204, 21, 255),  # Yellow
    'Y': (202, 138, 4, 255),   # Dark Yellow / Amber
    'o': (251, 146, 60, 255),  # Orange
    'r': (239, 68, 68, 255),   # Crimson
    'R': (185, 28, 28, 255),   # Dark Red
    'p': (216, 180, 254, 255), # Light Purple
    'P': (147, 51, 234, 255),  # Purple
    'm': (244, 114, 182, 255), # Pink / Magenta
    'M': (190, 24, 93, 255),   # Deep Magenta
    's': (148, 163, 184, 255), # Steel Slate
    'S': (71, 85, 105, 255),   # Dark Slate
    'b': (120, 72, 36, 255),   # Wood Brown
    'B': (62, 39, 18, 255),    # Dark Wood
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

def create_bone_blade_icon():
    # 32x32 Bone Blade: prehistoric sharpened bone saber with blood-red wraps
    grid = [
        "................................",
        "................................",
        "............................##..",
        "..........................##ww#.",
        "........................##wwww#.",
        "......................##wwwwww#.",
        "....................##wwwwwww#..",
        "..................##wwwwwwww#...",
        "................##wwwwwwww##....",
        "..............##wwwwwwwww#......",
        "............##wwwwwwwwww#.......",
        "..........##wwwwwwwwwww#........",
        "........##wwwwwwwwwwww#.........",
        "......##wwwwwwwwwwwww#..........",
        "....##wwwwwwwwwwwwww#...........",
        "..##wwwwwwwwwwwwwww#............",
        ".#wwwwwwwwwwwwwwww#.............",
        ".#wwwwwwwwwwwwwww#..............",
        ".#wwwwwwwwwwwwww#...............",
        "..#wwwwww#rr#ww#................",
        "...#wwww#rrrr##.................",
        "....#ww#rrrr#...................",
        ".....##rrrr#....................",
        "......#rrr#.....................",
        ".......#rr#.....................",
        "........#rr#....................",
        ".........#rr#...................",
        "..........#BB#..................",
        "...........##...................",
        "................................",
        "................................",
        "................................"
    ]
    return grid_to_image(grid)

def create_boomerang_icon():
    # 32x32 Boomerang: tribal carved curved throwing club with glowing feathers
    grid = [
        "................................",
        "................................",
        ".....#######....................",
        "...##bbbbbbb##..................",
        "..#bbbbbbbbbbb#.................",
        ".#bbbb#####bbbb#................",
        ".#bbb#.....#bbb#................",
        "#bbb#.......#bbb#...............",
        "#bbb#........#bbb#..............",
        "#bbb#.........#bbb#.............",
        "#bbb#..........#bbb#............",
        "#bbb#...........#bbb#...........",
        ".#bbb#...........#bbb#..........",
        ".#bbbb#...........#bbb#.........",
        "..#bbbb#...........#bbb#........",
        "...#bbbb#...........#bbb#.......",
        "....#bbbb#...........#bbb#......",
        ".....#bbbb#...........#bbb#.....",
        "......#bbbb#...........#bbb#....",
        ".......#bbbb#...........#bbb#...",
        "........#bbbb#...........#bbb#..",
        ".........#bbbb#...........#bbb#.",
        "..........#bbbb#..........#bbb#.",
        "...........#bbbb#.........#bbb#.",
        "............#bbbb#########bbbb#.",
        ".............#bbbbbbbbbbbbbbb#..",
        "..............##bbbbbbbbbbb##...",
        "................#######yyyy#....",
        ".......................#yy#.....",
        "........................##......",
        "................................",
        "................................"
    ]
    return grid_to_image(grid)

def create_stone_shield_icon():
    # 32x32 Stone Shield: carved rune aegis with cyan energy core
    grid = [
        "................................",
        "................................",
        "....########################....",
        "...#ssssssssssssssssssssssss#...",
        "..#ssssssssssssssssssssssssss#..",
        ".#ssssssssssssssssssssssssssss#.",
        ".#sssss##################sssss#.",
        "#sssss#SSSSSSSSSSSSSSSSSS#sssss#",
        "#ssss#SSSSccccccccccccSSSS#ssss#",
        "#ssss#SSSccccccccccccccSSS#ssss#",
        "#ssss#SSccccccccccccccccSS#ssss#",
        "#ssss#SScccc####cc####ccSS#ssss#",
        "#ssss#SScccc####cc####ccSS#ssss#",
        "#ssss#SScccccccc##ccccccSS#ssss#",
        "#ssss#SScccccccc##ccccccSS#ssss#",
        "#ssss#SScccc###cccc###ccSS#ssss#",
        "#ssss#SSccccc########cccSS#ssss#",
        "#ssss#SScccccc######ccccSS#ssss#",
        "#ssss#SSSccccccccccccccSSS#ssss#",
        "#ssss#SSSSccccccccccccSSSS#ssss#",
        ".#ssss#SSSSSSSSSSSSSSSSS#sssss#.",
        ".#sssss##################sssss#.",
        "..#ssssssssssssssssssssssssss#..",
        "...#ssssssssssssssssssssssss#...",
        "....#ssssssssssssssssssssss#....",
        ".....#ssssssssssssssssssss#.....",
        "......#ssssssssssssssssss#......",
        ".......#ssssssssssssssss#.......",
        "........#ssssssssssssss#........",
        ".........#ssssssssssss#.........",
        "..........############..........",
        "................................"
    ]
    return grid_to_image(grid)

def create_ground_slam_icon():
    # 32x32 Ground Slam: heavy spiked maul striking ground creating seismic cracks
    grid = [
        "................................",
        "........############............",
        ".......#ssssssssssss#...........",
        "......#ssssssssssssss#..........",
        ".....#ssss#ssssss#ssss#.........",
        "....#ssss##ssssss##ssss#........",
        "...#ssss###ssssss###ssss#.......",
        "...#ssss###ssssss###ssss#.......",
        "...#ssss###ssssss###ssss#.......",
        "...#sssss##ssssss##sssss#.......",
        "...#ssssss#ssssss#ssssss#.......",
        "...#ssssssssssssssssssss#.......",
        "....#ssssssssssssssssss#........",
        ".....#ssssssssssssssss#.........",
        "......#######bbbb######.........",
        "............#bbbb#..............",
        "............#bbbb#..............",
        "............#bbbb#..............",
        "............#bbbb#..............",
        "............#bbbb#..............",
        "............#bbbb#..............",
        "............#bbbb#..............",
        "............#bbbb#..............",
        ".Y.y........#bbbb#........y.Y...",
        "YY.yy......#bbbbbb#......yy.YY..",
        "YYYYyyy...#bbbbbbbb#...yyyYYYY..",
        "YYYYYYYY##bbbbbbbbbb##YYYYYYYY..",
        "################################",
        "................................",
        "................................",
        "................................",
        "................................"
    ]
    return grid_to_image(grid)

def create_time_shard_icon():
    # 32x32 Time Shard: glowing chronos crystal with temporal rings
    grid = [
        "................................",
        "...............##...............",
        "..............#cc#..............",
        ".............#cccc#.............",
        "............#cccccc#............",
        "...........#cccccccc#...........",
        "..........#cwwccccwwc#..........",
        ".........#cwwwwccwwwwc#.........",
        "........#ccwwwwccwwwwcc#........",
        ".......#ccccwwwwwwwwcccc#.......",
        "......#ccccccwwwwwwcccccc#......",
        ".....#ccccccccwwwwcccccccc#.....",
        "....#ccccccccccwwcccccccccc#....",
        "...#cccccccccccccccccccccccc#...",
        "..#cccccccccccc##cccccccccccc#..",
        ".#cccccccccccc#CC#cccccccccccc#.",
        "#cccccccccccc#CCCC#cccccccccccc#",
        ".#cccccccccccc#CC#cccccccccccc#.",
        "..#cccccccccccc##cccccccccccc#..",
        "...#cccccccccccccccccccccccc#...",
        "....#ccccccccccwwcccccccccc#....",
        ".....#ccccccccwwwwcccccccc#.....",
        "......#ccccccwwwwwwcccccc#......",
        ".......#ccccwwwwwwwwcccc#.......",
        "........#ccwwwwccwwwwcc#........",
        ".........#cwwwwccwwwwc#.........",
        "..........#cwwccccwwc#..........",
        "...........#cccccccc#...........",
        "............#cccccc#............",
        ".............#cccc#.............",
        "..............#cc#..............",
        "...............##..............."
    ]
    return grid_to_image(grid)

def create_magnet_relic_icon():
    # 32x32 Magnet Relic: horseshoe lodestone with pulsing magnetic field
    grid = [
        "................................",
        "....######............######....",
        "...#rrrrrr#..........#cccccc#...",
        "..#rrrrrrrr#........#cccccccc#..",
        ".#rrrrrrrrrr#......#cccccccccc#.",
        ".#rrrr##rrrr#......#cccc##cccc#.",
        "#rrrr#..#rrrr#....#cccc#..#cccc#",
        "#rrrr#..#rrrr#....#cccc#..#cccc#",
        "#rrrr#..#rrrr#....#cccc#..#cccc#",
        "#rrrr#..#rrrr#....#cccc#..#cccc#",
        "#ssss#..#ssss#....#ssss#..#ssss#",
        "#ssss#..#ssss#....#ssss#..#ssss#",
        "#ssss#..#ssss#....#ssss#..#ssss#",
        "#ssss#..#ssss#....#ssss#..#ssss#",
        "#ssss#..#ssss#....#ssss#..#ssss#",
        "#ssss#..#ssss#....#ssss#..#ssss#",
        "#ssss#..#ssss#....#ssss#..#ssss#",
        "#ssss#...#ssss####ssss#...#ssss#",
        "#ssss#....#ssssssssss#....#ssss#",
        ".#ssss#....#ssssssss#....#ssss#.",
        ".#ssss#.....#ssssss#.....#ssss#.",
        "..#ssss#.....######.....#ssss#..",
        "..#sssss#..............#sssss#..",
        "...#sssss#............#sssss#...",
        "....#ssssss##########ssssss#....",
        ".....#ssssssssssssssssssss#.....",
        "......#ssssssssssssssssss#......",
        ".......#ssssssssssssssss#.......",
        "........################........",
        "................................",
        "................................",
        "................................"
    ]
    return grid_to_image(grid)

def create_air_dash_icon():
    # 32x32 Air Dash: aerodynamic wing booster with speed streak trails
    grid = [
        "................................",
        "................................",
        ".......................#####....",
        "....................###ccccc#...",
        ".................###cccccccc#...",
        "..............###ccccccccccc#...",
        "...........###cccccccccccccc#...",
        "........###ccccccccccccccccc#...",
        ".....###ccccccccccccccwwwwww#...",
        "..###cccccccccccccccccwwwwww#...",
        "#cccccccccccccccccccccwwwwww#...",
        ".#ccccccccccccccccccccwwwwww#...",
        "..#ccccccccccccccccccwwwwwww#...",
        "...###ccccccccccccccwwwwwwww#...",
        "......###ccccccccccwwwwwwwww#...",
        ".........###ccccccwwwwwwwwww#...",
        "..ww........###cccwwwwwwwwww#...",
        "...wwww........###wwwwwwwwww#...",
        "....wwwwww........##########....",
        ".....wwwwwwww...................",
        ".......wwwwwwww.................",
        ".........wwwwwwww...............",
        "...........wwwwwwww.............",
        ".............wwwwwwww...........",
        "...............wwwwwwww.........",
        ".................wwwwwwww.......",
        "...................wwwwwwww.....",
        ".....................wwwwww.....",
        ".......................wwww.....",
        ".........................ww.....",
        "................................",
        "................................"
    ]
    return grid_to_image(grid)

def create_bounce_power_icon():
    # 32x32 Bounce Power: coiled spring coil with launch aura stars
    grid = [
        "................................",
        "................................",
        ".............######.............",
        "...........##yyyyyy##...........",
        "..........#yyyyyyyyyy#..........",
        ".........#yyyyyyyyyyyy#.........",
        "........#yyy###yy###yyy#........",
        "........#yy#...##...#yy#........",
        "........#yy#........#yy#........",
        "........#yy#...##...#yy#........",
        "........#yyy###yy###yyy#........",
        ".........#yyyyyyyyyyyy#.........",
        "..........#yyyyyyyyyy#..........",
        "...........##yyyyyy##...........",
        ".............######.............",
        "..........############..........",
        ".........#kkkkkkkkkkkk#.........",
        "........#kkk########kkk#........",
        ".......#kkk#........#kkk#.......",
        "......#kkk#..........#kkk#......",
        ".....#kkk#............#kkk#.....",
        "......#kkk#..........#kkk#......",
        ".......#kkk#........#kkk#.......",
        "........#kkk########kkk#........",
        ".........#kkkkkkkkkkkk#.........",
        "..........############..........",
        "................................",
        "....Y..y................y..Y....",
        "...YY..yy..............yy..YY...",
        "....Y..y................y..Y....",
        "................................",
        "................................"
    ]
    return grid_to_image(grid)

def create_collectible_gem():
    # 16x16 glowing Amber Fossil Gem
    grid = [
        "......####......",
        "....##YYYY##....",
        "...#YYYYyyyy#...",
        "..#YYYYyyyyyy#..",
        ".#YYYYyyyywwww#.",
        ".#YYYyyyywwwww#.",
        "#YYYyyyyyywwww##",
        "#YYYyyyyyywwww##",
        "#YYYyyyyyywwww##",
        "#YYYyyyyyywwww##",
        ".#YYYyyyywwwww#.",
        ".#YYYYyyyywwww#.",
        "..#YYYYyyyyyy#..",
        "...#YYYYyyyy#...",
        "....##YYYY##....",
        "......####......"
    ]
    return grid_to_image(grid)

def create_pickup_skill_orb():
    # 20x20 glowing Rift Orb
    grid = [
        ".......######.......",
        ".....##PPPPPP##.....",
        "....#PPPppppppP#....",
        "...#PPppppwwpppP#...",
        "..#PPpppwwwwwwppP#..",
        ".#PPpppwwwwwwwwppP#.",
        ".#PpppwwwwwwwwwwpP#.",
        "#PpppwwwwwwwwwwwwpP#",
        "#PpppwwwwwwwwwwwwpP#",
        "#PpppwwwwwwwwwwwwpP#",
        "#PpppwwwwwwwwwwwwpP#",
        "#PpppwwwwwwwwwwwwpP#",
        "#PpppwwwwwwwwwwwwpP#",
        ".#PpppwwwwwwwwwwpP#.",
        ".#PPpppwwwwwwwwppP#.",
        "..#PPpppwwwwwwppP#..",
        "...#PPppppwwpppP#...",
        "....#PPPppppppP#....",
        ".....##PPPPPP##.....",
        ".......######......."
    ]
    return grid_to_image(grid)

def create_pterodactyl_sprite():
    # 32x24 Airborne flying pterodactyl hazard
    grid = [
        "................................",
        "................................",
        "...................#####........",
        ".................##RRRRR##......",
        "...............##RRRRrrrrr##....",
        ".............##RRRRrrrrrrrre#...",
        "...........##RRRRrrrrrrrrrrre#..",
        ".........##RRRRrrrrrrrrrrrrr#...",
        ".......##RRRRrrrrrrrrrrrrrr#....",
        ".....##RRRRrrrrrrrrrrrrrr##.....",
        "..###RRRRrrrrrrrrrrrrrr##.......",
        "#RRRRRRrrrrrrrrrrrrrr##.........",
        ".##RRRRRRrrrrrrrrrr##...........",
        "...##RRRRRRrrrrrr##.............",
        ".....##RRRRRRrr##...............",
        ".......##RRRR##.................",
        ".........####...................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................"
    ]
    return grid_to_image(grid)

def create_crawler_sprite():
    # 24x16 Ground crawler insect / spike beetle
    grid = [
        "........................",
        ".........######.........",
        ".......##ssssss##.......",
        "......#ssssssssss#......",
        ".....#ss#ssssss#ss#.....",
        "....#ss#re#ss#er#ss#....",
        "...#ssss##ssss##ssss#...",
        "...#ssssssssssssssss#...",
        "..#ssssssssssssssssss#..",
        ".#ssssssssssssssssssss#.",
        "#ssssssssssssssssssssss#",
        "##ssssssssssssssssssss##",
        ".#ss##ss##ss##ss##ss##..",
        "..##..##..##..##..##....",
        "........................",
        "........................"
    ]
    return grid_to_image(grid)

def main():
    os.makedirs("assets/sprites", exist_ok=True)
    assets = {
        "skill_bone_blade.png": create_bone_blade_icon(),
        "skill_boomerang.png": create_boomerang_icon(),
        "skill_stone_shield.png": create_stone_shield_icon(),
        "skill_ground_slam.png": create_ground_slam_icon(),
        "skill_time_shard.png": create_time_shard_icon(),
        "skill_magnet_relic.png": create_magnet_relic_icon(),
        "skill_air_dash.png": create_air_dash_icon(),
        "skill_bounce_power.png": create_bounce_power_icon(),
        "collectible_gem.png": create_collectible_gem(),
        "pickup_skill_orb.png": create_pickup_skill_orb(),
        "obstacle_pterodactyl.png": create_pterodactyl_sprite(),
        "obstacle_crawler.png": create_crawler_sprite(),
    }
    for filename, img in assets.items():
        path = os.path.join("assets/sprites", filename)
        img.save(path)
        print(f"Generated {path} ({img.size[0]}x{img.size[1]})")

if __name__ == "__main__":
    main()
