class_name TestMovement
extends RefCounted

const PlayerScene = preload("res://scenes/player/player.tscn")
const StateMachine = preload("res://scripts/player/player_state_machine.gd")

func get_test_name() -> String:
	return "MovementTestSuite"

func _create_test_world() -> Dictionary:
	var tree = Engine.get_main_loop() as SceneTree
	var root = Node2D.new()
	tree.root.add_child(root)

	# Static ground at y=200
	var ground = StaticBody2D.new()
	ground.collision_layer = 2
	ground.collision_mask = 1
	var col = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(2000, 40)
	col.shape = rect
	col.position = Vector2(500, 220)
	ground.add_child(col)
	root.add_child(ground)

	# Player instance from packed scene
	var player = PlayerScene.instantiate() as Player
	root.add_child(player)
	player.position = Vector2(100, 180)

	# Ensure physics space is active
	var space = root.get_world_2d().space
	PhysicsServer2D.body_set_space(ground.get_rid(), space)
	PhysicsServer2D.body_set_space(player.get_rid(), space)

	return {"tree": tree, "root": root, "ground": ground, "player": player}

func _destroy_test_world(w: Dictionary) -> void:
	if w.has("root") and is_instance_valid(w["root"]):
		var root = w["root"]
		if root.get_parent():
			root.get_parent().remove_child(root)
		root.free()

func _step_simulation(player: CharacterBody2D, ticks: int, dt: float = 1.0 / 60.0) -> void:
	for _i in range(ticks):
		player._physics_process(dt)

func test_ground_detection_and_running() -> Variant:
	var w = _create_test_world()
	var player = w["player"]

	# Simulate gravity falling to ground
	_step_simulation(player, 30)

	if not player.is_on_floor():
		_destroy_test_world(w)
		return "Player failed to detect ground after 30 physics ticks"

	var st = player.state_machine.current_state
	if st != StateMachine.State.RUN and st != StateMachine.State.LAND:
		_destroy_test_world(w)
		return "Expected RUN or LAND on ground, got: %s" % player.state_machine.get_state_name()

	_destroy_test_world(w)
	return true

func test_short_hop_vs_held_jump() -> Variant:
	var w = _create_test_world()
	var player = w["player"]
	_step_simulation(player, 25) # settle on floor

	var start_y = player.position.y

	# --- 1. Tap Jump (no hold) ---
	player._execute_jump()
	player.jump_held = false
	var peak_tap_y = player.position.y
	for _i in range(60):
		player._physics_process(1.0 / 60.0)
		if player.position.y < peak_tap_y:
			peak_tap_y = player.position.y

	var tap_height = start_y - peak_tap_y

	# Reset player
	player.position = Vector2(100, 180)
	player.velocity = Vector2.ZERO
	_step_simulation(player, 25)
	start_y = player.position.y

	# --- 2. Held Jump (hold for 0.35s) ---
	player._execute_jump()
	var peak_hold_y = player.position.y
	for i in range(80):
		var time = i * (1.0 / 60.0)
		player.jump_held = (time < player.config.max_jump_hold_time)
		player._physics_process(1.0 / 60.0)
		if player.position.y < peak_hold_y:
			peak_hold_y = player.position.y

	var hold_height = start_y - peak_hold_y
	_destroy_test_world(w)

	# Validate: tap ~ 30px, hold ~ 84px
	if tap_height < 24.0 or tap_height > 40.0:
		return "Tap jump height out of expected range (24-40px): %.2f px" % tap_height

	if hold_height < 70.0 or hold_height > 95.0:
		return "Held jump height out of expected range (70-95px): %.2f px" % hold_height

	if hold_height <= tap_height * 1.8:
		return "Held jump (%.2f px) should be significantly higher than tap (%.2f px)" % [hold_height, tap_height]

	return true

func test_jump_hold_cap_and_gravity() -> Variant:
	var w = _create_test_world()
	var player = w["player"]
	_step_simulation(player, 25)

	var start_y = player.position.y
	player._execute_jump()

	# Hold forever (1.5 seconds)
	var peak_y = player.position.y
	for _i in range(90):
		player.jump_held = true
		player._physics_process(1.0 / 60.0)
		if player.position.y < peak_y:
			peak_y = player.position.y

	var max_height_reached = start_y - peak_y
	var final_y = player.position.y
	_destroy_test_world(w)

	if max_height_reached > 95.0:
		return "Jump exceeded maximum hold cap! Reached: %.2f px" % max_height_reached

	if final_y < start_y - 20.0:
		return "Player failed to fall back down despite gravity"

	return true

func test_jump_buffer_timing() -> Variant:
	var w = _create_test_world()
	var player = w["player"]
	_step_simulation(player, 25)

	# Jump into air
	player._execute_jump()
	player.jump_held = false
	# Step 22 ticks until just before landing (tap jump lands at ~tick 26)
	_step_simulation(player, 22)

	# Inject buffer jump within window (0.12s before landing)
	player.jump_buffer_timer = player.config.jump_buffer_time

	var jumped_again = [false]
	player.jumped.connect(func(): jumped_again[0] = true)
	# Step 10 ticks to trigger landing and execute buffered jump
	_step_simulation(player, 10)

	_destroy_test_world(w)

	if not jumped_again[0]:
		return "Buffered jump was not executed upon landing"

	return true

func test_coyote_time_allows_grace_and_prevents_double_jump() -> Variant:
	var w = _create_test_world()
	var player = w["player"]
	_step_simulation(player, 25)

	# 1. Walk off ledge into air: coyote timer active
	player.position.y = 150
	player.state_machine.change_state(StateMachine.State.JUMP_FALL)
	player.coyote_timer = player.config.coyote_time
	player.jump_buffer_timer = 0.05

	var jumped = [false]
	player.jumped.connect(func(): jumped[0] = true)
	_step_simulation(player, 1)

	if not jumped[0]:
		_destroy_test_world(w)
		return "Coyote jump failed within active window"

	# 2. Outside coyote window: coyote_timer = 0
	player.coyote_timer = 0.0
	player.jump_buffer_timer = 0.05
	jumped[0] = false
	_step_simulation(player, 1)

	_destroy_test_world(w)

	if jumped[0]:
		return "Mid-air jump succeeded outside coyote window (unintended double-jump)"

	return true

func test_slide_and_collision_shape_shrink_and_recovery() -> Variant:
	var w = _create_test_world()
	var player = w["player"]
	_step_simulation(player, 25)

	var standing_h = player.box_shape.size.y
	if standing_h != player.config.standing_extents.y * 2.0:
		_destroy_test_world(w)
		return "Initial standing shape height mismatch: %.1f" % standing_h

	# Enter slide
	player._enter_slide()
	if player.state_machine.current_state != StateMachine.State.SLIDE:
		_destroy_test_world(w)
		return "Failed to enter SLIDE state"

	var sliding_h = player.box_shape.size.y
	if sliding_h != player.config.sliding_extents.y * 2.0:
		_destroy_test_world(w)
		return "Sliding shape height mismatch: %.1f" % sliding_h

	# Recover from slide
	player._exit_slide()
	if player.state_machine.current_state != StateMachine.State.RUN:
		_destroy_test_world(w)
		return "Failed to recover to RUN from SLIDE"

	if player.box_shape.size.y != standing_h:
		_destroy_test_world(w)
		return "Shape did not restore standing height after exit"

	_destroy_test_world(w)
	return true

func test_dive_mechanic() -> Variant:
	var w = _create_test_world()
	var player = w["player"]
	_step_simulation(player, 25)

	player._execute_jump()
	_step_simulation(player, 10)

	player.state_machine.change_state(StateMachine.State.DIVE)
	_step_simulation(player, 1)

	var dive_vy = player.velocity.y
	_destroy_test_world(w)

	if dive_vy < 500.0:
		return "Dive velocity (%.1f) did not match expected velocity" % dive_vy

	return true

func test_interrupted_state_hazard_hit() -> Variant:
	var w = _create_test_world()
	var player = w["player"]
	_step_simulation(player, 25)

	player._execute_jump()
	_step_simulation(player, 5)

	var died = [false]
	player.died.connect(func(_cause: String): died[0] = true)
	player.hit_hazard()

	var is_dead = player.state_machine.current_state == StateMachine.State.DEAD

	# Ensure dead state cannot be interrupted by jump
	player._execute_jump()
	var still_dead = player.state_machine.current_state == StateMachine.State.DEAD

	_destroy_test_world(w)

	if not is_dead:
		return "State is not DEAD after hit_hazard"
	if not died[0]:
		return "Player did not emit died signal on hazard hit"
	if not still_dead:
		return "Dead state was unlawfully interrupted by jump"

	return true
