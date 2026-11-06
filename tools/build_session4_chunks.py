"""
Builds Session 4 vertical platform and bounce chunks for Riftosaur.
Generates:
  - chunk_09_mushroom_bounce.tscn
  - chunk_10_multi_tier_platforms.tscn
  - chunk_11_bounce_chain.tscn
  - chunk_12_wind_vent_ascent.tscn
"""

import os

def create_ground_tiles(indent=""):
    tiles_str = ""
    for i in range(30):
        x = i * 16 + 8
        tiles_str += f"""{indent}[node name="Tile_{i}" type="Sprite2D" parent="Ground/Tiles"]
{indent}position = Vector2({x}, 8)
{indent}texture = ExtResource("2_tile")

"""
    return tiles_str

def build_chunk_09():
    content = f"""[gd_scene load_steps=7 format=3]

[ext_resource type="Script" path="res://scripts/world/ground_chunk.gd" id="1_chunk"]
[ext_resource type="Texture2D" path="res://assets/sprites/ground_tile.png" id="2_tile"]
[ext_resource type="PackedScene" path="res://scenes/objects/bounce_mushroom.tscn" id="3_shroom"]
[ext_resource type="PackedScene" path="res://scenes/obstacles/obstacle_ground_low.tscn" id="4_low"]
[ext_resource type="PackedScene" path="res://scenes/objects/platform_solid.tscn" id="5_plat"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_ground"]
size = Vector2(480, 40)

[node name="ChunkMushroomBounce" type="Node2D"]
script = ExtResource("1_chunk")
pattern_name = "mushroom_bounce_to_high_ledge"
difficulty = 2

[node name="Ground" type="StaticBody2D" parent="."]
position = Vector2(0, 230)
collision_layer = 2
collision_mask = 1

[node name="CollisionShape2D" type="CollisionShape2D" parent="Ground"]
position = Vector2(240, 20)
shape = SubResource("RectangleShape2D_ground")

[node name="Tiles" type="Node2D" parent="Ground"]
{create_ground_tiles()}
[node name="Springs" type="Node2D" parent="."]
[node name="BounceMushroom" parent="Springs" instance=ExtResource("3_shroom")]
position = Vector2(130, 230)

[node name="Hazards" type="Node2D" parent="."]
[node name="Hazard_Spikes" parent="Hazards" instance=ExtResource("4_low")]
position = Vector2(200, 230)

[node name="Platforms" type="Node2D" parent="."]
[node name="PlatformSolid" parent="Platforms" instance=ExtResource("5_plat")]
position = Vector2(250, 180)
"""
    with open("scenes/obstacles/chunks/chunk_09_mushroom_bounce.tscn", "w") as f:
        f.write(content)
    print("Created chunk_09_mushroom_bounce.tscn")

def build_chunk_10():
    content = f"""[gd_scene load_steps=6 format=3]

[ext_resource type="Script" path="res://scripts/world/ground_chunk.gd" id="1_chunk"]
[ext_resource type="Texture2D" path="res://assets/sprites/ground_tile.png" id="2_tile"]
[ext_resource type="PackedScene" path="res://scenes/objects/platform_one_way.tscn" id="3_oneway"]
[ext_resource type="PackedScene" path="res://scenes/obstacles/obstacle_ground_low.tscn" id="4_low"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_ground"]
size = Vector2(480, 40)

[node name="ChunkMultiTierPlatforms" type="Node2D"]
script = ExtResource("1_chunk")
pattern_name = "multi_tier_oneway_platform_routes"
difficulty = 2

[node name="Ground" type="StaticBody2D" parent="."]
position = Vector2(0, 230)
collision_layer = 2
collision_mask = 1

[node name="CollisionShape2D" type="CollisionShape2D" parent="Ground"]
position = Vector2(240, 20)
shape = SubResource("RectangleShape2D_ground")

[node name="Tiles" type="Node2D" parent="Ground"]
{create_ground_tiles()}
[node name="Hazards" type="Node2D" parent="."]
[node name="Hazard_0" parent="Hazards" instance=ExtResource("4_low")]
position = Vector2(220, 230)

[node name="Hazard_1" parent="Hazards" instance=ExtResource("4_low")]
position = Vector2(340, 230)

[node name="Platforms" type="Node2D" parent="."]
[node name="Platform_Lower" parent="Platforms" instance=ExtResource("3_oneway")]
position = Vector2(160, 190)

[node name="Platform_Upper" parent="Platforms" instance=ExtResource("3_oneway")]
position = Vector2(280, 155)
"""
    with open("scenes/obstacles/chunks/chunk_10_multi_tier_platforms.tscn", "w") as f:
        f.write(content)
    print("Created chunk_10_multi_tier_platforms.tscn")

def build_chunk_11():
    content = f"""[gd_scene load_steps=8 format=3]

[ext_resource type="Script" path="res://scripts/world/ground_chunk.gd" id="1_chunk"]
[ext_resource type="Texture2D" path="res://assets/sprites/ground_tile.png" id="2_tile"]
[ext_resource type="PackedScene" path="res://scenes/objects/bounce_stump.tscn" id="3_stump"]
[ext_resource type="PackedScene" path="res://scenes/objects/platform_one_way.tscn" id="4_oneway"]
[ext_resource type="PackedScene" path="res://scenes/objects/bounce_launchpad.tscn" id="5_pad"]
[ext_resource type="PackedScene" path="res://scenes/obstacles/obstacle_ground_low.tscn" id="6_low"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_ground"]
size = Vector2(480, 40)

[node name="ChunkBounceChain" type="Node2D"]
script = ExtResource("1_chunk")
pattern_name = "bounce_chain_across_crystal_chasms"
difficulty = 3

[node name="Ground" type="StaticBody2D" parent="."]
position = Vector2(0, 230)
collision_layer = 2
collision_mask = 1

[node name="CollisionShape2D" type="CollisionShape2D" parent="Ground"]
position = Vector2(240, 20)
shape = SubResource("RectangleShape2D_ground")

[node name="Tiles" type="Node2D" parent="Ground"]
{create_ground_tiles()}
[node name="Springs" type="Node2D" parent="."]
[node name="BounceStump" parent="Springs" instance=ExtResource("3_stump")]
position = Vector2(120, 230)

[node name="BounceLaunchpad" parent="Springs" instance=ExtResource("5_pad")]
position = Vector2(320, 230)

[node name="Hazards" type="Node2D" parent="."]
[node name="Hazard_0" parent="Hazards" instance=ExtResource("6_low")]
position = Vector2(210, 230)

[node name="Hazard_1" parent="Hazards" instance=ExtResource("6_low")]
position = Vector2(410, 230)

[node name="Platforms" type="Node2D" parent="."]
[node name="PlatformOneWay" parent="Platforms" instance=ExtResource("4_oneway")]
position = Vector2(220, 175)
"""
    with open("scenes/obstacles/chunks/chunk_11_bounce_chain.tscn", "w") as f:
        f.write(content)
    print("Created chunk_11_bounce_chain.tscn")

def build_chunk_12():
    content = f"""[gd_scene load_steps=7 format=3]

[ext_resource type="Script" path="res://scripts/world/ground_chunk.gd" id="1_chunk"]
[ext_resource type="Texture2D" path="res://assets/sprites/ground_tile.png" id="2_tile"]
[ext_resource type="PackedScene" path="res://scenes/objects/boost_wind_vent.tscn" id="3_vent"]
[ext_resource type="PackedScene" path="res://scenes/objects/platform_solid.tscn" id="4_solid"]
[ext_resource type="PackedScene" path="res://scenes/obstacles/obstacle_overhang.tscn" id="5_high"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_ground"]
size = Vector2(480, 40)

[node name="ChunkWindVentAscent" type="Node2D"]
script = ExtResource("1_chunk")
pattern_name = "wind_vent_high_terrace_bypass"
difficulty = 3

[node name="Ground" type="StaticBody2D" parent="."]
position = Vector2(0, 230)
collision_layer = 2
collision_mask = 1

[node name="CollisionShape2D" type="CollisionShape2D" parent="Ground"]
position = Vector2(240, 20)
shape = SubResource("RectangleShape2D_ground")

[node name="Tiles" type="Node2D" parent="Ground"]
{create_ground_tiles()}
[node name="Springs" type="Node2D" parent="."]
[node name="BoostWindVent" parent="Springs" instance=ExtResource("3_vent")]
position = Vector2(130, 230)

[node name="Platforms" type="Node2D" parent="."]
[node name="PlatformSolid" parent="Platforms" instance=ExtResource("4_solid")]
position = Vector2(250, 165)

[node name="Hazards" type="Node2D" parent="."]
[node name="Hazard_Overhang" parent="Hazards" instance=ExtResource("5_high")]
position = Vector2(380, 230)
"""
    with open("scenes/obstacles/chunks/chunk_12_wind_vent_ascent.tscn", "w") as f:
        f.write(content)
    print("Created chunk_12_wind_vent_ascent.tscn")

def main():
    build_chunk_09()
    build_chunk_10()
    build_chunk_11()
    build_chunk_12()

if __name__ == "__main__":
    main()
