import os

os.makedirs("resources/themes", exist_ok=True)

themes = [
    {
        "filename": "theme_01_plains.tres",
        "id": "plains",
        "name": "Prehistoric Plains",
        "intro": "Clear silhouettes, cactus hurdles, and high-speed running",
        "sky": "res://assets/sprites/bg_sky.png",
        "dist": "res://assets/sprites/bg_mountains.png",
        "mid": "res://assets/sprites/bg_hills.png",
        "ground": "res://assets/sprites/ground_tile.png",
        "tint": "Color(1, 1, 1, 1)",
        "mod": "NONE",
        "dist_m": 250.0
    },
    {
        "filename": "theme_02_jungle.tres",
        "id": "jungle",
        "name": "Overgrown Jungle",
        "intro": "Dense vegetation with elevated canopy routes and bonus pickups",
        "sky": "res://assets/sprites/bg_jungle_sky.png",
        "dist": "res://assets/sprites/bg_jungle_canopy.png",
        "mid": "res://assets/sprites/bg_jungle_trees.png",
        "ground": "res://assets/sprites/ground_tile_jungle.png",
        "tint": "Color(0.85, 1.05, 0.9, 1)",
        "mod": "CANOPY_ROUTES",
        "dist_m": 500.0
    },
    {
        "filename": "theme_03_frozen.tres",
        "id": "frozen",
        "name": "Frozen Ruins",
        "intro": "Sub-zero glaciers, frost platforms, and icy slide segments",
        "sky": "res://assets/sprites/bg_ice_sky.png",
        "dist": "res://assets/sprites/bg_ice_peaks.png",
        "mid": "res://assets/sprites/bg_ice_ruins.png",
        "ground": "res://assets/sprites/ground_tile_ice.png",
        "tint": "Color(0.9, 0.95, 1.15, 1)",
        "mod": "SLIPPERY_SURFACES",
        "dist_m": 750.0
    },
    {
        "filename": "theme_04_volcanic.tres",
        "id": "volcanic",
        "name": "Volcanic Underworld",
        "intro": "Dark basalt, bubbling lava pits, and fiery rising magma",
        "sky": "res://assets/sprites/bg_volcano_sky.png",
        "dist": "res://assets/sprites/bg_volcano_mountains.png",
        "mid": "res://assets/sprites/bg_volcano_caves.png",
        "ground": "res://assets/sprites/ground_tile_volcano.png",
        "tint": "Color(1.15, 0.85, 0.8, 1)",
        "mod": "VOLCANIC_ERUPTIONS",
        "dist_m": 1000.0
    }
]

for t in themes:
    content = f"""[gd_resource type="Resource" script_class="WorldTheme" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/world/world_theme.gd" id="1_theme"]

[resource]
script = ExtResource("1_theme")
world_id = "{t['id']}"
world_name = "{t['name']}"
mechanic_intro = "{t['intro']}"
sky_texture_path = "{t['sky']}"
distant_texture_path = "{t['dist']}"
mid_texture_path = "{t['mid']}"
ground_tile_path = "{t['ground']}"
ambient_tint = {t['tint']}
gameplay_modifier = "{t['mod']}"
transition_distance_m = {t['dist_m']}
"""
    p = os.path.join("resources/themes", t["filename"])
    with open(p, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"Generated {p}")
