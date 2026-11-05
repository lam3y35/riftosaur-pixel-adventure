"""
Crystal Spikes generator for Riftosaur.
Generates an unmistakably deadly crystal spike hazard (16x24 px):
- Sharp jagged crystal spires pointing up
- Deep crimson/magenta crystal facets
- Glowing neon tips and highlights
"""

from PIL import Image

def generate_spikes():
    w, h = 16, 24
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))

    # Color Palette for Deadly Rift Spikes
    DARK_OUTLINE = (20, 5, 25, 255)
    CRYSTAL_DARK = (136, 19, 55, 255)      # Deep crimson/ruby
    CRYSTAL_MID = (225, 29, 72, 255)       # Hot ruby
    CRYSTAL_LIGHT = (251, 113, 133, 255)   # Bright neon pink
    CRYSTAL_TIP = (255, 241, 242, 255)     # Glowing white/pink specular

    # Main spike (center-left: base x=4..11, tip at x=7, y=5)
    # Secondary spike (right: base x=10..15, tip at x=13, y=10)
    # Small tertiary spike (left: base x=0..5, tip at x=2, y=13)

    grid = [['.' for _ in range(w)] for _ in range(h)]

    # Center-tallest spire: tip at (7, 4)
    # y=4: tip
    grid[4][7] = 'T'
    # y=5..6
    grid[5][6] = 'L'; grid[5][7] = 'M'
    grid[6][6] = 'L'; grid[6][7] = 'M'; grid[6][8] = 'D'
    # y=7..10
    for y in range(7, 11):
        grid[y][5] = 'L'; grid[y][6] = 'L'; grid[y][7] = 'M'; grid[y][8] = 'D'
    # y=11..16
    for y in range(11, 17):
        grid[y][4] = 'L'; grid[y][5] = 'L'; grid[y][6] = 'M'; grid[y][7] = 'M'; grid[y][8] = 'D'; grid[y][9] = 'D'
    # y=17..23 (base)
    for y in range(17, 24):
        for x in range(3, 11):
            grid[y][x] = 'M' if x < 7 else 'D'
        grid[y][3] = 'L'

    # Right spire: tip at (13, 9)
    grid[9][13] = 'T'
    grid[10][12] = 'L'; grid[10][13] = 'M'
    grid[11][12] = 'L'; grid[11][13] = 'M'; grid[11][14] = 'D'
    for y in range(12, 18):
        grid[y][11] = 'L'; grid[y][12] = 'M'; grid[y][13] = 'M'; grid[y][14] = 'D'
    for y in range(18, 24):
        for x in range(10, 16):
            grid[y][x] = 'M' if x < 13 else 'D'
        grid[y][10] = 'L'

    # Left smaller spire: tip at (2, 13)
    grid[13][2] = 'T'
    grid[14][1] = 'L'; grid[14][2] = 'M'
    grid[15][1] = 'L'; grid[15][2] = 'M'; grid[15][3] = 'D'
    for y in range(16, 24):
        grid[y][0] = 'L'; grid[y][1] = 'L'; grid[y][2] = 'M'; grid[y][3] = 'D'

    # Ground base anchor: y=22, 23
    for x in range(16):
        if grid[23][x] == '.':
            grid[23][x] = 'D'

    # Draw to image with outlines
    palette = {
        'T': CRYSTAL_TIP,
        'L': CRYSTAL_LIGHT,
        'M': CRYSTAL_MID,
        'D': CRYSTAL_DARK
    }

    # First pass: fill pixels
    for y in range(h):
        for x in range(w):
            c = grid[y][x]
            if c in palette:
                img.putpixel((x, y), palette[c])

    # Second pass: dark outline around non-empty pixels
    outlined = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for y in range(h):
        for x in range(w):
            if grid[y][x] != '.':
                outlined.putpixel((x, y), palette[grid[y][x]])
            else:
                # check neighbors
                has_solid_neighbor = False
                for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and grid[ny][nx] != '.':
                        has_solid_neighbor = True
                        break
                if has_solid_neighbor:
                    outlined.putpixel((x, y), DARK_OUTLINE)

    outlined.save("assets/sprites/obstacle_low.png")
    print("Generated deadly crystal spikes at assets/sprites/obstacle_low.png (16x24 px).")

if __name__ == "__main__":
    generate_spikes()
