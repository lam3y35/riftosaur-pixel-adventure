def generate_tiles():
    out = []
    for i in range(30):
        x = 8 + i * 16
        out.append(f"""[node name="Tile_{i}" type="Sprite2D" parent="Ground/Tiles"]
position = Vector2({x}, 8)
texture = ExtResource("2_tile")
""")
    return "\n".join(out)

tiles_str = generate_tiles()

c00 = f"""[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/world/ground_chunk.gd" id="1_chunk"]
[ext_resource type="Texture2D" path="res://assets/sprites/ground_tile.png" id="2_tile"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_ground"]
size = Vector2(480, 40)

[node name="ChunkWorldTransition" type="Node2D"]
script = ExtResource("1_chunk")
pattern_name = "safe_world_transition_runway"
difficulty = 1

[node name="Ground" type="StaticBody2D" parent="."]
position = Vector2(0, 230)
collision_layer = 2
collision_mask = 1

[node name="CollisionShape2D" type="CollisionShape2D" parent="Ground"]
position = Vector2(240, 20)
shape = SubResource("RectangleShape2D_ground")

[node name="Tiles" type="Node2D" parent="Ground"]
{tiles_str}
"""

with open("scenes/obstacles/chunks/chunk_00_world_transition.tscn", "w", encoding="utf-8") as f:
    f.write(c00)

print("Generated chunk_00_world_transition.tscn successfully.")
