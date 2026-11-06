class_name ValidatorV2
extends SceneTree

## Spec C: Validator V2 (Simulated Reference Controller) for Riftosaur.
## Headless simulation that navigates every chunk pattern with a deterministic
## reference controller at maximum speed with realistic reaction delay (0.25s).

const LevelPattern = preload("res://scripts/world/level_pattern.gd")

var player_scene: PackedScene
var stage: Node2D
var player: Player

var results: Dictionary = {
	"total_patterns": 0,
	"passed": 0,
	"failed": 0,
	"by_band": {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
	"by_world": {"plains": 0, "jungle": 0, "frozen": 0, "volcanic": 0},
	"failures": [],
	"patterns": []
}

func _init() -> void:
	call_deferred("_start_validation")

func _start_validation() -> void:
	print("==================================================")
	print("[ValidatorV2] Starting Simulated Reference Validation")
	print("==================================================")

	player_scene = load("res://scenes/player/player.tscn")
	if player_scene == null:
		push_error("Could not load player scene")
		quit(1)
		return

	stage = Node2D.new()
	root.add_child(stage)

	player = player_scene.instantiate() as Player
	stage.add_child(player)

	# Allow scene tree and physics space to initialize
	await process_frame
	await physics_frame

	var pattern_dir = DirAccess.open("res://resources/patterns")
	if pattern_dir == null:
		push_error("Could not open res://resources/patterns")
		quit(1)
		return

	pattern_dir.list_dir_begin()
	var file_name = pattern_dir.get_next()
	var pattern_paths: Array[String] = []

	while file_name != "":
		if not pattern_dir.current_is_dir() and file_name.ends_with(".tres"):
			pattern_paths.append("res://resources/patterns/" + file_name)
		file_name = pattern_dir.get_next()
	pattern_dir.list_dir_end()

	pattern_paths.sort()

	for path in pattern_paths:
		var pat = load(path) as LevelPattern
		if pat != null:
			await _validate_pattern(pat)

	_output_report()

	if results["failed"] > 0:
		print("\n==================================================")
		print("[ValidatorV2] RESULT: FAILED (%d failures)" % results["failed"])
		quit(1)
	else:
		print("\n==================================================")
		print("[ValidatorV2] RESULT: PASSED (All %d patterns verified fair)" % results["passed"])
		quit(0)

func _validate_pattern(pat: LevelPattern) -> void:
	results["total_patterns"] += 1
	var band = pat.difficulty_band
	results["by_band"][band] = results["by_band"].get(band, 0) + 1
	for w in pat.world_ids:
		results["by_world"][w] = results["by_world"].get(w, 0) + 1

	var chunk_scene = load(pat.chunk_scene_path) as PackedScene
	if chunk_scene == null:
		_record_failure(pat, "Failed to load chunk scene: " + pat.chunk_scene_path)
		return

	var chunk = chunk_scene.instantiate() as Node2D
	stage.add_child(chunk)

	# Give one frame for colliders to register in physics space
	await physics_frame

	player.reset()
	player.position = Vector2(0.0, 216.0)
	var sim_speed = pat.speed_range.y
	player.current_speed = sim_speed
	player.is_steer_enabled = false
	player.state_machine.change_state(PlayerStateMachine.State.RUN)

	var died = {"state": false, "cause": ""}
	var on_died = func(cause):
		died["state"] = true
		died["cause"] = cause
	player.died.connect(on_died)

	# Collect obstacles and elements
	var hazards: Array[Node2D] = []
	var platforms: Array[Node2D] = []
	var springs: Array[Node2D] = []
	var flight_pickups: Array[Node2D] = []
	_gather_elements(chunk, hazards, platforms, springs, flight_pickups)

	var delta: float = 1.0 / 60.0
	var max_sim_time: float = (pat.chunk_width / sim_speed) * 2.5 + 2.0
	var current_time: float = 0.0
	var jump_hold_timer: float = 0.0
	var slide_timer: float = 0.0

	var passed = true

	while current_time < max_sim_time and player.position.x < pat.chunk_width:
		var reaction_dist = sim_speed * 0.25 # 0.25s realistic reaction delay
		var px = player.position.x
		var py = player.position.y

		# Find nearest upcoming obstacle ahead
		var next_hazard: Node2D = null
		var min_hz_dist = 9999.0
		for h in hazards:
			if is_instance_valid(h):
				var hx = h.global_position.x - stage.global_position.x
				var d = hx - px
				if d > -10.0 and d < min_hz_dist:
					min_hz_dist = d
					next_hazard = h

		# If flight pickup exists ahead, steer towards it
		for fp in flight_pickups:
			if is_instance_valid(fp):
				var fpx = fp.global_position.x - stage.global_position.x
				if absf(fpx - px) < 30.0 and player.is_on_floor():
					player._execute_jump()

		# Reference controller action decisions
		if next_hazard != null and min_hz_dist <= reaction_dist + 40.0:
			var hy = next_hazard.global_position.y - stage.global_position.y
			if hy < 215.0 and hy > 170.0:
				# Overhang obstacle: initiate slide
				if player.state_machine.current_state != PlayerStateMachine.State.SLIDE and slide_timer <= 0.0:
					player.slide_held = true
					player._enter_slide()
					slide_timer = 0.55
			elif hy >= 215.0:
				# Ground low hurdle: jump
				if player.is_on_floor() and jump_hold_timer <= 0.0:
					player._execute_jump()
					jump_hold_timer = 0.28

		# Jump hold decay
		if jump_hold_timer > 0.0:
			player.jump_held = true
			jump_hold_timer -= delta
		else:
			player.jump_held = false

		# Slide timer decay
		if slide_timer > 0.0:
			player.slide_held = true
			slide_timer -= delta
		else:
			player.slide_held = false

		# Flight controls when flying
		if player.is_flying:
			if py > 170.0:
				player.flight_up_input = true
				player.flight_down_input = false
			elif py < 100.0:
				player.flight_up_input = false
				player.flight_down_input = true
			else:
				player.flight_up_input = false
				player.flight_down_input = false

		player._physics_process(delta)

		if died["state"]:
			passed = false
			break

		current_time += delta

	player.died.disconnect(on_died)

	if not passed:
		_record_failure(pat, "Died at x=%.1f y=%.1f: %s" % [player.position.x, player.position.y, died["cause"]])
	elif player.position.x < pat.chunk_width:
		_record_failure(pat, "Timed out or stalled at x=%.1f" % player.position.x)
	else:
		results["passed"] += 1
		results["patterns"].append({
			"id": pat.pattern_id,
			"band": pat.difficulty_band,
			"width": pat.chunk_width,
			"status": "PASSED"
		})
		print("  [PASS] Pattern %-26s (Band %d, %.0fpx, v=%.0f px/s)" % [pat.pattern_id, pat.difficulty_band, pat.chunk_width, sim_speed])

	stage.remove_child(chunk)
	chunk.queue_free()

func _record_failure(pat: LevelPattern, reason: String) -> void:
	results["failed"] += 1
	var fail_info = {
		"id": pat.pattern_id,
		"band": pat.difficulty_band,
		"reason": reason
	}
	results["failures"].append(fail_info)
	results["patterns"].append({
		"id": pat.pattern_id,
		"band": pat.difficulty_band,
		"width": pat.chunk_width,
		"status": "FAILED",
		"reason": reason
	})
	print("  [FAIL] Pattern %-26s (Band %d): %s" % [pat.pattern_id, pat.difficulty_band, reason])

func _gather_elements(node: Node, hazards: Array[Node2D], platforms: Array[Node2D], springs: Array[Node2D], flight_pickups: Array[Node2D]) -> void:
	for child in node.get_children():
		if child is Hazard or (child is Area2D and (child.name.contains("Hazard") or child.name.contains("Spike") or child.name.contains("Cactus") or child.name.contains("Overhang") or child.name.contains("Pterodactyl") or child.name.contains("Crawler") or child.name.contains("StormCloud"))):
			hazards.append(child as Node2D)
		elif child is Platform or (child is StaticBody2D and child.name.contains("Platform")):
			platforms.append(child as Node2D)
		elif child is BouncePad or (child is Area2D and (child.name.contains("Bounce") or child.name.contains("Spring") or child.name.contains("Mushroom") or child.name.contains("Stump") or child.name.contains("Vent"))):
			springs.append(child as Node2D)
		elif child is FlightPickup or (child is Area2D and (child.name.contains("Wings") or child.name.contains("Rocket"))):
			flight_pickups.append(child as Node2D)
		_gather_elements(child, hazards, platforms, springs, flight_pickups)

func _output_report() -> void:
	var json_str = JSON.stringify(results, "  ")
	var file = FileAccess.open("res://tests/validator_v2_report.json", FileAccess.WRITE)
	if file != null:
		file.store_string(json_str)
		file.close()

	print("\nValidation Summary:")
	print("  Total Patterns : %d" % results["total_patterns"])
	print("  Passed         : %d" % results["passed"])
	print("  Failed         : %d" % results["failed"])
	print("  By Band        : %s" % str(results["by_band"]))
	print("  Report saved to: res://tests/validator_v2_report.json")
