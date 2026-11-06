import os

def generate_960_chunk_ruins():
    lines = [
        '[gd_scene load_steps=7 format=3]',
        '',
        '[ext_resource type="Script" path="res://scripts/world/ground_chunk.gd" id="1_chunk"]',
        '[ext_resource type="Texture2D" path="res://assets/sprites/ground_tile.png" id="2_tile"]',
        '[ext_resource type="PackedScene" path="res://scenes/objects/platform_one_way.tscn" id="3_oneway"]',
        '[ext_resource type="PackedScene" path="res://scenes/obstacles/obstacle_ground_low.tscn" id="4_low"]',
        '[ext_resource type="PackedScene" path="res://scenes/objects/collectible_gem.tscn" id="5_gem"]',
        '',
        '[sub_resource type="RectangleShape2D" id="RectangleShape2D_ground"]',
        'size = Vector2(960, 40)',
        '',
        '[node name="ChunkGrandRuinsGauntlet" type="Node2D"]',
        'script = ExtResource("1_chunk")',
        'pattern_name = "grand_ruins_gauntlet_960"',
        'difficulty = 4',
        'chunk_width = 960.0',
        'entry_height = 230.0',
        'entry_surface = "solid"',
        'exit_height = 230.0',
        'exit_surface = "solid"',
        'route_class = "challenging"',
        'difficulty_band = 4',
        'required_movement = ["run_and_jump"]',
        'allowed_worlds = ["plains", "jungle", "frozen", "volcanic"]',
        '',
        '[node name="Ground" type="StaticBody2D" parent="."] ',
        'position = Vector2(0, 230)',
        'collision_layer = 2',
        'collision_mask = 1',
        '',
        '[node name="CollisionShape2D" type="CollisionShape2D" parent="Ground"]',
        'position = Vector2(480, 20)',
        'shape = SubResource("RectangleShape2D_ground")',
        '',
        '[node name="Tiles" type="Node2D" parent="Ground"]'
    ]

    for i in range(60):
        lines.append(f'[node name="Tile_{i}" type="Sprite2D" parent="Ground/Tiles"]')
        lines.append(f'position = Vector2({i * 16 + 8}, 8)')
        lines.append('texture = ExtResource("2_tile")')
        lines.append('')

    # Platform 1: x=220, y=190 (rise 40px <= 49.6)
    lines.append('[node name="Platform1" parent="." instance=ExtResource("3_oneway")]')
    lines.append('position = Vector2(220, 190)')
    lines.append('')

    # Platform 2: x=460, y=190
    lines.append('[node name="Platform2" parent="." instance=ExtResource("3_oneway")]')
    lines.append('position = Vector2(460, 190)')
    lines.append('')

    # Platform 3: x=700, y=190
    lines.append('[node name="Platform3" parent="." instance=ExtResource("3_oneway")]')
    lines.append('position = Vector2(700, 190)')
    lines.append('')

    # Ground hurdles below platforms (lower route hazard)
    lines.append('[node name="Hazard1" parent="." instance=ExtResource("4_low")]')
    lines.append('position = Vector2(330, 230)')
    lines.append('')

    lines.append('[node name="Hazard2" parent="." instance=ExtResource("4_low")]')
    lines.append('position = Vector2(580, 230)')
    lines.append('')

    lines.append('[node name="Hazard3" parent="." instance=ExtResource("4_low")]')
    lines.append('position = Vector2(820, 230)')
    lines.append('')

    # Gems rewarding upper route
    lines.append('[node name="Gem1" parent="." instance=ExtResource("5_gem")]')
    lines.append('position = Vector2(220, 160)')
    lines.append('')
    lines.append('[node name="Gem2" parent="." instance=ExtResource("5_gem")]')
    lines.append('position = Vector2(460, 160)')
    lines.append('')
    lines.append('[node name="Gem3" parent="." instance=ExtResource("5_gem")]')
    lines.append('position = Vector2(700, 160)')
    lines.append('')

    with open("scenes/obstacles/chunks/chunk_18_grand_ruins_gauntlet.tscn", "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print("Generated chunk_18_grand_ruins_gauntlet.tscn (960px)")

def generate_960_chunk_volcanic():
    lines = [
        '[gd_scene load_steps=7 format=3]',
        '',
        '[ext_resource type="Script" path="res://scripts/world/ground_chunk.gd" id="1_chunk"]',
        '[ext_resource type="Texture2D" path="res://assets/sprites/ground_tile.png" id="2_tile"]',
        '[ext_resource type="PackedScene" path="res://scenes/objects/bounce_mushroom.tscn" id="3_bounce"]',
        '[ext_resource type="PackedScene" path="res://scenes/objects/platform_one_way.tscn" id="4_oneway"]',
        '[ext_resource type="PackedScene" path="res://scenes/obstacles/obstacle_ground_low.tscn" id="5_low"]',
        '[ext_resource type="PackedScene" path="res://scenes/objects/collectible_gem.tscn" id="6_gem"]',
        '',
        '[sub_resource type="RectangleShape2D" id="RectangleShape2D_ground"]',
        'size = Vector2(960, 40)',
        '',
        '[node name="ChunkVolcanicAerialChasm" type="Node2D"]',
        'script = ExtResource("1_chunk")',
        'pattern_name = "volcanic_aerial_chasm_960"',
        'difficulty = 5',
        'chunk_width = 960.0',
        'entry_height = 230.0',
        'entry_surface = "solid"',
        'exit_height = 230.0',
        'exit_surface = "solid"',
        'route_class = "optional_reward"',
        'difficulty_band = 5',
        'required_movement = ["run_and_jump", "bounce"]',
        'allowed_worlds = ["plains", "jungle", "frozen", "volcanic"]',
        '',
        '[node name="Ground" type="StaticBody2D" parent="."] ',
        'position = Vector2(0, 230)',
        'collision_layer = 2',
        'collision_mask = 1',
        '',
        '[node name="CollisionShape2D" type="CollisionShape2D" parent="Ground"]',
        'position = Vector2(480, 20)',
        'shape = SubResource("RectangleShape2D_ground")',
        '',
        '[node name="Tiles" type="Node2D" parent="Ground"]'
    ]

    for i in range(60):
        lines.append(f'[node name="Tile_{i}" type="Sprite2D" parent="Ground/Tiles"]')
        lines.append(f'position = Vector2({i * 16 + 8}, 8)')
        lines.append('texture = ExtResource("2_tile")')
        lines.append('')

    # Bounce pad at x=160 launch to elevated platform at x=280 y=160
    lines.append('[node name="BouncePad" parent="." instance=ExtResource("3_bounce")]')
    lines.append('position = Vector2(160, 230)')
    lines.append('')

    lines.append('[node name="HighPlatform1" parent="." instance=ExtResource("4_oneway")]')
    lines.append('position = Vector2(280, 160)')
    lines.append('')

    # Second bounce pad at x=380 launching to HighPlatform2
    lines.append('[node name="BouncePad2" parent="." instance=ExtResource("3_bounce")]')
    lines.append('position = Vector2(380, 230)')
    lines.append('')

    lines.append('[node name="HighPlatform2" parent="." instance=ExtResource("4_oneway")]')
    lines.append('position = Vector2(480, 160)')
    lines.append('')

    lines.append('[node name="StepPlatform" parent="." instance=ExtResource("4_oneway")]')
    lines.append('position = Vector2(680, 188)')
    lines.append('')

    # Ground hazards
    lines.append('[node name="Hazard1" parent="." instance=ExtResource("5_low")]')
    lines.append('position = Vector2(380, 230)')
    lines.append('')

    lines.append('[node name="Hazard2" parent="." instance=ExtResource("5_low")]')
    lines.append('position = Vector2(580, 230)')
    lines.append('')

    lines.append('[node name="Hazard3" parent="." instance=ExtResource("5_low")]')
    lines.append('position = Vector2(820, 230)')
    lines.append('')

    # Aerial gems
    for gx in [280, 380, 480, 580, 680]:
        lines.append(f'[node name="Gem_{gx}" parent="." instance=ExtResource("6_gem")]')
        lines.append(f'position = Vector2({gx}, 130)')
        lines.append('')

    with open("scenes/obstacles/chunks/chunk_19_volcanic_aerial_chasm.tscn", "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print("Generated chunk_19_volcanic_aerial_chasm.tscn (960px)")

def generate_pattern_resources():
    os.makedirs("resources/patterns", exist_ok=True)

    # Define pattern configurations
    patterns = [
        # (id, scene, width, worlds, band, speed_range, movement, route_class)
        ("p00_world_transition", "res://scenes/obstacles/chunks/chunk_00_world_transition.tscn", 480.0, ["plains", "jungle", "frozen", "volcanic"], 1, (250, 520), ["none"], "safe"),
        ("p01_safe_breather", "res://scenes/obstacles/chunks/chunk_01_empty.tscn", 480.0, ["plains", "jungle", "frozen", "volcanic"], 1, (250, 520), ["none"], "safe"),
        ("p02_single_low_hop", "res://scenes/obstacles/chunks/chunk_02_single_low.tscn", 480.0, ["plains", "jungle", "frozen", "volcanic"], 1, (250, 360), ["run_and_jump"], "safe"),
        ("p03_stone_arch_slide", "res://scenes/obstacles/chunks/chunk_03_overhang.tscn", 480.0, ["plains", "jungle", "frozen", "volcanic"], 2, (280, 420), ["slide"], "challenging"),
        ("p04_double_low_rhythm", "res://scenes/obstacles/chunks/chunk_04_double_low.tscn", 480.0, ["plains", "jungle", "frozen", "volcanic"], 2, (280, 420), ["run_and_jump"], "safe"),
        ("p05_jump_and_slide", "res://scenes/obstacles/chunks/chunk_05_jump_and_slide.tscn", 480.0, ["plains", "jungle", "frozen", "volcanic"], 3, (320, 460), ["run_and_jump", "slide"], "challenging"),
        ("p06_crate_step_hurdle", "res://scenes/obstacles/chunks/chunk_06_crate_step.tscn", 480.0, ["plains", "jungle", "frozen", "volcanic"], 2, (280, 420), ["run_and_jump"], "safe"),
        ("p07_triple_low_hurdles", "res://scenes/obstacles/chunks/chunk_07_triple_low.tscn", 480.0, ["plains", "jungle", "frozen", "volcanic"], 3, (350, 480), ["run_and_jump"], "challenging"),
        ("p08_double_crate_stair", "res://scenes/obstacles/chunks/chunk_08_double_crate.tscn", 480.0, ["plains", "jungle", "frozen", "volcanic"], 2, (280, 420), ["run_and_jump"], "safe"),
        ("p09_mushroom_bounce", "res://scenes/obstacles/chunks/chunk_09_mushroom_bounce.tscn", 480.0, ["plains", "jungle", "frozen", "volcanic"], 3, (320, 460), ["bounce"], "optional_reward"),
        ("p10_multi_tier_platforms", "res://scenes/obstacles/chunks/chunk_10_multi_tier_platforms.tscn", 480.0, ["plains", "jungle", "frozen", "volcanic"], 4, (370, 500), ["run_and_jump"], "challenging"),
        ("p11_bounce_pad_chain", "res://scenes/obstacles/chunks/chunk_11_bounce_chain.tscn", 480.0, ["plains", "jungle", "frozen", "volcanic"], 4, (370, 500), ["bounce"], "optional_reward"),
        ("p12_wind_vent_ascent", "res://scenes/obstacles/chunks/chunk_12_wind_vent_ascent.tscn", 480.0, ["plains", "jungle", "frozen", "volcanic"], 4, (370, 500), ["bounce"], "optional_reward"),
        ("p13_airborne_pterodactyl", "res://scenes/obstacles/chunks/chunk_13_airborne_pterodactyl.tscn", 480.0, ["plains", "jungle", "frozen", "volcanic"], 3, (350, 480), ["run_and_jump"], "challenging"),
        ("p14_crawler_and_barrier", "res://scenes/obstacles/chunks/chunk_14_crawler_and_barrier.tscn", 480.0, ["plains", "jungle", "frozen", "volcanic"], 3, (350, 480), ["run_and_jump"], "challenging"),
        ("p15_skill_gem_cache", "res://scenes/obstacles/chunks/chunk_15_skill_gem_cache.tscn", 480.0, ["plains", "jungle", "frozen", "volcanic"], 4, (370, 500), ["run_and_jump"], "optional_reward"),
        ("p16_flight_wings_route", "res://scenes/obstacles/chunks/chunk_16_flight_wings_route.tscn", 480.0, ["plains", "jungle", "frozen", "volcanic"], 4, (370, 500), ["flight"], "optional_reward"),
        ("p17_flight_rocket_route", "res://scenes/obstacles/chunks/chunk_17_flight_rocket_route.tscn", 480.0, ["plains", "jungle", "frozen", "volcanic"], 5, (420, 520), ["flight"], "optional_reward"),
        ("p18_grand_ruins_gauntlet", "res://scenes/obstacles/chunks/chunk_18_grand_ruins_gauntlet.tscn", 960.0, ["plains", "jungle", "frozen", "volcanic"], 4, (380, 520), ["run_and_jump"], "challenging"),
        ("p19_volcanic_aerial_chasm", "res://scenes/obstacles/chunks/chunk_19_volcanic_aerial_chasm.tscn", 960.0, ["plains", "jungle", "frozen", "volcanic"], 5, (420, 520), ["run_and_jump", "bounce"], "optional_reward"),
    ]

    for pid, scene, width, worlds, band, (min_spd, max_spd), mov, rclass in patterns:
        worlds_str = '["' + '", "'.join(worlds) + '"]'
        mov_str = '["' + '", "'.join(mov) + '"]'
        tres_content = f"""[gd_resource type="Resource" script_class="LevelPattern" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/world/level_pattern.gd" id="1_pattern"]

[resource]
script = ExtResource("1_pattern")
pattern_id = "{pid}"
chunk_scene_path = "{scene}"
chunk_width = {width:.1f}
world_ids = {worlds_str}
difficulty_band = {band}
speed_range = Vector2({min_spd:.1f}, {max_spd:.1f})
required_movement = {mov_str}
route_class = "{rclass}"
entry_height = 230.0
entry_surface = "solid"
exit_height = 230.0
exit_surface = "solid"
requires_skill = false
skill_type = ""
"""
        filepath = f"resources/patterns/{pid}.tres"
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(tres_content)
        print(f"Generated {filepath}")

if __name__ == "__main__":
    generate_960_chunk_ruins()
    generate_960_chunk_volcanic()
    generate_pattern_resources()
