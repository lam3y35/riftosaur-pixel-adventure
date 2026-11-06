import os
import math
from PIL import Image, ImageDraw

os.makedirs("assets/sprites", exist_ok=True)

def save_image(img, path):
    img.save(path)
    print(f"Generated {path} ({img.width}x{img.height})")

# 1. Ground Tiles (16x16)
# Jungle Ground: lush mossy top with deep roots
img_jungle_tile = Image.new("RGBA", (16, 16), (42, 30, 20, 255))
d = ImageDraw.Draw(img_jungle_tile)
d.rectangle([0, 0, 15, 3], fill=(35, 140, 50, 255)) # Green moss top
d.rectangle([0, 4, 15, 5], fill=(55, 175, 65, 255))
d.point([(2, 7), (5, 9), (11, 8), (13, 11), (7, 13)], fill=(20, 90, 35, 255)) # root speckles
save_image(img_jungle_tile, "assets/sprites/ground_tile_jungle.png")

# Ice Ground: frosted crystal cyan surface with deep blue permafrost
img_ice_tile = Image.new("RGBA", (16, 16), (25, 45, 75, 255))
d = ImageDraw.Draw(img_ice_tile)
d.rectangle([0, 0, 15, 2], fill=(225, 250, 255, 255)) # White frost
d.rectangle([0, 3, 15, 5], fill=(120, 215, 245, 255)) # Cyan ice
d.point([(3, 8), (7, 11), (12, 7), (9, 13)], fill=(180, 235, 255, 255)) # Ice crystal glints
save_image(img_ice_tile, "assets/sprites/ground_tile_ice.png")

# Volcano Ground: basalt obsidian with magma fissure lines
img_volcano_tile = Image.new("RGBA", (16, 16), (28, 22, 25, 255))
d = ImageDraw.Draw(img_volcano_tile)
d.rectangle([0, 0, 15, 2], fill=(55, 40, 45, 255)) # Dark crust
d.line([(2, 3), (6, 7), (9, 6), (14, 11)], fill=(255, 95, 20, 255), width=1) # Glowing magma vein
d.point([(6, 8), (9, 7)], fill=(255, 215, 50, 255)) # Hot spot
save_image(img_volcano_tile, "assets/sprites/ground_tile_volcano.png")

# Lava Pit Environmental Hazard (48x16)
img_lava = Image.new("RGBA", (48, 16), (0, 0, 0, 0))
d = ImageDraw.Draw(img_lava)
d.rectangle([0, 4, 47, 15], fill=(220, 50, 10, 255))
d.rectangle([0, 6, 47, 13], fill=(255, 120, 20, 255))
d.rectangle([2, 8, 45, 11], fill=(255, 230, 60, 255))
# Bubbles
d.ellipse([10, 2, 16, 8], fill=(255, 150, 30, 255))
d.ellipse([32, 1, 37, 6], fill=(255, 190, 40, 255))
save_image(img_lava, "assets/sprites/hazard_lava_pit.png")

# 2. Parallax Backgrounds (480x270 seamless width)
# A) JUNGLE PARALLAX
# Sky: Tropical emerald-tinted misty sky
img_j_sky = Image.new("RGBA", (480, 270), (0, 0, 0, 0))
d = ImageDraw.Draw(img_j_sky)
for y in range(270):
    t = y / 270.0
    r = int(25 + 30 * t)
    g = int(65 + 60 * t)
    b = int(70 + 40 * t)
    d.line([(0, y), (479, y)], fill=(r, g, b, 255))
save_image(img_j_sky, "assets/sprites/bg_jungle_sky.png")

# Canopy: Distant giant tree trunks and massive vine branches
img_j_canopy = Image.new("RGBA", (480, 270), (0, 0, 0, 0))
d = ImageDraw.Draw(img_j_canopy)
for x in range(480):
    elev = int(140 + 25 * math.sin(x * 2 * math.pi / 240.0) + 12 * math.sin(x * 2 * math.pi / 120.0))
    d.line([(x, elev), (x, 270)], fill=(18, 55, 32, 255))
# Tree silhouettes
for tx in [60, 180, 300, 420]:
    d.rectangle([tx - 12, 80, tx + 12, 270], fill=(12, 42, 24, 255))
    d.ellipse([tx - 45, 30, tx + 45, 110], fill=(15, 60, 30, 255))
save_image(img_j_canopy, "assets/sprites/bg_jungle_canopy.png")

# Foreground foliage / dangling vines
img_j_trees = Image.new("RGBA", (480, 270), (0, 0, 0, 0))
d = ImageDraw.Draw(img_j_trees)
for x in range(480):
    elev = int(190 + 15 * math.sin(x * 2 * math.pi / 160.0) + 8 * math.cos(x * 2 * math.pi / 80.0))
    d.line([(x, elev), (x, 270)], fill=(28, 85, 45, 255))
save_image(img_j_trees, "assets/sprites/bg_jungle_trees.png")

# B) FROZEN RUINS PARALLAX
# Sky: Pale arctic aurora sky
img_i_sky = Image.new("RGBA", (480, 270), (0, 0, 0, 0))
d = ImageDraw.Draw(img_i_sky)
for y in range(270):
    t = y / 270.0
    r = int(15 + 40 * t)
    g = int(30 + 70 * t)
    b = int(70 + 80 * t)
    d.line([(0, y), (479, y)], fill=(r, g, b, 255))
save_image(img_i_sky, "assets/sprites/bg_ice_sky.png")

# Distant snowy glaciers
img_i_peaks = Image.new("RGBA", (480, 270), (0, 0, 0, 0))
d = ImageDraw.Draw(img_i_peaks)
for x in range(480):
    elev = int(135 + 35 * abs(math.sin(x * math.pi / 240.0 + 0.3)))
    d.line([(x, elev), (x, 270)], fill=(40, 75, 115, 255))
    d.line([(x, elev), (x, elev + 10)], fill=(200, 235, 255, 255)) # snow caps
save_image(img_i_peaks, "assets/sprites/bg_ice_peaks.png")

# Fore ruins: crumbling stone monoliths covered in icicles
img_i_ruins = Image.new("RGBA", (480, 270), (0, 0, 0, 0))
d = ImageDraw.Draw(img_i_ruins)
for x in range(480):
    elev = int(195 + 12 * math.sin(x * 2 * math.pi / 120.0))
    d.line([(x, elev), (x, 270)], fill=(50, 95, 130, 255))
for rx in [80, 220, 360]:
    d.rectangle([rx - 15, 130, rx + 15, 270], fill=(45, 80, 110, 255))
    # icicles
    d.polygon([(rx - 15, 130), (rx + 15, 130), (rx, 155)], fill=(210, 245, 255, 255))
save_image(img_i_ruins, "assets/sprites/bg_ice_ruins.png")

# C) VOLCANIC UNDERWORLD PARALLAX
# Sky: Blood-red volcanic smog and ash
img_v_sky = Image.new("RGBA", (480, 270), (0, 0, 0, 0))
d = ImageDraw.Draw(img_v_sky)
for y in range(270):
    t = y / 270.0
    r = int(60 + 80 * t)
    g = int(15 + 25 * t)
    b = int(20 + 20 * t)
    d.line([(0, y), (479, y)], fill=(r, g, b, 255))
save_image(img_v_sky, "assets/sprites/bg_volcano_sky.png")

# Volcanic peaks with glowing caldera
img_v_mountains = Image.new("RGBA", (480, 270), (0, 0, 0, 0))
d = ImageDraw.Draw(img_v_mountains)
for x in range(480):
    elev = int(130 + 40 * math.sin(x * 2 * math.pi / 240.0 + 1.0))
    d.line([(x, elev), (x, 270)], fill=(45, 20, 25, 255))
# Glowing calderas
d.ellipse([140, 105, 180, 125], fill=(255, 80, 20, 255))
d.ellipse([340, 115, 380, 135], fill=(255, 110, 30, 255))
save_image(img_v_mountains, "assets/sprites/bg_volcano_mountains.png")

# Foreground basalt caves and jagged spires
img_v_caves = Image.new("RGBA", (480, 270), (0, 0, 0, 0))
d = ImageDraw.Draw(img_v_caves)
for x in range(480):
    elev = int(190 + 18 * abs(math.cos(x * 2 * math.pi / 90.0)))
    d.line([(x, elev), (x, 270)], fill=(32, 16, 20, 255))
save_image(img_v_caves, "assets/sprites/bg_volcano_caves.png")

print("All Session 7 World assets generated successfully.")
