class_name ValidateL1
extends SceneTree

func _init() -> void:
	print("==================================================")
	print("[ValidateL1] Starting L1 Static Validation")
	print("==================================================")
	call_deferred("_validate")

func _validate() -> void:
	var errors: Array[String] = []

	# 1. Project configuration checks
	var proj_name: String = ProjectSettings.get_setting("application/config/name", "")
	if proj_name != "Riftosaur":
		errors.append("Invalid project name: '%s' (expected 'Riftosaur')" % proj_name)

	var w: int = ProjectSettings.get_setting("display/window/size/viewport_width", 0)
	var h: int = ProjectSettings.get_setting("display/window/size/viewport_height", 0)
	if w != 480 or h != 270:
		errors.append("Invalid logical viewport: %dx%d (expected 480x270)" % [w, h])

	var filter = ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter", -1)
	if filter != 0:
		errors.append("Default texture filter must be nearest (0), got: %s" % str(filter))

	var renderer = ProjectSettings.get_setting("rendering/renderer/rendering_method", "")
	if renderer != "gl_compatibility":
		errors.append("Renderer should be gl_compatibility for mobile/pixel-art target, got: %s" % renderer)

	# 2. Input action checks
	var required_actions: Array[String] = ["jump", "slide", "skill", "pause"]
	for act in required_actions:
		if not InputMap.has_action(act):
			errors.append("Required input action missing: %s" % act)
		else:
			var events = InputMap.action_get_events(act)
			if events.is_empty():
				errors.append("Input action has no events bound: %s" % act)

	# 3. Critical scenes, resources & paths
	var critical_paths: Array[String] = [
		"res://scenes/main/main.tscn",
		"res://scenes/player/player.tscn",
		"res://scenes/gameplay/flat_test_track.tscn",
		"res://resources/gameplay_config/gameplay_config.tres",
		"res://assets/sprites/dinosaur_sheet.png"
	]
	for cp in critical_paths:
		if not ResourceLoader.exists(cp):
			errors.append("Critical resource '%s' does not exist" % cp)
		else:
			var res = load(cp)
			if res == null:
				errors.append("Failed to load resource '%s'" % cp)

	# 4. Summary
	print("\nValidation Findings:")
	if errors.is_empty():
		print("  [SUCCESS] All static L1 checks passed with 0 errors!")
		print("==================================================")
		print("[ValidateL1] RESULT: PASSED (L1 Static)")
		quit(0)
	else:
		for err in errors:
			printerr("  [ERROR] %s" % err)
		print("==================================================")
		print("[ValidateL1] RESULT: FAILED with %d errors" % errors.size())
		quit(1)
