"""
Builds hand-authored ground-obstacle chunk scenes for Riftosaur.
Each chunk is 480px wide with solid ground collision and hand-authored hazard placements.
"""

import os

os.makedirs("scenes/obstacles/chunks", exist_ok=True)

CHUNKS = [
    {
        "filename": "chunk_01_empty.tscn",
        "name": "ChunkEmpty",
        "pattern": "empty_breather",
        "difficulty": 1,
        "hazards": []
    },
    {
        "filename": "chunk_02_single_low.tscn",
        "name": "ChunkSingleLow",
        "pattern": "single_low_hop",
        "difficulty": 1,
        "hazards": [
            ("low", 240.0)
        ]
    },
    {
        "filename": "chunk_03_overhang.tscn",
        "name": "ChunkOverhang",
        "pattern": "single_overhang_slide",
        "difficulty": 1,
        "hazards": [
            ("high", 240.0)
        ]
    },
    {
        "filename": "chunk_04_double_low.tscn",
        "name": "ChunkDoubleLow",
        "pattern": "double_low_rhythm",
        "difficulty": 2,
        "hazards": [
            ("low", 160.0),
            ("low", 320.0)
        ]
    },
    {
        "filename": "chunk_05_jump_and_slide.tscn",
        "name": "ChunkJumpAndSlide",
        "pattern": "hop_then_slide_combo",
        "difficulty": 2,
        "hazards": [
            ("low", 140.0),
            ("high", 340.0)
        ]
    }
]

def make_chunk_tscn(cfg):
    load_steps = 4
    has_low = any(h[0] == "low" for h in cfg["hazards"])
    has_high = any(h[0] == "high" for h in cfg["hazards"])

    ext_res = [
        '[ext_resource type="Script" path="res://scripts/world/ground_chunk.gd" id="1_chunk"]',
        '[ext_resource type="Texture2D" path="res://assets/sprites/ground_tile.png" id="2_tile"]'
    ]
    ext_map = {"tile": "ExtResource(\"2_tile\")"}

    res_id = 3
    if has_low:
        ext_res.append(f'[ext_resource type="PackedScene" path="res://scenes/obstacles/obstacle_ground_low.tscn" id="{res_id}_low"]')
        ext_map["low"] = f'ExtResource("{res_id}_low")'
        res_id += 1
    if has_high:
        ext_res.append(f'[ext_resource type="PackedScene" path="res://scenes/obstacles/obstacle_overhang.tscn" id="{res_id}_high"]')
        ext_map["high"] = f'ExtResource("{res_id}_high")'
        res_id += 1

    content = f"""[gd_scene load_steps={res_id + 1} format=3]

""" + "\n".join(ext_res) + f"""

[sub_resource type="RectangleShape2D" id="RectangleShape2D_ground"]
size = Vector2(480, 40)

[node name="{cfg['name']}" type="Node2D"]
script = ExtResource("1_chunk")
pattern_name = "{cfg['pattern']}"
difficulty = {cfg['difficulty']}

[node name="Ground" type="StaticBody2D" parent="."]
position = Vector2(0, 230)
collision_layer = 2
collision_mask = 1

[node name="CollisionShape2D" type="CollisionShape2D" parent="Ground"]
position = Vector2(240, 20)
shape = SubResource("RectangleShape2D_ground")

[node name="Tiles" type="Node2D" parent="Ground"]
"""
    # 30 tiles across 480 px
    for i in range(30):
        x = i * 16 + 8
        content += f"""[node name="Tile_{i}" type="Sprite2D" parent="Ground/Tiles"]
position = Vector2({x}, 8)
texture = {ext_map['tile']}

"""

    content += """[node name="Hazards" type="Node2D" parent="."]
"""
    for idx, (h_type, h_x) in enumerate(cfg["hazards"]):
        scene_ref = ext_map[h_type]
        content += f"""[node name="Hazard_{idx}" parent="Hazards" instance={scene_ref}]
position = Vector2({h_x}, 230)

"""

    with open(f"scenes/obstacles/chunks/{cfg['filename']}", "w") as f:
        f.write(content)
    print(f"Created chunk: scenes/obstacles/chunks/{cfg['filename']}")

for c in CHUNKS:
    make_chunk_tscn(c)
