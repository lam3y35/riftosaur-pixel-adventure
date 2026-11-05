"""
Sprite generator for Riftosaur.
Generates pixel-perfect 32x32 dinosaur animation frames, dust effects, tiles, and test obstacles.
Saves human-readable source maps to assets/sources/ and compiled PNGs to assets/sprites/.
"""

import os
from PIL import Image

PALETTE = {
    '.': (0, 0, 0, 0),         # Transparent
    '#': (24, 24, 27, 255),    # Outline / Dark slate
    'g': (34, 197, 94, 255),   # Body Green (primary)
    'G': (21, 128, 61, 255),   # Shadow Green
    'l': (134, 239, 172, 255), # Belly / Light Green
    'w': (255, 255, 255, 255), # Eye white / teeth
    'e': (24, 24, 27, 255),    # Eye pupil
    'r': (239, 68, 68, 255),   # Red (hurt/mouth)
    'd': (161, 161, 170, 255), # Dust light grey
    'D': (82, 82, 91, 255),    # Dust dark grey
    's': (180, 83, 9, 255),    # Ground sand/rock
    'S': (120, 53, 15, 255),   # Ground shadow
    'o': (217, 119, 6, 255),   # Ground highlight
}

def grid_to_image(grid, cell_size=32):
    height = len(grid)
    width = len(grid[0])
    img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    pixels = img.load()
    for y in range(height):
        for x in range(width):
            char = grid[y][x]
            pixels[x, y] = PALETTE.get(char, (0, 0, 0, 0))
    return img

def create_dino_frame(pose="idle", leg_offset=0, mouth_open=False, eye_state="normal", duck=False, hurt=False, dead=False):
    # 32x32 grid initialized with '.'
    grid = [['.' for _ in range(32)] for _ in range(32)]

    if duck:
        # Lower profile for sliding/ducking: height ~16px
        # Head lower at y=16..24, body elongated y=18..27
        # Tail: x=2..12, y=19..23
        for y in range(20, 23):
            for x in range(3, 13):
                grid[y][x] = 'g'
        # Body: x=11..21, y=18..26
        for y in range(18, 26):
            for x in range(11, 22):
                grid[y][x] = 'g'
        # Head: x=19..28, y=15..23
        for y in range(15, 23):
            for x in range(19, 28):
                grid[y][x] = 'g'
        # Belly
        for x in range(13, 21):
            grid[25][x] = 'l'
        # Eye
        grid[17][24] = 'w'
        grid[17][25] = 'e'
        # Legs horizontal back & front
        grid[26][12] = 'G'
        grid[26][13] = 'G'
        grid[26][19] = 'G'
        grid[26][20] = 'G'

    elif dead:
        # Knocked over / sideways silhouette
        for y in range(20, 28):
            for x in range(6, 26):
                grid[y][x] = 'g'
        # Head fallen
        for y in range(21, 28):
            for x in range(22, 29):
                grid[y][x] = 'g'
        # Eye is an X
        grid[23][25] = 'r'
        grid[24][26] = 'r'
        grid[24][25] = 'r'
        # Legs up
        grid[18][12] = 'G'
        grid[19][12] = 'G'
        grid[17][18] = 'G'
        grid[18][18] = 'G'

    else:
        # Standard standing/running/jumping dinosaur (side-facing)
        # Tail: starts at body x=8, curves up to x=2, y=14..18
        grid[16][2] = 'g'; grid[16][3] = 'g'
        grid[15][4] = 'g'; grid[16][4] = 'g'
        grid[15][5] = 'g'; grid[16][5] = 'g'
        grid[14][6] = 'g'; grid[15][6] = 'g'; grid[16][6] = 'g'
        grid[14][7] = 'g'; grid[15][7] = 'g'; grid[16][7] = 'g'

        # Main Body: x=8..18, y=12..22
        for y in range(12, 23):
            for x in range(8, 19):
                grid[y][x] = 'g'

        # Light belly: x=12..18, y=17..22
        for y in range(17, 23):
            for x in range(12, 18):
                grid[y][x] = 'l'

        # Neck: x=14..20, y=9..12
        for y in range(9, 13):
            for x in range(14, 21):
                grid[y][x] = 'g'

        # Head / Snout: x=16..28, y=4..11
        for y in range(4, 12):
            for x in range(16, 28):
                grid[y][x] = 'g'

        # Snout front: x=27..29, y=6..10
        for y in range(6, 11):
            for x in range(27, 30):
                grid[y][x] = 'g'

        # Mouth opening
        if mouth_open:
            for x in range(22, 29):
                grid[10][x] = '.'
                grid[11][x] = 'r'

        # Eye: at x=23, y=6
        if eye_state == "normal":
            grid[6][23] = 'w'; grid[6][24] = 'w'
            grid[7][23] = 'w'; grid[7][24] = 'e'
        elif eye_state == "blink":
            grid[7][23] = '#'
            grid[7][24] = '#'
        elif eye_state == "hurt":
            grid[6][23] = 'r'; grid[6][24] = 'r'
            grid[7][23] = 'w'; grid[7][24] = 'r'

        # Little arm: x=19..22, y=14..16
        grid[14][19] = 'G'; grid[14][20] = 'G'; grid[14][21] = 'G'
        grid[15][21] = 'G'; grid[16][21] = 'G'

        # Legs (y=23..30)
        # Left leg (near) and Right leg (far/darker)
        if pose == "idle":
            # Standing straight
            for y in range(23, 30):
                grid[y][10] = 'g'; grid[y][11] = 'g'
                grid[y][15] = 'G'; grid[y][16] = 'G'
            grid[29][12] = 'g'
            grid[29][17] = 'G'

        elif pose == "run":
            # 6-phase run cycle
            if leg_offset == 0:
                # Leg 1 forward, Leg 2 back
                for y in range(23, 27): grid[y][16] = 'g'
                for y in range(27, 30): grid[y][18] = 'g'
                grid[29][19] = 'g'
                for y in range(23, 27): grid[y][9] = 'G'
                grid[26][8] = 'G'; grid[26][7] = 'G'
            elif leg_offset == 1:
                # Passing
                for y in range(23, 30): grid[y][14] = 'g'; grid[y][11] = 'G'
                grid[29][15] = 'g'; grid[29][12] = 'G'
            elif leg_offset == 2:
                # Leg 1 back, Leg 2 forward
                for y in range(23, 27): grid[y][9] = 'g'
                grid[26][8] = 'g'; grid[26][7] = 'g'
                for y in range(23, 27): grid[y][16] = 'G'
                for y in range(27, 30): grid[y][18] = 'G'
                grid[29][19] = 'G'
            elif leg_offset == 3:
                # High stride
                for y in range(23, 27): grid[y][8] = 'g'
                grid[27][7] = 'g'; grid[28][6] = 'g'
                for y in range(23, 26): grid[y][17] = 'G'
                for y in range(26, 30): grid[y][19] = 'G'
                grid[29][20] = 'G'
            elif leg_offset == 4:
                # Ground contact
                for y in range(23, 30): grid[y][12] = 'g'; grid[y][15] = 'G'
                grid[29][13] = 'g'; grid[29][16] = 'G'
            else:
                # Push off
                for y in range(23, 28): grid[y][10] = 'g'
                for y in range(23, 28): grid[y][16] = 'G'
                grid[28][11] = 'g'; grid[28][17] = 'G'

        elif pose == "jump_rise":
            # Stretched, legs tucked slightly forward
            for y in range(23, 28):
                grid[y][12] = 'g'; grid[y][14] = 'G'
            grid[27][13] = 'g'; grid[27][15] = 'G'

        elif pose == "jump_apex":
            # Neutral tuck at highest point
            for y in range(22, 27):
                grid[y][11] = 'g'; grid[y][14] = 'G'
            grid[26][12] = 'g'; grid[26][15] = 'G'

        elif pose == "jump_fall":
            # Legs extending down preparing for landing
            for y in range(23, 30):
                grid[y][11] = 'g'; grid[y][15] = 'G'
            grid[29][12] = 'g'; grid[29][16] = 'G'

        elif pose == "land":
            # Squash down (legs splayed out)
            for y in range(25, 30):
                grid[y][9] = 'g'; grid[y][10] = 'g'
                grid[y][17] = 'G'; grid[y][18] = 'G'
            grid[29][8] = 'g'; grid[29][19] = 'G'

        elif pose == "dive":
            # Head tipped downward, streamlined
            for y in range(22, 27):
                grid[y][9] = 'g'; grid[y][12] = 'G'
            grid[26][8] = 'g'; grid[26][11] = 'G'

    # Add 1px dark outline around all non-transparent pixels
    outlined = [['.' for _ in range(32)] for _ in range(32)]
    for y in range(32):
        for x in range(32):
            if grid[y][x] != '.':
                outlined[y][x] = grid[y][x]
            else:
                # Check 4-connected neighbors
                has_solid = False
                for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < 32 and 0 <= ny < 32 and grid[ny][nx] != '.':
                        has_solid = True
                        break
                if has_solid:
                    outlined[y][x] = '#'

    return outlined

def generate_all():
    os.makedirs("assets/sources", exist_ok=True)
    os.makedirs("assets/sprites", exist_ok=True)

    frames = {}
    # 1. Idle (2 frames)
    frames["idle_0"] = create_dino_frame("idle", eye_state="normal")
    frames["idle_1"] = create_dino_frame("idle", eye_state="blink")

    # 2. Run (6 frames)
    for i in range(6):
        frames[f"run_{i}"] = create_dino_frame("run", leg_offset=i)

    # 3. Jump: rise, apex, fall
    frames["jump_rise"] = create_dino_frame("jump_rise")
    frames["jump_apex"] = create_dino_frame("jump_apex")
    frames["jump_fall"] = create_dino_frame("jump_fall")

    # 4. Land (2 frames)
    frames["land_0"] = create_dino_frame("land")
    frames["land_1"] = create_dino_frame("idle")

    # 5. Slide / duck (2 frames)
    frames["slide_0"] = create_dino_frame("slide", duck=True)
    frames["slide_1"] = create_dino_frame("slide", duck=True, mouth_open=True)

    # 6. Dive (2 frames)
    frames["dive_0"] = create_dino_frame("dive")
    frames["dive_1"] = create_dino_frame("dive", mouth_open=True)

    # 7. Drop-through (2 frames)
    frames["drop_0"] = create_dino_frame("dive")
    frames["drop_1"] = create_dino_frame("jump_fall")

    # 8. Hurt (2 frames)
    frames["hurt_0"] = create_dino_frame("idle", eye_state="hurt", mouth_open=True)
    frames["hurt_1"] = create_dino_frame("land", eye_state="hurt")

    # 9. Death (6 frames)
    for i in range(6):
        frames[f"death_{i}"] = create_dino_frame("death", dead=True, eye_state="hurt")

    # Save source text maps
    with open("assets/sources/dinosaur_sourcemap.txt", "w") as f:
        for name, grid in frames.items():
            f.write(f"=== FRAME: {name} ===\n")
            for row in grid:
                f.write("".join(row) + "\n")
            f.write("\n")

    # Build Atlas / Sprite Sheet
    # Layout: each column is a 32x32 frame. 26 frames total = 832x32 px image
    frame_list = list(frames.keys())
    sheet_width = len(frame_list) * 32
    sheet_img = Image.new("RGBA", (sheet_width, 32), (0, 0, 0, 0))

    frame_indices = {}
    for idx, name in enumerate(frame_list):
        img = grid_to_image(frames[name], 32)
        sheet_img.paste(img, (idx * 32, 0))
        frame_indices[name] = idx

    sheet_img.save("assets/sprites/dinosaur_sheet.png")

    # Save index guide
    with open("assets/sprites/dinosaur_frames.json", "w") as f:
        import json
        json.dump(frame_indices, f, indent=2)

    # 10. Generate Dust Puff (4 frames, 16x16 px)
    dust_frames = []
    # frame 0: tiny puff
    d0 = [['.' for _ in range(16)] for _ in range(16)]
    d0[12][7] = 'd'; d0[12][8] = 'd'; d0[13][6] = '#'; d0[13][9] = '#'
    dust_frames.append(d0)
    # frame 1: expanding
    d1 = [['.' for _ in range(16)] for _ in range(16)]
    for x in range(5, 11): d1[11][x] = 'd'
    for x in range(4, 12): d1[12][x] = 'd'
    dust_frames.append(d1)
    # frame 2: dissipating
    d2 = [['.' for _ in range(16)] for _ in range(16)]
    d2[10][3] = 'd'; d2[10][12] = 'd'; d2[9][5] = 'd'; d2[9][10] = 'd'
    dust_frames.append(d2)
    # frame 3: faded specks
    d3 = [['.' for _ in range(16)] for _ in range(16)]
    d3[8][2] = 'd'; d3[8][13] = 'd'
    dust_frames.append(d3)

    dust_sheet = Image.new("RGBA", (64, 16), (0, 0, 0, 0))
    for i, df in enumerate(dust_frames):
        img = grid_to_image(df, 16)
        dust_sheet.paste(img, (i * 16, 0))
    dust_sheet.save("assets/sprites/dust_puff.png")

    # 11. Generate Tiles & Test Obstacles
    # 16x16 Ground tile
    gt = [['s' for _ in range(16)] for _ in range(16)]
    for x in range(16):
        gt[0][x] = '#'
        gt[1][x] = 'o'
        gt[2][x] = 'o'
        gt[15][x] = 'S'
    gt_img = grid_to_image(gt, 16)
    gt_img.save("assets/sprites/ground_tile.png")

    # Low obstacle (Cactus/Rock: 16x24 px)
    obs_low = [['.' for _ in range(16)] for _ in range(24)]
    for y in range(4, 24):
        for x in range(4, 12):
            obs_low[y][x] = 's'
    # side arms
    for y in range(8, 15):
        obs_low[y][2] = 's'; obs_low[y][3] = 's'
        obs_low[y][12] = 's'; obs_low[y][13] = 's'
    # outline
    obs_low_img = grid_to_image(obs_low, 16)
    # Outline low obstacle
    obs_low_outlined = Image.new("RGBA", (16, 24), (0, 0, 0, 0))
    for y in range(24):
        for x in range(16):
            if obs_low[y][x] == 's':
                obs_low_outlined.putpixel((x, y), PALETTE['s'])
            elif obs_low[y][x] == '.':
                for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < 16 and 0 <= ny < 24 and obs_low[ny][nx] == 's':
                        obs_low_outlined.putpixel((x, y), PALETTE['#'])
                        break
    obs_low_outlined.save("assets/sprites/obstacle_low.png")

    # High obstacle (Overhang barrier to slide under: 24x32 px, leaves bottom 14px clear)
    obs_high = Image.new("RGBA", (24, 32), (0, 0, 0, 0))
    for y in range(0, 16):
        for x in range(2, 22):
            obs_high.putpixel((x, y), PALETTE['S'])
    # Outline
    for x in range(1, 23):
        obs_high.putpixel((x, 0), PALETTE['#'])
        obs_high.putpixel((x, 16), PALETTE['#'])
    for y in range(0, 17):
        obs_high.putpixel((1, y), PALETTE['#'])
        obs_high.putpixel((22, y), PALETTE['#'])
    obs_high.save("assets/sprites/obstacle_high.png")

    print(f"Generated dinosaur sheet ({sheet_width}x32) with {len(frame_list)} frames.")
    print("Generated dust_puff.png, ground_tile.png, obstacle_low.png, obstacle_high.png.")

if __name__ == "__main__":
    generate_all()
