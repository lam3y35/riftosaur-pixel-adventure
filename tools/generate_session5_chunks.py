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

# Chunk 13: Airborne Pterodactyl with airborne gems
c13 = f"""[gd_scene load_steps=6 format=3]

[ext_resource type="Script" path="res://scripts/world/ground_chunk.gd" id="1_chunk"]
[ext_resource type="Texture2D" path="res://assets/sprites/ground_tile.png" id="2_tile"]
[ext_resource type="PackedScene" path="res://scenes/obstacles/obstacle_pterodactyl.tscn" id="3_pter"]
[ext_resource type="PackedScene" path="res://scenes/objects/collectible_gem.tscn" id="4_gem"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_ground"]
size = Vector2(480, 40)

[node name="ChunkAirbornePterodactyl" type="Node2D"]
script = ExtResource("1_chunk")
pattern_name = "airborne_pterodactyl_hunt"
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

[node name="Hazards" type="Node2D" parent="."]
[node name="Pterodactyl" parent="Hazards" instance=ExtResource("3_pter")]
position = Vector2(300, 185)

[node name="Collectibles" type="Node2D" parent="."]
[node name="Gem1" parent="Collectibles" instance=ExtResource("4_gem")]
position = Vector2(160, 210)

[node name="Gem2" parent="Collectibles" instance=ExtResource("4_gem")]
position = Vector2(210, 195)

[node name="Gem3" parent="Collectibles" instance=ExtResource("4_gem")]
position = Vector2(260, 210)
"""

with open("scenes/obstacles/chunks/chunk_13_airborne_pterodactyl.tscn", "w", encoding="utf-8") as f:
    f.write(c13)

# Chunk 14: Crawler and Wooden Barrier with Skill Pickup
c14 = f"""[gd_scene load_steps=7 format=3]

[ext_resource type="Script" path="res://scripts/world/ground_chunk.gd" id="1_chunk"]
[ext_resource type="Texture2D" path="res://assets/sprites/ground_tile.png" id="2_tile"]
[ext_resource type="PackedScene" path="res://scenes/obstacles/obstacle_crawler.tscn" id="3_crawl"]
[ext_resource type="PackedScene" path="res://scenes/obstacles/obstacle_wooden_barrier.tscn" id="4_bar"]
[ext_resource type="PackedScene" path="res://scenes/objects/skill_pickup.tscn" id="5_skill"]
[ext_resource type="PackedScene" path="res://scenes/objects/collectible_gem.tscn" id="6_gem"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_ground"]
size = Vector2(480, 40)

[node name="ChunkCrawlerAndBarrier" type="Node2D"]
script = ExtResource("1_chunk")
pattern_name = "crawler_and_barrier_run"
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

[node name="Hazards" type="Node2D" parent="."]
[node name="Crawler" parent="Hazards" instance=ExtResource("3_crawl")]
position = Vector2(200, 222)

[node name="Barrier" parent="Hazards" instance=ExtResource("4_bar")]
position = Vector2(340, 214)

[node name="Pickups" type="Node2D" parent="."]
[node name="SkillPickup" parent="Pickups" instance=ExtResource("5_skill")]
position = Vector2(100, 205)
skill_type = 1

[node name="Collectibles" type="Node2D" parent="."]
[node name="Gem1" parent="Collectibles" instance=ExtResource("6_gem")]
position = Vector2(380, 215)
"""

with open("scenes/obstacles/chunks/chunk_14_crawler_and_barrier.tscn", "w", encoding="utf-8") as f:
    f.write(c14)

# Chunk 15: Skill Gem Cache on Elevated Platform
c15 = f"""[gd_scene load_steps=7 format=3]

[ext_resource type="Script" path="res://scripts/world/ground_chunk.gd" id="1_chunk"]
[ext_resource type="Texture2D" path="res://assets/sprites/ground_tile.png" id="2_tile"]
[ext_resource type="PackedScene" path="res://scenes/objects/platform_one_way.tscn" id="3_plat"]
[ext_resource type="PackedScene" path="res://scenes/objects/collectible_gem.tscn" id="4_gem"]
[ext_resource type="PackedScene" path="res://scenes/objects/skill_pickup.tscn" id="5_skill"]
[ext_resource type="PackedScene" path="res://scenes/obstacles/obstacle_ground_low.tscn" id="6_low"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_ground"]
size = Vector2(480, 40)

[node name="ChunkSkillGemCache" type="Node2D"]
script = ExtResource("1_chunk")
pattern_name = "skill_gem_cache"
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

[node name="Platforms" type="Node2D" parent="."]
[node name="Platform" parent="Platforms" instance=ExtResource("3_plat")]
position = Vector2(220, 188)

[node name="Hazards" type="Node2D" parent="."]
[node name="Cactus" parent="Hazards" instance=ExtResource("6_low")]
position = Vector2(220, 230)

[node name="Collectibles" type="Node2D" parent="."]
[node name="Gem1" parent="Collectibles" instance=ExtResource("4_gem")]
position = Vector2(200, 168)

[node name="Gem2" parent="Collectibles" instance=ExtResource("4_gem")]
position = Vector2(240, 168)

[node name="SkillPickup" parent="Collectibles" instance=ExtResource("5_skill")]
position = Vector2(220, 148)
skill_type = 7
"""

with open("scenes/obstacles/chunks/chunk_15_skill_gem_cache.tscn", "w", encoding="utf-8") as f:
    f.write(c15)

print("Generated chunks 13, 14, 15 successfully.")
