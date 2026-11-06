class_name ValidatorV1
extends SceneTree

# Spec E: Analytic Validator V1 for Riftosaur
# Checks fairness, reachability, rise limits, and reaction windows across all chunk patterns.

const MAX_JUMP_RISE: float = 62.0 # Maximum jump height with full hold
const MAX_RISE_ALLOWED: float = MAX_JUMP_RISE * 0.80 # 80% rule = 49.6 px
const MIN_REACTION_TIME: float = 0.65 # Minimum reaction window in seconds
const OPENING_SPEED: float = 200.0
const MAX_SPEED: float = 450.0

var errors: Array[String] = []
var warnings: Array[String] = []
var validated_chunks: int = 0

func _init() -> void:
	print("==================================================")
	print("[ValidatorV1] Starting Analytic Fairness Validation")
	print("==================================================")

	var dir = DirAccess.open("res://scenes/obstacles/chunks")
	if dir == null:
		push_error("Failed to open chunks directory")
		quit(1)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	var chunk_files: Array[String] = []

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tscn"):
			chunk_files.append("res://scenes/obstacles/chunks/" + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	chunk_files.sort()

	for chunk_path in chunk_files:
		_validate_chunk(chunk_path)

	print("\nValidation Summary:")
	print("  Chunks Validated : %d" % validated_chunks)
	print("  Errors           : %d" % errors.size())
	print("  Warnings         : %d" % warnings.size())

	if errors.size() > 0:
		print("\nErrors Found:")
		for err in errors:
			print("  [ERROR] " + err)
		print("==================================================")
		print("[ValidatorV1] RESULT: FAILED")
		quit(1)
	else:
		print("\n  [SUCCESS] All chunks conform to 80% physical reach & rise fairness constraints!")
		print("==================================================")
		print("[ValidatorV1] RESULT: PASSED (Spec E Compliant)")
		quit(0)

func _validate_chunk(path: String) -> void:
	var scene = load(path)
	if scene == null:
		errors.append("Could not load scene: %s" % path)
		return

	var chunk = scene.instantiate() as Node2D
	if chunk == null:
		errors.append("Could not instantiate scene: %s" % path)
		return

	root.add_child(chunk)
	validated_chunks += 1
	var base_name = path.get_file()

	# Collect all elements
	var hazards: Array[Node2D] = []
	var platforms: Array[Node2D] = []
	var springs: Array[Node2D] = []

	_gather_elements(chunk, hazards, platforms, springs)

	# 1. Reaction window check: first obstacle must have adequate distance from chunk start (x=0)
	var first_obs_x = 9999.0
	for h in hazards:
		first_obs_x = minf(first_obs_x, h.global_position.x - chunk.global_position.x)
	for s in springs:
		first_obs_x = minf(first_obs_x, s.global_position.x - chunk.global_position.x)

	if first_obs_x < 9999.0:
		var reaction_at_max = first_obs_x / MAX_SPEED
		if first_obs_x < 100.0:
			warnings.append("%s: First obstacle placed very early at x=%.1f (reaction: %.2fs)" % [base_name, first_obs_x, reaction_at_max])

	# 2. Platform rise check
	for p in platforms:
		var rise_from_ground = 230.0 - (p.global_position.y - chunk.global_position.y)
		# If rise exceeds unassisted jump rise, check if assisted by a spring
		if rise_from_ground > MAX_RISE_ALLOWED:
			var has_assist = false
			for sp in springs:
				if absf(sp.global_position.x - p.global_position.x) <= 160.0:
					has_assist = true
					break
			if not has_assist:
				# Check if stepped from another lower platform
				for other in platforms:
					if other != p and other.global_position.x < p.global_position.x:
						var step_rise = other.global_position.y - p.global_position.y
						if step_rise > 0.0 and step_rise <= MAX_RISE_ALLOWED and (p.global_position.x - other.global_position.x) <= 140.0:
							has_assist = true
							break
			if not has_assist:
				errors.append("%s: Platform at y=%.1f (rise %.1fpx) exceeds 80%% max jump rise (%.1fpx) without spring/step assist" % [base_name, p.global_position.y - chunk.global_position.y, rise_from_ground, MAX_RISE_ALLOWED])

	# 3. Hazard unavoidable trap check: springs must not launch directly into a ceiling hazard
	for sp in springs:
		for h in hazards:
			if absf(h.global_position.x - sp.global_position.x) < 20.0 and h.global_position.y < sp.global_position.y:
				errors.append("%s: Spring at x=%.1f launches directly upward into hazard at y=%.1f" % [base_name, sp.global_position.x, h.global_position.x])

	chunk.queue_free()

func _gather_elements(node: Node, hazards: Array[Node2D], platforms: Array[Node2D], springs: Array[Node2D]) -> void:
	for child in node.get_children():
		if child is Hazard or (child is Area2D and (child.name.contains("Hazard") or child.name.contains("Spike") or child.name.contains("Cactus") or child.name.contains("Overhang"))):
			hazards.append(child as Node2D)
		elif child is Platform or (child is StaticBody2D and child.name.contains("Platform")):
			platforms.append(child as Node2D)
		elif child is BouncePad or (child is Area2D and (child.name.contains("Bounce") or child.name.contains("Spring") or child.name.contains("Mushroom") or child.name.contains("Stump") or child.name.contains("Vent") or child.name.contains("Launchpad"))):
			springs.append(child as Node2D)
		_gather_elements(child, hazards, platforms, springs)
