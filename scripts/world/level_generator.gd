class_name LevelGenerator
extends RefCounted

const LevelPattern = preload("res://scripts/world/level_pattern.gd")

## Procedural Level Generator for Riftosaur.
## Handles deterministic seeding, pattern matching, connector continuity,
## difficulty bands, and fairness constraints.

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var current_seed: int = 0

var patterns: Array[LevelPattern] = []
var patterns_by_band: Dictionary = {1: [], 2: [], 3: [], 4: [], 5: []}

var last_pattern: LevelPattern = null
var last_exit_height: float = 230.0
var last_exit_surface: String = "solid"
var consecutive_challenging_count: int = 0

func _init(initial_seed: int = 0) -> void:
	if initial_seed == 0:
		rng.randomize()
		current_seed = int(rng.randi() % 1000000)
	else:
		current_seed = initial_seed
	rng.seed = current_seed
	_load_patterns()

func set_seed(new_seed: int) -> void:
	current_seed = new_seed
	rng.seed = current_seed
	reset_state()

func reset_state() -> void:
	last_pattern = null
	last_exit_height = 230.0
	last_exit_surface = "solid"
	consecutive_challenging_count = 0

func _load_patterns() -> void:
	patterns.clear()
	for b in [1, 2, 3, 4, 5]:
		patterns_by_band[b] = []

	var dir = DirAccess.open("res://resources/patterns")
	if dir == null:
		push_error("[LevelGenerator] Failed to open res://resources/patterns")
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	var pattern_files: Array[String] = []

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			pattern_files.append("res://resources/patterns/" + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	pattern_files.sort()

	for path in pattern_files:
		var pat = load(path) as LevelPattern
		if pat != null:
			patterns.append(pat)
			var band = clampi(pat.difficulty_band, 1, 5)
			patterns_by_band[band].append(pat)

func get_difficulty_band(distance_m: float, _speed: float = 280.0) -> int:
	if distance_m < 150.0:
		return 1 # Teaching band
	elif distance_m < 350.0:
		return 2
	elif distance_m < 600.0:
		return 3
	elif distance_m < 900.0:
		return 4
	else:
		return 5

func get_world_transition_pattern() -> LevelPattern:
	for pat in patterns:
		if pat.pattern_id == "p00_world_transition":
			last_pattern = pat
			last_exit_height = pat.exit_height
			last_exit_surface = pat.exit_surface
			consecutive_challenging_count = 0
			return pat
	return null

func select_next_pattern(distance_m: float, current_speed: float, world_id: String) -> LevelPattern:
	var target_band = get_difficulty_band(distance_m, current_speed)
	var candidates: Array[LevelPattern] = []

	# Hard rule: If we had a challenging pattern, force breathing room (safe route)
	var allow_challenging = (consecutive_challenging_count == 0)

	for pat in patterns:
		# Exclude special transition chunk from ordinary procedural selection
		if pat.pattern_id == "p00_world_transition":
			continue

		# Check world compatibility
		if not pat.world_ids.is_empty() and not pat.world_ids.has(world_id):
			continue

		# Check difficulty band: current band or one band lower for pacing
		if pat.difficulty_band > target_band:
			continue
		if target_band > 1 and pat.difficulty_band < target_band - 1:
			continue

		# Check speed range
		if current_speed < pat.speed_range.x or current_speed > pat.speed_range.y:
			continue

		# Connector continuity check
		if absf(pat.entry_height - last_exit_height) > 1.0 or pat.entry_surface != last_exit_surface:
			continue

		# Avoid consecutive high challenge
		if not allow_challenging and pat.route_class == "challenging":
			continue

		candidates.append(pat)

	# Fallback if no matching pattern
	if candidates.is_empty():
		for pat in patterns:
			if pat.pattern_id == "p01_safe_breather":
				candidates.append(pat)
				break

	var chosen: LevelPattern
	if candidates.is_empty():
		chosen = patterns[0]
	else:
		var idx = int(rng.randi() % candidates.size())
		chosen = candidates[idx]

	if chosen.route_class == "challenging":
		consecutive_challenging_count += 1
	else:
		consecutive_challenging_count = 0

	last_pattern = chosen
	last_exit_height = chosen.exit_height
	last_exit_surface = chosen.exit_surface

	return chosen
