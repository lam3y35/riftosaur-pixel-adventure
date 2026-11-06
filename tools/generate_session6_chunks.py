import os

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

# Chunk 16: Mechanical Wings Route
c16 = f"""[gd_scene load_steps=7 format=3]

[ext_resource type="Script" path="res://scripts/world/ground_chunk.gd" id="1_chunk"]
[ext_resource type="Texture2D" path="res://assets/sprites/ground_tile.png" id="2_tile"]
[ext_resource type="PackedScene" path="res://scenes/objects/flight_pickup_wings.tscn" id="3_wings"]
[ext_resource type="PackedScene" path="res://scenes/objects/collectible_gem.tscn" id="4_gem"]
[ext_resource type="PackedScene" path="res://scenes/obstacles/obstacle_storm_cloud.tscn" id="5_cloud"]
[ext_resource type="PackedScene" path="res://scenes/obstacles/obstacle_ground_low.tscn" id="6_low"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_ground"]
size = Vector2(480, 40)

[node name="ChunkFlightWingsRoute" type="Node2D"]
script = ExtResource("1_chunk")
pattern_name = "mechanical_wings_flight_route"
difficulty = 2

[node name="Ground" type="StaticBody2D" parent="."]
position = Vector2(0, 230)
collision_layer = 2
collision_mask = 1

[node name="CollisionShape2D" type="CollisionShape2D" parent="Ground"]
position = Vector2(240, 20)
shape = SubResource("RectangleShape2D_ground")

[node name="Tiles" type="Node2D" parent="Ground"]
{tiles_str}

[node name="Pickups" type="Node2D" parent="."]
[node name="WingsPickup" parent="Pickups" instance=ExtResource("3_wings")]
position = Vector2(80, 210)

[node name="Hazards" type="Node2D" parent="."]
[node name="GroundCactus" parent="Hazards" instance=ExtResource("6_low")]
position = Vector2(200, 230)

[node name="StormCloud" parent="Hazards" instance=ExtResource("5_cloud")]
position = Vector2(290, 110)

[node name="Collectibles" type="Node2D" parent="."]
[node name="Gem1" parent="Collectibles" instance=ExtResource("4_gem")]
position = Vector2(140, 130)

[node name="Gem2" parent="Collectibles" instance=ExtResource("4_gem")]
position = Vector2(180, 100)

[node name="Gem3" parent="Collectibles" instance=ExtResource("4_gem")]
position = Vector2(220, 90)

[node name="Gem4" parent="Collectibles" instance=ExtResource("4_gem")]
position = Vector2(350, 120)

[node name="Gem5" parent="Collectibles" instance=ExtResource("4_gem")]
position = Vector2(400, 150)
"""

with open("scenes/obstacles/chunks/chunk_16_flight_wings_route.tscn", "w", encoding="utf-8") as f:
    f.write(c16)

# Chunk 17: Rocket Relic Route
c17 = f"""[gd_scene load_steps=7 format=3]

[ext_resource type="Script" path="res://scripts/world/ground_chunk.gd" id="1_chunk"]
[ext_resource type="Texture2D" path="res://assets/sprites/ground_tile.png" id="2_tile"]
[ext_resource type="PackedScene" path="res://scenes/objects/flight_pickup_rocket.tscn" id="3_rocket"]
[ext_resource type="PackedScene" path="res://scenes/objects/collectible_gem.tscn" id="4_gem"]
[ext_resource type="PackedScene" path="res://scenes/obstacles/obstacle_pterodactyl.tscn" id="5_pter"]
[ext_resource type="PackedScene" path="res://scenes/objects/platform_one_way.tscn" id="6_plat"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_ground"]
size = Vector2(480, 40)

[node name="ChunkFlightRocketRoute" type="Node2D"]
script = ExtResource("1_chunk")
pattern_name = "rocket_relic_flight_route"
difficulty = 3

[node name="Ground" type="StaticBody2D" parent="."]
position = Vector2(0, 230)
collision_layer = 2
collision_mask = 1

[node name="CollisionShape2D" type="CollisionShape2D" parent="Ground"]
position = Vector2(240, 20)
shape = SubResource("RectangleShape2D_ground")

[node name="Tiles" type="Node2D" parent="Ground"]
{tiles_str}

[node name="Pickups" type="Node2D" parent="."]
[node name="RocketPickup" parent="Pickups" instance=ExtResource("3_rocket")]
position = Vector2(70, 210)

[node name="Hazards" type="Node2D" parent="."]
[node name="Pterodactyl" parent="Hazards" instance=ExtResource("5_pter")]
position = Vector2(250, 140)

[node name="Platforms" type="Node2D" parent="."]
[node name="LandingPlatform" parent="Platforms" instance=ExtResource("6_plat")]
position = Vector2(400, 188)

[node name="Collectibles" type="Node2D" parent="."]
[node name="Gem1" parent="Collectibles" instance=ExtResource("4_gem")]
position = Vector2(130, 110)

[node name="Gem2" parent="Collectibles" instance=ExtResource("4_gem")]
position = Vector2(180, 80)

[node name="Gem3" parent="Collectibles" instance=ExtResource("4_gem")]
position = Vector2(220, 80)

[node name="Gem4" parent="Collectibles" instance=ExtResource("4_gem")]
position = Vector2(320, 120)

[node name="Gem5" parent="Collectibles" instance=ExtResource("4_gem")]
position = Vector2(400, 168)
"""

with open("scenes/obstacles/chunks/chunk_17_flight_rocket_route.tscn", "w", encoding="utf-8") as f:
    f.write(c17)

print("Generated chunks 16 and 17 successfully.")
