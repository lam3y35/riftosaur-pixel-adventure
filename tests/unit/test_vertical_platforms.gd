class_name TestVerticalPlatforms
extends RefCounted

const PlayerScene = preload("res://scenes/player/player.tscn")
const PlatformSolidScene = preload("res://scenes/objects/platform_solid.tscn")
const PlatformOneWayScene = preload("res://scenes/objects/platform_one_way.tscn")
const BounceMushroomScene = preload("res://scenes/objects/bounce_mushroom.tscn")
const GameCameraScene = preload("res://scripts/world/game_camera.gd")

func get_test_name() -> String:
	return "VerticalPlatformsAndSpringsTest"

func _create_test_world() -> Dictionary:
	var tree = Engine.get_main_loop() as SceneTree
	var root = Node2D.new()
	tree.root.add_child(root)

	# Ground at y=230
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

func test_landing_on_elevated_solid_platform() -> Variant:
	var w = _create_test_world()
	var root = w["root"] as Node2D
	var player = w["player"] as Player
	var space = w["space"]

	var plat = PlatformSolidScene.instantiate() as Platform
	plat.position = Vector2(200, 180)
	root.add_child(plat)
	PhysicsServer2D.body_set_space(plat.get_rid(), space)

	# Drop player directly above platform with zero horizontal velocity
	player.position = Vector2(200, 150)
	player.current_speed = 0.0
	player.velocity = Vector2(0, 100.0)

	for _i in range(30):
		player._physics_process(1.0 / 60.0)

	var final_y = player.position.y
	var landed_on_plat = player.is_on_floor() and absf(final_y - 160.0) < 5.0
	_destroy_test_world(w)

	if not landed_on_plat:
		return "Player did not land reliably on solid elevated platform (final y=%.1f)" % final_y

	return true

func test_one_way_platform_pass_from_below_and_land_from_above() -> Variant:
	var w = _create_test_world()
	var root = w["root"] as Node2D
	var player = w["player"] as Player
	var space = w["space"]

	var plat = PlatformOneWayScene.instantiate() as Platform
	plat.position = Vector2(200, 170)
	root.add_child(plat)
	PhysicsServer2D.body_set_space(plat.get_rid(), space)

	# 1. Fall onto platform from above
	player.position = Vector2(200, 140)
	player.current_speed = 0.0
	player.velocity = Vector2(0, 120.0)

	for _i in range(30):
		player._physics_process(1.0 / 60.0)

	var landed_on_oneway = player.is_on_floor() and player.position.y < 170.0
	if not landed_on_oneway:
		var err_y = player.position.y
		_destroy_test_world(w)
		return "Player did not land on one-way platform from above (y=%.1f)" % err_y

	# 2. Ascend from below: jump up through one-way platform
	player.position = Vector2(200, 210)
	player.current_speed = 0.0
	player.velocity = Vector2(0, -350.0)

	for _i in range(15):
		player._physics_process(1.0 / 60.0)

	var final_pass_y = player.position.y
	var passed_through = final_pass_y < 170.0
	_destroy_test_world(w)

	if not passed_through:
		return "Player was blocked when jumping through one-way platform from below (y=%.1f)" % final_pass_y

	return true

func test_one_way_platform_drop_through_on_down_input() -> Variant:
	var w = _create_test_world()
	var root = w["root"] as Node2D
	var player = w["player"] as Player
	var space = w["space"]

	var plat = PlatformOneWayScene.instantiate() as Platform
	plat.position = Vector2(200, 170)
	root.add_child(plat)
	PhysicsServer2D.body_set_space(plat.get_rid(), space)

	# Stand on one-way platform
	player.position = Vector2(200, 156)
	player.velocity = Vector2.ZERO

	for _i in range(10):
		player._physics_process(1.0 / 60.0)

	# Trigger drop through
	player.drop_through_one_way_platform()

	for _i in range(30):
		player._physics_process(1.0 / 60.0)

	var dropped_below = player.position.y > 175.0
	_destroy_test_world(w)

	if not dropped_below:
		return "Player failed to drop through one-way platform after down/slide input"

	return true

func test_spring_bounce_pad_launch_and_states() -> Variant:
	var w = _create_test_world()
	var root = w["root"] as Node2D
	var player = w["player"] as Player

	var shroom = BounceMushroomScene.instantiate() as BouncePad
	shroom.position = Vector2(200, 230)
	root.add_child(shroom)

	if shroom.current_state != BouncePad.State.IDLE:
		_destroy_test_world(w)
		return "Bounce pad should initialize in IDLE state"

	# Player touches bounce pad
	player.position = Vector2(200, 220)
	shroom._on_body_entered(player)

	var launched_state = shroom.current_state == BouncePad.State.COMPRESSED
	var upward_velocity = player.velocity.y < -400.0

	# Process timers to verify state progression
	shroom._process(0.08)
	var is_launching = shroom.current_state == BouncePad.State.LAUNCHING

	shroom._process(0.15)
	var is_cooldown = shroom.current_state == BouncePad.State.COOLDOWN

	shroom._process(0.30)
	var returned_to_idle = shroom.current_state == BouncePad.State.IDLE

	_destroy_test_world(w)

	if not launched_state:
		return "Bounce pad failed to enter COMPRESSED state on player contact"
	if not upward_velocity:
		return "Bounce pad failed to impart strong upward launch velocity to player"
	if not is_launching:
		return "Bounce pad failed to transition to LAUNCHING state"
	if not is_cooldown:
		return "Bounce pad failed to transition to COOLDOWN state"
	if not returned_to_idle:
		return "Bounce pad failed to return to IDLE state after cooldown"

	return true

func test_camera_vertical_tracking_and_deadzone() -> Variant:
	var w = _create_test_world()
	var root = w["root"] as Node2D
	var player = w["player"] as Player

	var camera = GameCameraScene.new() as GameCamera
	camera.target = player
	root.add_child(camera)
	camera._ready()

	# 1. On ground (y=218): camera should stay locked at baseline_y (135.0)
	player.position = Vector2(100, 218)
	for _i in range(10):
		camera._physics_process(1.0 / 60.0)

	if absf(camera.global_position.y - 135.0) > 1.0:
		_destroy_test_world(w)
		return "Camera vertical position (%.1f) did not stay locked at baseline_y (135.0) for ground player" % camera.global_position.y

	# 2. Player ascends to high platform at y=90: camera should ease upward
	player.position = Vector2(100, 90)
	for _i in range(30):
		camera._physics_process(1.0 / 60.0)

	var camera_tracked_up = camera.global_position.y < 120.0
	var final_cam_y = camera.global_position.y

	# 3. Player returns to ground: camera should ease back down toward baseline_y
	player.position = Vector2(100, 218)
	for _i in range(60):
		camera._physics_process(1.0 / 60.0)

	var camera_returned_down = camera.global_position.y > final_cam_y and camera.global_position.y <= 135.0

	_destroy_test_world(w)

	if not camera_tracked_up:
		return "Camera failed to track upward for high platform player (y=%.1f)" % final_cam_y
	if not camera_returned_down:
		return "Camera failed to smoothly return toward baseline after player returned to ground"

	return true
