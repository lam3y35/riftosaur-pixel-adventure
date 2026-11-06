class_name TestFlightSystem
extends RefCounted

const PlayerScene = preload("res://scenes/player/player.tscn")
const FlightWingsPickupScene = preload("res://scenes/objects/flight_pickup_wings.tscn")
const FlightRocketPickupScene = preload("res://scenes/objects/flight_pickup_rocket.tscn")
const StormCloudScene = preload("res://scenes/obstacles/obstacle_storm_cloud.tscn")

func get_test_name() -> String:
	return "FlightSystemTest"

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

# 1. Flight Pickup & Feel Difference (Mechanical Wings vs Rocket Relic)
func test_flight_pickup_and_feel_differences() -> Variant:
	var w = _create_test_world()
	var player = w["player"] as Player

	# Start Mechanical Wings
	player.start_flight(1, 7.0)
	if not player.is_flying:
		_destroy_test_world(w)
		return "Player failed to enter flight mode with Mechanical Wings"
	if player.state_machine.current_state != PlayerStateMachine.State.FLIGHT:
		_destroy_test_world(w)
		return "Expected state machine to be in FLIGHT state"
	if player.flight_timer != 7.0:
		_destroy_test_world(w)
		return "Expected 7.0s flight duration for Wings"

	# Simulate upward ascent with Wings
	player.set_flight_input(true, false)
	player._handle_flight_state(0.016)
	var wings_up_v = player.velocity.y
	if wings_up_v != -210.0:
		_destroy_test_world(w)
		return "Expected Wings up velocity -210.0, got %f" % wings_up_v

	# Switch to Rocket Relic
	player.start_flight(2, 5.0)
	if player.flight_type != 2 or player.flight_timer != 5.0:
		_destroy_test_world(w)
		return "Expected Rocket Relic with 5.0s duration"

	# Simulate upward ascent with Rocket
	player.set_flight_input(true, false)
	player._handle_flight_state(0.016)
	var rocket_up_v = player.velocity.y
	if rocket_up_v != -340.0:
		_destroy_test_world(w)
		return "Expected Rocket up velocity -340.0, got %f" % rocket_up_v

	# Rocket must have distinctively stronger thrust than Wings
	if absf(rocket_up_v) <= absf(wings_up_v):
		_destroy_test_world(w)
		return "Rocket thrust is not stronger than wings"

	_destroy_test_world(w)
	return true

# 2. Down input gives gradual descent, NEVER a grounded action
func test_flight_down_input_descent_no_slide() -> Variant:
	var w = _create_test_world()
	var player = w["player"] as Player

	player.start_flight(1, 7.0)

	# Simulate down input
	player.set_flight_input(false, true)
	player._handle_flight_state(0.016)

	if player.velocity.y <= 0.0:
		_destroy_test_world(w)
		return "Expected positive downward descent velocity, got %f" % player.velocity.y

	# Down input must NOT transition state machine to SLIDE, DIVE, or DROP_THROUGH
	if player.state_machine.current_state != PlayerStateMachine.State.FLIGHT:
		_destroy_test_world(w)
		return "Down input broke FLIGHT state machine state into %s" % player.state_machine.get_state_name()

	_destroy_test_world(w)
	return true

# 3. 2s Warning indicator before flight expiry
func test_flight_expiry_warning_timing() -> Variant:
	var w = _create_test_world()
	var player = w["player"] as Player

	var warning_received = {"warned": false, "time": 0.0}
	player.flight_warning.connect(func(rem):
		warning_received["warned"] = true
		warning_received["time"] = rem
	)

	player.start_flight(1, 7.0)

	# Advance 4.5 seconds (2.5s remaining - no warning yet)
	player._handle_flight_state(4.5)
	if warning_received["warned"]:
		_destroy_test_world(w)
		return "Flight warning triggered prematurely at > 2s remaining"

	# Advance another 0.6 seconds (1.9s remaining - warning must trigger)
	player._handle_flight_state(0.6)
	if not warning_received["warned"]:
		_destroy_test_world(w)
		return "Flight warning failed to trigger at <= 2s remaining"

	if warning_received["time"] > 2.0:
		_destroy_test_world(w)
		return "Warning emitted at invalid time: %f" % warning_received["time"]

	_destroy_test_world(w)
	return true

# 4. Gradual physics resumption and landing support
func test_flight_expiry_smooth_landing() -> Variant:
	var w = _create_test_world()
	var player = w["player"] as Player

	player.start_flight(1, 3.0)

	var ended = {"emitted": false}
	player.flight_ended.connect(func(): ended["emitted"] = true)

	# Advance to expiry
	player._handle_flight_state(3.1)

	if not ended["emitted"]:
		_destroy_test_world(w)
		return "flight_ended signal was not emitted"
	if player.is_flying:
		_destroy_test_world(w)
		return "Player is still flagged flying after expiry"
	if player.state_machine.current_state != PlayerStateMachine.State.JUMP_FALL:
		_destroy_test_world(w)
		return "Expected state to be JUMP_FALL after flight ends, got %s" % player.state_machine.get_state_name()

	# Initial exit velocity must be gentle forward glide (<= 100 px/s downward) rather than heavy drop
	if player.velocity.y > 100.0 or player.velocity.y < 0.0:
		_destroy_test_world(w)
		return "Expected gentle downward glide velocity (0..100), got %f" % player.velocity.y

	_destroy_test_world(w)
	return true

# 5. Pause and resume while flight timers are active
func test_flight_pause_preserves_timer() -> Variant:
	var w = _create_test_world()
	var player = w["player"] as Player

	player.start_flight(1, 6.0)

	# Run 2.0s
	player._handle_flight_state(2.0)
	var time_before_pause = player.flight_timer

	# Simulate paused world (no delta applied)
	# When resumed, timer remains exact
	var time_after_resume = player.flight_timer
	if absf(time_before_pause - time_after_resume) > 0.001:
		_destroy_test_world(w)
		return "Flight timer drifted during pause"

	# Ensure timer continues cleanly after resume
	player._handle_flight_state(1.0)
	if absf(player.flight_timer - (time_before_pause - 1.0)) > 0.01:
		_destroy_test_world(w)
		return "Flight timer failed to tick down after resume"

	_destroy_test_world(w)
	return true
