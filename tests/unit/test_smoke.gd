class_name TestSmoke
extends RefCounted

func get_test_name() -> String:
	return "SmokeTest"

func test_project_name_and_identity() -> Variant:
	var proj_name = ProjectSettings.get_setting("application/config/name")
	if proj_name != "Riftosaur":
		return "Expected project name 'Riftosaur', got '%s'" % proj_name
	return true

func test_viewport_resolution_and_pixel_art() -> Variant:
	var w = ProjectSettings.get_setting("display/window/size/viewport_width")
	var h = ProjectSettings.get_setting("display/window/size/viewport_height")
	if w != 480 or h != 270:
		return "Expected viewport 480x270, got %dx%d" % [w, h]

	var filter = ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter")
	if filter != 0:
		return "Expected nearest texture filter (0), got %s" % str(filter)
	return true

func test_required_input_actions() -> Variant:
	var required_actions: Array[String] = ["jump", "slide", "skill", "pause"]
	for action in required_actions:
		if not InputMap.has_action(action):
			return "Missing required input action '%s'" % action
		var events = InputMap.action_get_events(action)
		if events.is_empty():
			return "Input action '%s' has no bound events" % action
	return true

func test_main_scene_load_and_instance() -> Variant:
	var main_scene_path: String = ProjectSettings.get_setting("application/run/main_scene")
	if not ResourceLoader.exists(main_scene_path):
		return "Main scene resource '%s' does not exist" % main_scene_path

	var packed = load(main_scene_path) as PackedScene
	if packed == null:
		return "Failed to load PackedScene '%s'" % main_scene_path

	var instance = packed.instantiate()
	if instance == null:
		return "Failed to instantiate main scene"
	instance.free()
	return true

func test_deterministic_random_seed() -> Variant:
	seed(1337)
	var first_val: int = randi()
	var second_val: int = randi()

	seed(1337)
	var re_first: int = randi()
	var re_second: int = randi()

	if first_val != re_first or second_val != re_second:
		return "RNG is not deterministic with fixed seed 1337"
	return true
