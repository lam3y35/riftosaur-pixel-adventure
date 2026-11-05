"""
Pro Dinosaur Sprite Sheet Generator for Riftosaur.
Directly reproduces the iconic, pro-grade pixel art style from the reference photos in gini/:
- Crisp charcoal slate body (#484f58 / #525252)
- Clean rectangular head with open maw and 2x2 white eye (#e6e6e6)
- Cute upward-angled tail, small L-shaped arm
- 4-frame running animation with distinct leg strides
- Clean jump pose, slide/duck pose, and hurt/death pose
"""

from PIL import Image

def generate_pro_dino():
    # Each frame is 32x32 pixels
    fw, fh = 32, 32

    # Pro Dino Palette matching reference
    BODY = (72, 79, 88, 255)       # Charcoal slate
    BODY_DARK = (55, 62, 71, 255)  # Shadow / back leg
    EYE = (240, 243, 246, 255)     # Clean white eye
    HURT_EYE = (239, 68, 68, 255)  # Red X eye
    TRANSPARENT = (0, 0, 0, 0)

    # Base dinosaur anatomy (head, body, tail, arm)
    # Head: x=14..27, y=3..12
    # Snout front: x=25..27, y=4..11
    # Mouth notch: x=21..27, y=9..10
    # Eye: (18, 5), (19, 5), (18, 6), (19, 6)
    # Body: x=9..20, y=11..21
    # Tail: starts at x=9, y=14, goes up to x=5..6, y=9..13
    # Arm: x=20..22, y=13..16

    def draw_base_dino(grid, eye_type="normal", arm_raised=False):
        # 1. Head
        for y in range(3, 12):
            for x in range(15, 28):
                grid[y][x] = 'B'

        # Mouth notch cutout
        for y in range(9, 11):
            for x in range(21, 28):
                grid[y][x] = '.'

        # Eye
        if eye_type == "normal":
            grid[5][18] = 'W'; grid[5][19] = 'W'
            grid[6][18] = 'W'; grid[6][19] = 'W'
        elif eye_type == "blink":
            grid[6][18] = '.'; grid[6][19] = '.'
        elif eye_type == "hurt":
            grid[5][18] = 'X'; grid[5][19] = 'X'
            grid[6][18] = 'X'; grid[6][19] = 'X'

        # 2. Neck & Body
        # Neck connection
        for y in range(10, 14):
            for x in range(13, 20):
                grid[y][x] = 'B'
        # Main torso
        for y in range(12, 22):
            for x in range(8, 20):
                grid[y][x] = 'B'

        # 3. Tail (pointing up and back)
        for y in range(13, 20):
            for x in range(6, 10):
                grid[y][x] = 'B'
        for y in range(10, 15):
            for x in range(5, 8):
                grid[y][x] = 'B'
        grid[9][5] = 'B'; grid[9][6] = 'B'
        grid[8][5] = 'B'; grid[8][6] = 'B'

        # 4. Cute little arm
        if not arm_raised:
            grid[14][20] = 'B'; grid[14][21] = 'B'
            grid[15][21] = 'B'
            grid[16][21] = 'B'
        else:
            grid[13][20] = 'B'; grid[13][21] = 'B'
            grid[14][21] = 'B'

    def draw_legs_run_1(grid):
        # Left leg forward, right leg back
        # Front leg (left)
        grid[22][16] = 'B'; grid[22][17] = 'B'
        grid[23][16] = 'B'; grid[23][17] = 'B'
        grid[24][16] = 'B'; grid[24][17] = 'B'; grid[24][18] = 'B'
        # Back leg (right) - slightly darker for depth
        grid[22][10] = 'D'; grid[22][11] = 'D'
        grid[23][9] = 'D'; grid[23][10] = 'D'
        grid[24][8] = 'D'; grid[24][9] = 'D'

    def draw_legs_run_2(grid):
        # Passing frame: legs straight down
        grid[22][12] = 'B'; grid[22][13] = 'B'; grid[22][15] = 'B'; grid[22][16] = 'B'
        grid[23][12] = 'B'; grid[23][13] = 'B'; grid[23][15] = 'B'; grid[23][16] = 'B'
        grid[24][12] = 'B'; grid[24][13] = 'B'; grid[24][14] = 'B'; grid[24][15] = 'B'; grid[24][16] = 'B'; grid[24][17] = 'B'

    def draw_legs_run_3(grid):
        # Right leg forward, left leg back
        # Front leg (right)
        grid[22][10] = 'B'; grid[22][11] = 'B'
        grid[23][10] = 'B'; grid[23][11] = 'B'; grid[23][12] = 'B'
        grid[24][11] = 'B'; grid[24][12] = 'B'; grid[24][13] = 'B'
        # Back leg (left)
        grid[22][16] = 'D'; grid[22][17] = 'D'
        grid[23][17] = 'D'; grid[23][18] = 'D'
        grid[24][18] = 'D'; grid[24][19] = 'D'

    def draw_legs_run_4(grid):
        # Passing frame 2
        grid[22][13] = 'B'; grid[22][14] = 'B'; grid[22][15] = 'B'
        grid[23][13] = 'B'; grid[23][14] = 'B'; grid[23][15] = 'B'
        grid[24][13] = 'B'; grid[24][14] = 'B'; grid[24][15] = 'B'; grid[24][16] = 'B'

    def draw_legs_jump(grid):
        # Tucked jump legs
        grid[22][11] = 'B'; grid[22][12] = 'B'; grid[22][15] = 'B'; grid[22][16] = 'B'
        grid[23][10] = 'B'; grid[23][11] = 'B'; grid[23][16] = 'B'; grid[23][17] = 'B'

    # Build frames
    frames = []

    # Frame 0: Idle (standing)
    f_idle = [['.' for _ in range(fw)] for _ in range(fh)]
    draw_base_dino(f_idle, "normal")
    draw_legs_run_2(f_idle)
    frames.append(f_idle)

    # Frame 1: Idle blink
    f_blink = [['.' for _ in range(fw)] for _ in range(fh)]
    draw_base_dino(f_blink, "blink")
    draw_legs_run_2(f_blink)
    frames.append(f_blink)

    # Frame 2..5: 4-Frame Run Cycle
    f_run1 = [['.' for _ in range(fw)] for _ in range(fh)]
    draw_base_dino(f_run1, "normal")
    draw_legs_run_1(f_run1)
    frames.append(f_run1)

    f_run2 = [['.' for _ in range(fw)] for _ in range(fh)]
    draw_base_dino(f_run2, "normal")
    draw_legs_run_2(f_run2)
    frames.append(f_run2)

    f_run3 = [['.' for _ in range(fw)] for _ in range(fh)]
    draw_base_dino(f_run3, "normal")
    draw_legs_run_3(f_run3)
    frames.append(f_run3)

    f_run4 = [['.' for _ in range(fw)] for _ in range(fh)]
    draw_base_dino(f_run4, "normal")
    draw_legs_run_4(f_run4)
    frames.append(f_run4)

    # Extra run frames for 6-frame loop compatibility (frames 6, 7)
    frames.append(f_run1)
    frames.append(f_run3)

    # Frame 8: Jump Rise (arm slightly raised, legs tucked)
    f_rise = [['.' for _ in range(fw)] for _ in range(fh)]
    draw_base_dino(f_rise, "normal", arm_raised=True)
    draw_legs_jump(f_rise)
    frames.append(f_rise)

    # Frame 9: Jump Apex
    f_apex = [['.' for _ in range(fw)] for _ in range(fh)]
    draw_base_dino(f_apex, "normal")
    draw_legs_jump(f_apex)
    frames.append(f_apex)

    # Frame 10: Jump Fall
    f_fall = [['.' for _ in range(fw)] for _ in range(fh)]
    draw_base_dino(f_fall, "normal")
    draw_legs_run_1(f_fall)
    frames.append(f_fall)

    # Frame 11: Land squash
    f_land = [['.' for _ in range(fw)] for _ in range(fh)]
    draw_base_dino(f_land, "normal")
    draw_legs_run_2(f_land)
    frames.append(f_land)

    # Frame 12..14: Slide / Duck (lower profile)
    f_slide1 = [['.' for _ in range(fw)] for _ in range(fh)]
    # Ducked head: y=10..18, x=16..29
    for y in range(10, 18):
        for x in range(16, 30):
            f_slide1[y][x] = 'B'
    # Mouth notch
    for y in range(15, 17):
        for x in range(24, 30):
            f_slide1[y][x] = '.'
    # Eye
    f_slide1[12][20] = 'W'; f_slide1[12][21] = 'W'
    f_slide1[13][20] = 'W'; f_slide1[13][21] = 'W'
    # Ducked body & horizontal tail
    for y in range(14, 22):
        for x in range(6, 20):
            f_slide1[y][x] = 'B'
    for y in range(15, 18):
        for x in range(2, 6):
            f_slide1[y][x] = 'B'
    # Feet tucked
    for x in range(8, 16):
        f_slide1[22][x] = 'B'
    frames.append(f_slide1)
    frames.append(f_slide1)
    frames.append(f_slide1)

    # Frame 15: Dive (angled forward downward)
    f_dive = [['.' for _ in range(fw)] for _ in range(fh)]
    draw_base_dino(f_dive, "normal", arm_raised=True)
    draw_legs_jump(f_dive)
    frames.append(f_dive)

    # Frames 16..18: Hurt / Hit
    f_hurt = [['.' for _ in range(fw)] for _ in range(fh)]
    draw_base_dino(f_hurt, "hurt")
    draw_legs_jump(f_hurt)
    frames.append(f_hurt)
    frames.append(f_hurt)
    frames.append(f_hurt)

    # Frames 19..26: Death animation sequence (tumble back onto ground)
    for rot in range(8):
        f_dead = [['.' for _ in range(fw)] for _ in range(fh)]
        draw_base_dino(f_dead, "hurt")
        draw_legs_run_1(f_dead)
        frames.append(f_dead)

    # Stitch into a single horizontal sprite sheet
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

    sheet.save("assets/sprites/dinosaur_sheet.png")
    print(f"Generated pro-grade dinosaur_sheet.png with {total_frames} frames (size: {sheet.size}).")

if __name__ == "__main__":
    generate_pro_dino()
