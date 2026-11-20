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
var recent_pattern_ids: Array[String] = []
var _shuffled_bag_ids: Array[String] = []

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
	recent_pattern_ids.clear()
	_shuffled_bag_ids.clear()

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
		if not dir.current_is_dir():
			var clean_name = file_name.trim_suffix(".remap")
			if clean_name.ends_with(".tres"):
				var full_path = "res://resources/patterns/" + clean_name
				if not pattern_files.has(full_path):
					pattern_files.append(full_path)
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

func select_next_pattern(distance_m: float, current_speed: float, world_id: String, allowed_movements: Array = [], avoid_overhang: bool = false, allow_flight_routes: bool = true, mode_hint: int = 1) -> LevelPattern:
	var target_band = get_difficulty_band(distance_m, current_speed)
	var candidates: Array[LevelPattern] = []

	# Hard rule: If we had a challenging pattern, force breathing room (safe route)
	var allow_challenging = (consecutive_challenging_count == 0)

	for pat in patterns:
		# Exclude special transition chunk from ordinary procedural selection
		if pat.pattern_id == "p00_world_transition":
			continue

		if not allow_flight_routes and pat.required_movement.has("flight"):
			continue

		# Check world compatibility
		if not pat.world_ids.is_empty() and not pat.world_ids.has(world_id):
			continue

		# Check movement compatibility (e.g., Spicy Jump disallows slide; Flight avoids overhang traps)
		if avoid_overhang and pat.required_movement.has("slide"):
			continue
		if not allowed_movements.is_empty():
			var movement_ok := true
			for req in pat.required_movement:
				if req != "none" and req != "run_and_jump" and not allowed_movements.has(req):
					movement_ok = false
					break
			if not movement_ok:
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

		# Keep empty safe breather strictly as recovery/fallback, never spamming empty chunks
		if pat.pattern_id == "p01_safe_breather" and allow_challenging:
			continue

		candidates.append(pat)

	# Second-chance relaxation: if strict high-band speed gates excluded every chunk (e.g., Chill/Practice speed caps),
	# allow any unlocked lower-band obstacle pattern matching speed, world, movement, and connector continuity.
	if candidates.is_empty():
		for pat in patterns:
			if pat.pattern_id == "p00_world_transition" or pat.pattern_id == "p01_safe_breather":
				continue
			if not allow_flight_routes and pat.required_movement.has("flight"):
				continue
			if not pat.world_ids.is_empty() and not pat.world_ids.has(world_id):
				continue
			if avoid_overhang and pat.required_movement.has("slide"):
				continue
			if not allowed_movements.is_empty():
				var mv_ok := true
				for req in pat.required_movement:
					if req != "none" and req != "run_and_jump" and not allowed_movements.has(req):
						mv_ok = false
						break
				if not mv_ok:
					continue
			if pat.difficulty_band > target_band:
				continue
			if current_speed < pat.speed_range.x or current_speed > pat.speed_range.y:
				continue
			if absf(pat.entry_height - last_exit_height) > 1.0 or pat.entry_surface != last_exit_surface:
				continue
			if not allow_challenging and pat.route_class == "challenging":
				continue
			candidates.append(pat)

	# Avoid immediate back-to-back repeats when other valid choices exist
	if candidates.size() > 1:
		var non_recent: Array[LevelPattern] = []
		for pat in candidates:
			if not recent_pattern_ids.has(pat.pattern_id):
				non_recent.append(pat)
		if not non_recent.is_empty():
			candidates = non_recent

	# Mode-aware pacing bias (without ever making layout deterministic-boring or exhausting all patterns)
	if candidates.size() > 2:
		if mode_hint == 0:
			var gentle: Array[LevelPattern] = []
			for pat in candidates:
				if pat.route_class != "challenging":
					gentle.append(pat)
			if not gentle.is_empty() and (rng.randi() % 100) < 68:
				candidates = gentle
		elif mode_hint == 2 and allow_challenging:
			var intense: Array[LevelPattern] = []
			for pat in candidates:
				if pat.route_class == "challenging" or pat.route_class == "optional_reward":
					intense.append(pat)
			if not intense.is_empty() and (rng.randi() % 100) < 75:
				candidates = intense

	# Fallback if no matching pattern
	if candidates.is_empty():
		for pat in patterns:
			if pat.pattern_id == "p01_safe_breather":
				candidates.append(pat)
				break

	var chosen: LevelPattern
	if candidates.is_empty():
		if patterns.is_empty():
			return null
		chosen = patterns[0]
	else:
		# Prioritize biome-exclusive signature chunks when available (keeps each biome distinct)
		var biome_specific: Array[LevelPattern] = []
		for pat in candidates:
			if pat.world_ids.size() > 0 and pat.world_ids.size() <= 2:
				biome_specific.append(pat)
		if not biome_specific.is_empty() and (rng.randi() % 100) < 55:
			candidates = biome_specific

		# Shuffle-bag draw across candidates so layouts stay fresh instead of repetitive
		var bag_candidates: Array[LevelPattern] = []
		for pat in candidates:
			if not _shuffled_bag_ids.has(pat.pattern_id):
				bag_candidates.append(pat)
		if bag_candidates.is_empty():
			for pat in candidates:
				_shuffled_bag_ids.erase(pat.pattern_id)
			bag_candidates = candidates

		var idx = int(rng.randi() % bag_candidates.size())
		chosen = bag_candidates[idx]
		_shuffled_bag_ids.append(chosen.pattern_id)
		if _shuffled_bag_ids.size() > 16:
			_shuffled_bag_ids.remove_at(0)

	recent_pattern_ids.append(chosen.pattern_id)
	if recent_pattern_ids.size() > 2:
		recent_pattern_ids.remove_at(0)

	if chosen.route_class == "challenging":
		consecutive_challenging_count += 1
	else:
		consecutive_challenging_count = 0

	last_pattern = chosen
	last_exit_height = chosen.exit_height
	last_exit_surface = chosen.exit_surface

	return chosen
