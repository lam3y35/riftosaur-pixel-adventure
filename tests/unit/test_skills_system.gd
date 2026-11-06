class_name TestSkillsSystem
extends RefCounted

const PlayerScene = preload("res://scenes/player/player.tscn")
const CollectibleGemScene = preload("res://scenes/objects/collectible_gem.tscn")
const SkillPickupScene = preload("res://scenes/objects/skill_pickup.tscn")
const PterodactylScene = preload("res://scenes/obstacles/obstacle_pterodactyl.tscn")
const CrawlerScene = preload("res://scenes/obstacles/obstacle_crawler.tscn")
const BarrierScene = preload("res://scenes/obstacles/obstacle_wooden_barrier.tscn")
const CactusScene = preload("res://scenes/obstacles/obstacle_ground_low.tscn")

func get_test_name() -> String:
	return "SkillsAndCollectiblesSystemTest"

func _create_test_world() -> Dictionary:
	var tree = Engine.get_main_loop() as SceneTree
	var root = Node2D.new()
	tree.root.add_child(root)

	var ground = StaticBody2D.new()
	ground.collision_layer = 2
	ground.collision_mask = 1
	var col = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(2000, 40)
	col.shape = rect
	col.position = Vector2(500, 250)
	ground.add_child(col)
	root.add_child(ground)

	var player = PlayerScene.instantiate() as Player
	player.position = Vector2(100, 218)
	root.add_child(player)

	var space = root.get_world_2d().space
	PhysicsServer2D.body_set_space(ground.get_rid(), space)
	PhysicsServer2D.body_set_space(player.get_rid(), space)

	return {"tree": tree, "root": root, "ground": ground, "player": player, "space": space}

func _destroy_test_world(w: Dictionary) -> void:
	if w.has("root") and is_instance_valid(w["root"]):
		var root = w["root"]
		if root.get_parent():
			root.get_parent().remove_child(root)
		root.free()

# 1. Skill Collection & Replacement
func test_skill_pickup_and_replacement() -> Variant:
	var w = _create_test_world()
	var player = w["player"] as Player

	var sm = player.skill_manager
	if sm == null:
		_destroy_test_world(w)
		return "SkillManager was not initialized on Player"

	# Equip Bone Blade
	sm.equip_skill(SkillManager.SkillType.BONE_BLADE)
	if sm.current_skill != SkillManager.SkillType.BONE_BLADE:
		_destroy_test_world(w)
		return "Expected current_skill to be BONE_BLADE"

	var replace_state = {"triggered": false, "old": "", "new": ""}
	sm.skill_replaced.connect(func(o, n):
		replace_state["triggered"] = true
		replace_state["old"] = o
		replace_state["new"] = n
	)

	# Replace with Air Dash
	sm.equip_skill(SkillManager.SkillType.AIR_DASH)
	if sm.current_skill != SkillManager.SkillType.AIR_DASH:
		_destroy_test_world(w)
		return "Expected current_skill to be AIR_DASH"

	if not replace_state["triggered"]:
		_destroy_test_world(w)
		return "Expected skill_replaced signal to be emitted"

	if replace_state["old"] != "Bone Blade" or replace_state["new"] != "Air Dash":
		_destroy_test_world(w)
		return "Unexpected replaced names: old=%s, new=%s" % [replace_state["old"], replace_state["new"]]

	_destroy_test_world(w)
	return true

# 2. Bone Blade destroys BREAKABLE hazards
func test_bone_blade_destroys_breakable() -> Variant:
	var w = _create_test_world()
	var root = w["root"] as Node2D
	var player = w["player"] as Player

	var barrier = BarrierScene.instantiate() as Hazard
	barrier.position = player.position + Vector2(25, 0)
	root.add_child(barrier)

	player.skill_manager.equip_skill(SkillManager.SkillType.BONE_BLADE)
	var activated = player.use_skill()
	if not activated:
		_destroy_test_world(w)
		return "Failed to activate Bone Blade"

	if not barrier.is_destroyed:
		_destroy_test_world(w)
		return "Bone Blade failed to destroy breakable barrier"

	_destroy_test_world(w)
	return true

# 3. Bone Blade does NOT destroy SOLID hazards
func test_bone_blade_ignores_solid() -> Variant:
	var w = _create_test_world()
	var root = w["root"] as Node2D
	var player = w["player"] as Player

	var cactus = CactusScene.instantiate() as Hazard
	cactus.position = player.position + Vector2(25, 0)
	root.add_child(cactus)

	player.skill_manager.equip_skill(SkillManager.SkillType.BONE_BLADE)
	player.use_skill()

	if cactus.is_destroyed:
		_destroy_test_world(w)
		return "Bone Blade incorrectly destroyed solid cactus"

	_destroy_test_world(w)
	return true

# 4. Boomerang destroys AIRBORNE and CRAWLER
func test_boomerang_hits_airborne_and_crawler() -> Variant:
	var w = _create_test_world()
	var root = w["root"] as Node2D
	var player = w["player"] as Player

	var pter = PterodactylScene.instantiate() as Hazard
	pter.position = player.position + Vector2(30, 0)
	root.add_child(pter)

	var crawl = CrawlerScene.instantiate() as Hazard
	crawl.position = player.position + Vector2(60, 0)
	root.add_child(crawl)

	var solid = CactusScene.instantiate() as Hazard
	solid.position = player.position + Vector2(90, 0)
	root.add_child(solid)

	# Simulate projectile check directly
	var boom = BoomerangProjectile.new()
	boom._check_hit_hazard(pter)
	boom._check_hit_hazard(crawl)
	boom._check_hit_hazard(solid)

	if not pter.is_destroyed:
		_destroy_test_world(w)
		return "Boomerang did not destroy airborne hazard"
	if not crawl.is_destroyed:
		_destroy_test_world(w)
		return "Boomerang did not destroy crawler hazard"
	if solid.is_destroyed:
		_destroy_test_world(w)
		return "Boomerang incorrectly destroyed solid hazard"

	boom.free()
	_destroy_test_world(w)
	return true

# 5. Stone Shield absorbs AIRBORNE/CRAWLER/PROJECTILE and breaks, but player dies on SOLID
func test_stone_shield_absorbs_hit() -> Variant:
	var w = _create_test_world()
	var player = w["player"] as Player

	# Equip stone shield
	player.skill_manager.equip_skill(SkillManager.SkillType.STONE_SHIELD)
	if not player.skill_manager.has_shield:
		_destroy_test_world(w)
		return "Stone shield not flagged active"

	# Hit with airborne hazard
	var pter = PterodactylScene.instantiate() as Hazard
	player.hit_hazard("Hit by pterodactyl", false, pter)

	if player.state_machine.current_state == PlayerStateMachine.State.DEAD:
		_destroy_test_world(w)
		return "Stone shield failed to absorb airborne hit - player died"

	if player.skill_manager.has_shield:
		_destroy_test_world(w)
		return "Stone shield did not break after absorbing hit"

	pter.free()

	# Re-equip stone shield and test solid hazard
	player.skill_manager.equip_skill(SkillManager.SkillType.STONE_SHIELD)
	var cactus = CactusScene.instantiate() as Hazard
	player.hit_hazard("Hit by cactus", false, cactus)

	if player.state_machine.current_state != PlayerStateMachine.State.DEAD:
		_destroy_test_world(w)
		return "Stone shield incorrectly absorbed solid hazard - player should die"

	cactus.free()
	_destroy_test_world(w)
	return true

# 6. Ground Slam shockwave destroys Breakable and Crawler in radius
func test_ground_slam_shockwave() -> Variant:
	var w = _create_test_world()
	var root = w["root"] as Node2D
	var player = w["player"] as Player

	var barrier = BarrierScene.instantiate() as Hazard
	barrier.position = player.position + Vector2(50, 0)
	root.add_child(barrier)

	var crawler = CrawlerScene.instantiate() as Hazard
	crawler.position = player.position + Vector2(-40, 0)
	root.add_child(crawler)

	var solid = CactusScene.instantiate() as Hazard
	solid.position = player.position + Vector2(30, 0)
	root.add_child(solid)

	player._execute_ground_slam_shockwave()

	if not barrier.is_destroyed:
		_destroy_test_world(w)
		return "Ground slam did not destroy breakable barrier"
	if not crawler.is_destroyed:
		_destroy_test_world(w)
		return "Ground slam did not destroy crawler"
	if solid.is_destroyed:
		_destroy_test_world(w)
		return "Ground slam incorrectly destroyed solid cactus"

	_destroy_test_world(w)
	return true

# 7. Time Shard slows hazards by 50%
func test_time_shard_slows_hazards() -> Variant:
	var w = _create_test_world()
	var root = w["root"] as Node2D
	var player = w["player"] as Player

	var pter = PterodactylScene.instantiate() as Hazard
	root.add_child(pter)
	if pter.speed != 65.0:
		_destroy_test_world(w)
		return "Expected pterodactyl speed 65.0, got %f" % pter.speed

	player.skill_manager.equip_skill(SkillManager.SkillType.TIME_SHARD)
	player.use_skill()

	if pter.time_scale != 0.5:
		_destroy_test_world(w)
		return "Expected time_scale 0.5, got %f" % pter.time_scale

	# Expire duration
	player.skill_manager.update(4.1)

	if pter.time_scale != 1.0:
		_destroy_test_world(w)
		return "Expected time_scale to restore to 1.0 after expiry"

	_destroy_test_world(w)
	return true

# 8. Air Dash 2 charges and ground recharge
func test_air_dash_charges_and_recharge() -> Variant:
	var w = _create_test_world()
	var player = w["player"] as Player

	player.skill_manager.equip_skill(SkillManager.SkillType.AIR_DASH)
	if player.skill_manager.current_charges != 2:
		_destroy_test_world(w)
		return "Expected Air Dash to start with 2 charges, got %d" % player.skill_manager.current_charges

	# First dash
	var dash1 = player.use_skill()
	if not dash1:
		_destroy_test_world(w)
		return "Failed to use first air dash"
	if player.skill_manager.current_charges != 1:
		_destroy_test_world(w)
		return "Expected 1 charge remaining, got %d" % player.skill_manager.current_charges

	# Cooldown enforcement
	var dash_cd = player.use_skill()
	if dash_cd:
		_destroy_test_world(w)
		return "Air dash was usable while on cooldown"

	# Advance past cooldown
	player.skill_manager.update(0.65)
	var dash2 = player.use_skill()
	if not dash2:
		_destroy_test_world(w)
		return "Failed to use second air dash after cooldown"
	if player.skill_manager.current_charges != 0:
		_destroy_test_world(w)
		return "Expected 0 charges remaining, got %d" % player.skill_manager.current_charges

	# Land on ground to refill charges
	player.skill_manager.on_player_landed()
	if player.skill_manager.current_charges != 2:
		_destroy_test_world(w)
		return "Expected charges to refill to 2 on landing, got %d" % player.skill_manager.current_charges

	_destroy_test_world(w)
	return true

# 9. Bounce Power launch boost (+35%)
func test_bounce_power_multiplier() -> Variant:
	var w = _create_test_world()
	var player = w["player"] as Player

	player.skill_manager.equip_skill(SkillManager.SkillType.BOUNCE_POWER)
	player.use_skill()

	if absf(player.bounce_multiplier - 1.35) > 0.01:
		_destroy_test_world(w)
		return "Expected bounce_multiplier 1.35, got %f" % player.bounce_multiplier

	player.bounce_launch(-400.0)
	if absf(player.velocity.y - (-540.0)) > 1.0:
		_destroy_test_world(w)
		return "Expected boosted launch velocity -540.0, got %f" % player.velocity.y

	# Expire
	player.skill_manager.update(8.1)
	if absf(player.bounce_multiplier - 1.0) > 0.01:
		_destroy_test_world(w)
		return "Expected bounce_multiplier to revert to 1.0, got %f" % player.bounce_multiplier

	_destroy_test_world(w)
	return true

# 10. Collectible Gems and Magnet Relic
func test_collectible_gem_and_magnet() -> Variant:
	var w = _create_test_world()
	var root = w["root"] as Node2D
	var player = w["player"] as Player

	var gem = CollectibleGemScene.instantiate() as Collectible
	gem.position = player.position + Vector2(100, 0)
	root.add_child(gem)

	if player.gems_collected != 0:
		_destroy_test_world(w)
		return "Expected gems_collected to start at 0"

	# Activate Magnet
	player.skill_manager.equip_skill(SkillManager.SkillType.MAGNET_RELIC)
	player.use_skill()
	if not player.is_magnet_active:
		_destroy_test_world(w)
		return "Magnet relic failed to activate"

	# Simulate physics tick on gem
	var old_x = gem.global_position.x
	gem._physics_process(0.1)
	if gem.global_position.x >= old_x:
		_destroy_test_world(w)
		return "Gem did not move toward player under magnet pull"

	# Touch collection
	gem.collect(player)
	if player.gems_collected != 1:
		_destroy_test_world(w)
		return "Expected gems_collected to be 1 after pickup"

	_destroy_test_world(w)
	return true
