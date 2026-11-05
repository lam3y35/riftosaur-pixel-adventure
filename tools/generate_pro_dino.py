"""
Pro Dinosaur Sprite Sheet Generator for Riftosaur.
Generates multi-skin sprite sheets for the Dinosaur Skin Shop:
- Classic Charcoal (Default)
- Emerald Raptor (Vibrant jungle green with golden eye)
- Ruby Carnotaur (Fiery crimson with glowing yellow eye)
- Cyber Rift (Electric neon cyan with magenta eye)
- Golden Fossil (Shimmering ammonite gold with platinum eye)
"""

from PIL import Image

SKINS = {
    "classic": {
        "file": "assets/sprites/dinosaur_sheet.png",
        "copy": "assets/sprites/dinosaur_sheet_classic.png",
        "body": (72, 79, 88, 255),
        "body_dark": (55, 62, 71, 255),
        "eye": (240, 243, 246, 255),
        "hurt_eye": (239, 68, 68, 255)
    },
    "emerald": {
        "file": "assets/sprites/dinosaur_sheet_emerald.png",
        "body": (46, 142, 60, 255),
        "body_dark": (32, 98, 42, 255),
        "eye": (255, 218, 54, 255),
        "hurt_eye": (239, 68, 68, 255)
    },
    "ruby": {
        "file": "assets/sprites/dinosaur_sheet_ruby.png",
        "body": (212, 48, 56, 255),
        "body_dark": (148, 28, 36, 255),
        "eye": (255, 235, 90, 255),
        "hurt_eye": (255, 255, 255, 255)
    },
    "cyber": {
        "file": "assets/sprites/dinosaur_sheet_cyber.png",
        "body": (18, 190, 230, 255),
        "body_dark": (10, 115, 170, 255),
        "eye": (255, 105, 230, 255),
        "hurt_eye": (255, 255, 255, 255)
    },
    "gold": {
        "file": "assets/sprites/dinosaur_sheet_gold.png",
        "body": (242, 185, 40, 255),
        "body_dark": (185, 132, 22, 255),
        "eye": (255, 255, 255, 255),
        "hurt_eye": (239, 68, 68, 255)
    }
}

def generate_skin_sheet(cfg):
    fw, fh = 32, 32
    BODY = cfg["body"]
    BODY_DARK = cfg["body_dark"]
    EYE = cfg["eye"]
    HURT_EYE = cfg["hurt_eye"]
    TRANSPARENT = (0, 0, 0, 0)

    def draw_base_dino(grid, eye_type="normal", arm_raised=False):
        for y in range(3, 12):
            for x in range(15, 28):
                grid[y][x] = 'B'

        for y in range(9, 11):
            for x in range(21, 28):
                grid[y][x] = '.'

        if eye_type == "normal":
            grid[5][18] = 'W'; grid[5][19] = 'W'
            grid[6][18] = 'W'; grid[6][19] = 'W'
        elif eye_type == "blink":
            grid[6][18] = '.'; grid[6][19] = '.'
        elif eye_type == "hurt":
            grid[5][18] = 'X'; grid[6][19] = 'X'
            grid[5][19] = 'X'; grid[6][18] = 'X'

        for y in range(11, 21):
            for x in range(9, 21):
                grid[y][x] = 'B'

        tail_pts = [(8, 14), (8, 15), (7, 13), (7, 14), (6, 12), (6, 13), (5, 10), (5, 11), (5, 12), (4, 9), (4, 10)]
        for tx, ty in tail_pts:
            grid[ty][tx] = 'B'

        arm_y = 13 if arm_raised else 14
        grid[arm_y][20] = 'B'; grid[arm_y][21] = 'B'
        grid[arm_y + 1][21] = 'B'

    def draw_legs_idle(grid):
        for y in range(21, 27):
            grid[y][12] = 'B'; grid[y][13] = 'B'
        grid[27][13] = 'B'; grid[27][14] = 'B'; grid[27][15] = 'B'
        for y in range(21, 27):
            grid[y][17] = 'D'; grid[y][18] = 'D'
        grid[27][18] = 'D'; grid[27][19] = 'D'; grid[27][20] = 'D'

    def draw_legs_run_1(grid):
        for y in range(21, 27):
            grid[y][11] = 'B'; grid[y][12] = 'B'
        grid[27][10] = 'B'; grid[27][11] = 'B'; grid[27][12] = 'B'
        for y in range(21, 25):
            grid[y][18] = 'D'; grid[y][19] = 'D'
        grid[25][20] = 'D'; grid[25][21] = 'D'
        grid[26][21] = 'D'; grid[26][22] = 'D'

    def draw_legs_run_2(grid):
        for y in range(21, 26):
            grid[y][13] = 'B'; grid[y][14] = 'B'
        grid[26][12] = 'B'; grid[26][13] = 'B'
        for y in range(21, 26):
            grid[y][17] = 'D'; grid[y][18] = 'D'
        grid[26][18] = 'D'; grid[26][19] = 'D'

    def draw_legs_run_3(grid):
        for y in range(21, 25):
            grid[y][12] = 'B'; grid[y][13] = 'B'
        grid[25][10] = 'B'; grid[25][11] = 'B'
        grid[26][9] = 'B'; grid[26][10] = 'B'
        for y in range(21, 27):
            grid[y][18] = 'D'; grid[y][19] = 'D'
        grid[27][19] = 'D'; grid[27][20] = 'D'; grid[27][21] = 'D'

    def draw_legs_run_4(grid):
        for y in range(21, 26):
            grid[y][14] = 'B'; grid[y][15] = 'B'
        grid[26][15] = 'B'; grid[26][16] = 'B'
        for y in range(21, 26):
            grid[y][16] = 'D'; grid[y][17] = 'D'
        grid[26][15] = 'D'; grid[26][16] = 'D'

    def draw_legs_jump(grid):
        for y in range(21, 25):
            grid[y][12] = 'B'; grid[y][13] = 'B'
        grid[25][11] = 'B'; grid[25][12] = 'B'
        for y in range(21, 25):
            grid[y][17] = 'D'; grid[y][18] = 'D'
        grid[25][18] = 'D'; grid[25][19] = 'D'

    frames = []

    # Frame 0..1: Idle
    f_idle = [['.' for _ in range(fw)] for _ in range(fh)]
    draw_base_dino(f_idle, "normal")
    draw_legs_idle(f_idle)
    frames.append(f_idle)

    f_blink = [['.' for _ in range(fw)] for _ in range(fh)]
    draw_base_dino(f_blink, "blink")
    draw_legs_idle(f_blink)
    frames.append(f_blink)

    # Frame 2..7: Run cycle
    run_leg_funcs = [draw_legs_run_1, draw_legs_run_2, draw_legs_run_3, draw_legs_run_4, draw_legs_run_1, draw_legs_run_3]
    for i, leg_fn in enumerate(run_leg_funcs):
        f_run = [['.' for _ in range(fw)] for _ in range(fh)]
        draw_base_dino(f_run, "normal", arm_raised=(i % 2 == 1))
        leg_fn(f_run)
        frames.append(f_run)

    # Frame 8: Jump Rise
    f_jump = [['.' for _ in range(fw)] for _ in range(fh)]
    draw_base_dino(f_jump, "normal", arm_raised=True)
    draw_legs_jump(f_jump)
    frames.append(f_jump)

    # Frame 9: Jump Apex
    frames.append(f_jump)

    # Frame 10: Jump Fall
    f_fall = [['.' for _ in range(fw)] for _ in range(fh)]
    draw_base_dino(f_fall, "normal", arm_raised=False)
    draw_legs_idle(f_fall)
    frames.append(f_fall)

    # Frame 11: Land
    f_land = [['.' for _ in range(fw)] for _ in range(fh)]
    draw_base_dino(f_land, "normal")
    draw_legs_idle(f_land)
    frames.append(f_land)

    # Frames 12..14: Slide / Duck (low crouching profile)
    f_slide = [['.' for _ in range(fw)] for _ in range(fh)]
    for y in range(12, 19):
        for x in range(16, 28):
            f_slide[y][x] = 'B'
    for y in range(16, 18):
        for x in range(22, 28):
            f_slide[y][x] = '.'
    f_slide[13][19] = 'W'; f_slide[13][20] = 'W'
    f_slide[14][19] = 'W'; f_slide[14][20] = 'W'
    for y in range(14, 22):
        for x in range(6, 20):
            f_slide[y][x] = 'B'
    for y in range(15, 18):
        for x in range(2, 6):
            f_slide[y][x] = 'B'
    for x in range(8, 16):
        f_slide[22][x] = 'B'
    frames.append(f_slide)
    frames.append(f_slide)
    frames.append(f_slide)

    # Frame 15: Dive
    f_dive = [['.' for _ in range(fw)] for _ in range(fh)]
    draw_base_dino(f_dive, "normal", arm_raised=True)
    draw_legs_jump(f_dive)
    frames.append(f_dive)

    # Frames 16..18: Hurt
    f_hurt = [['.' for _ in range(fw)] for _ in range(fh)]
    draw_base_dino(f_hurt, "hurt")
    draw_legs_jump(f_hurt)
    frames.append(f_hurt)
    frames.append(f_hurt)
    frames.append(f_hurt)

    # Frames 19..26: Death animation sequence
    for _ in range(8):
        f_dead = [['.' for _ in range(fw)] for _ in range(fh)]
        draw_base_dino(f_dead, "hurt")
        draw_legs_run_1(f_dead)
        frames.append(f_dead)

    total_frames = len(frames)
    sheet = Image.new("RGBA", (total_frames * fw, fh), TRANSPARENT)

    palette = {
        'B': BODY,
        'D': BODY_DARK,
        'W': EYE,
        'X': HURT_EYE
    }

    for i, f in enumerate(frames):
        for y in range(fh):
            for x in range(fw):
                c = f[y][x]
                if c in palette:
                    sheet.putpixel((i * fw + x, y), palette[c])

    sheet.save(cfg["file"])
    if "copy" in cfg:
        sheet.save(cfg["copy"])
    print(f"Generated skin: {cfg['file']} ({sheet.size})")

def generate_all_skins():
    for name, cfg in SKINS.items():
        generate_skin_sheet(cfg)

if __name__ == "__main__":
    generate_all_skins()
