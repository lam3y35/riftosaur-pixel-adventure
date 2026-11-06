import os
from PIL import Image, ImageDraw

os.makedirs("assets/sprites", exist_ok=True)

def save_image(img, path):
    img.save(path)
    print(f"Generated {path} ({img.width}x{img.height})")

# 1. Pickup: Mechanical Wings (24x24)
img_wings = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
draw = ImageDraw.Draw(img_wings)
# Glowing orb background
draw.ellipse([2, 2, 21, 21], fill=(20, 60, 90, 200), outline=(80, 190, 255, 255))
# Mechanical wings icon: metallic cyan/brass wings
# Left wing
draw.polygon([(11, 11), (5, 6), (3, 10), (7, 13), (11, 13)], fill=(0, 230, 255, 255), outline=(255, 255, 255, 255))
# Right wing
draw.polygon([(12, 11), (18, 6), (20, 10), (16, 13), (12, 13)], fill=(0, 230, 255, 255), outline=(255, 255, 255, 255))
# Central gear/pivot
draw.ellipse([10, 10, 13, 13], fill=(255, 215, 0, 255))
save_image(img_wings, "assets/sprites/pickup_flight_wings.png")

# 2. Pickup: Rocket Relic (24x24)
img_rocket = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
draw = ImageDraw.Draw(img_rocket)
# Glowing orb background (fiery orange/red)
draw.ellipse([2, 2, 21, 21], fill=(80, 30, 15, 200), outline=(255, 120, 40, 255))
# Rocket body
draw.polygon([(11, 4), (13, 4), (15, 9), (15, 16), (9, 16), (9, 9)], fill=(220, 220, 230, 255), outline=(100, 100, 120, 255))
# Nosecone
draw.polygon([(11, 4), (13, 4), (12, 2)], fill=(255, 50, 50, 255))
# Fins
draw.polygon([(8, 14), (9, 14), (9, 17), (7, 18)], fill=(255, 60, 40, 255))
draw.polygon([(15, 14), (16, 14), (17, 18), (15, 17)], fill=(255, 60, 40, 255))
# Flame
draw.polygon([(10, 17), (14, 17), (12, 21)], fill=(255, 220, 0, 255))
save_image(img_rocket, "assets/sprites/pickup_flight_rocket.png")

# 3. Flight Wings Animation (4 frames, 32x32 each = 128x32 spritesheet)
# Frame 0: Wings high
# Frame 1: Wings mid-glide
# Frame 2: Wings downstroke
# Frame 3: Wings returning mid
img_wings_anim = Image.new("RGBA", (128, 32), (0, 0, 0, 0))
draw_wa = ImageDraw.Draw(img_wings_anim)

wing_coords = [
    # Frame 0: High
    [((12, 14), (2, 4), (5, 2), (14, 10)), ((18, 14), (28, 4), (25, 2), (16, 10))],
    # Frame 1: Mid
    [((12, 16), (3, 12), (5, 10), (14, 14)), ((18, 16), (27, 12), (25, 10), (16, 14))],
    # Frame 2: Low downstroke
    [((12, 18), (4, 24), (7, 26), (14, 18)), ((18, 18), (26, 24), (23, 26), (16, 18))],
    # Frame 3: Mid returning
    [((12, 16), (3, 13), (6, 11), (14, 15)), ((18, 16), (27, 13), (24, 11), (16, 15))]
]

for frame_idx, (left_wing, right_wing) in enumerate(wing_coords):
    ox = frame_idx * 32
    # Shift x
    lw = [(p[0] + ox, p[1]) for p in left_wing]
    rw = [(p[0] + ox, p[1]) for p in right_wing]
    # Draw left wing
    draw_wa.polygon(lw, fill=(0, 220, 255, 240), outline=(255, 255, 255, 255))
    # Draw right wing
    draw_wa.polygon(rw, fill=(0, 180, 230, 240), outline=(220, 240, 255, 255))
    # Mechanical brace
    draw_wa.line([(12 + ox, 16), (18 + ox, 16)], fill=(255, 215, 0, 255), width=2)

save_image(img_wings_anim, "assets/sprites/flight_wings_anim.png")

# 4. Flight Rocket Thruster Animation (4 frames, 16x16 each = 64x16 spritesheet)
img_flame = Image.new("RGBA", (64, 16), (0, 0, 0, 0))
draw_flame = ImageDraw.Draw(img_flame)
flame_lengths = [8, 12, 10, 14]
for f_idx, flen in enumerate(flame_lengths):
    ox = f_idx * 16
    # Outer orange flame
    draw_flame.polygon([(5 + ox, 2), (11 + ox, 2), (8 + ox, 2 + flen)], fill=(255, 100, 20, 240))
    # Inner yellow core
    draw_flame.polygon([(6 + ox, 2), (10 + ox, 2), (8 + ox, 2 + flen - 3)], fill=(255, 240, 60, 255))
    # White hot root
    draw_flame.ellipse([6 + ox, 1, 10 + ox, 4], fill=(255, 255, 255, 255))

save_image(img_flame, "assets/sprites/flight_flame_anim.png")

# 5. Airborne Sky Hazard: Storm Cloud (36x24)
img_cloud = Image.new("RGBA", (36, 24), (0, 0, 0, 0))
draw_cloud = ImageDraw.Draw(img_cloud)
# Dark storm cloud puffs
draw_cloud.ellipse([4, 6, 18, 18], fill=(60, 65, 80, 240))
draw_cloud.ellipse([14, 2, 28, 18], fill=(75, 80, 95, 240))
draw_cloud.ellipse([20, 6, 34, 18], fill=(55, 60, 75, 240))
draw_cloud.ellipse([8, 10, 26, 20], fill=(50, 55, 70, 255))
# Glowing lightning sparks inside
draw_cloud.polygon([(16, 12), (14, 18), (17, 17), (15, 23)], fill=(255, 235, 50, 255))
draw_cloud.polygon([(24, 10), (22, 15), (25, 14), (23, 19)], fill=(120, 230, 255, 255))
save_image(img_cloud, "assets/sprites/obstacle_storm_cloud.png")

print("All Session 6 assets generated successfully.")
