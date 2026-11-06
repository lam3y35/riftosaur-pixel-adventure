class_name TestWorldThemes
extends RefCounted

const ParallaxBgScene = preload("res://scenes/world/parallax_background.tscn")
const TransitionChunkScene = preload("res://scenes/obstacles/chunks/chunk_00_world_transition.tscn")

func get_test_name() -> String:
	return "WorldThemesAndTransitionsTest"

# 1. Theme Validation: All 4 launch themes
func test_four_launch_world_themes_validation() -> Variant:
	var theme_paths = [
		"res://resources/themes/theme_01_plains.tres",
		"res://resources/themes/theme_02_jungle.tres",
		"res://resources/themes/theme_03_frozen.tres",
		"res://resources/themes/theme_04_volcanic.tres"
	]

	var expected_mods = ["NONE", "CANOPY_ROUTES", "SLIPPERY_SURFACES", "VOLCANIC_ERUPTIONS"]

	for i in range(theme_paths.size()):
		var p = theme_paths[i]
		if not ResourceLoader.exists(p):
			return "Missing world theme resource: %s" % p

		var theme = load(p) as WorldTheme
		if theme == null:
			return "Failed to load WorldTheme resource: %s" % p

		if theme.world_name == "" or theme.world_id == "":
			return "Theme at %s has blank name or id" % p

		if theme.gameplay_modifier != expected_mods[i]:
			return "Theme %s has modifier %s, expected %s" % [theme.world_name, theme.gameplay_modifier, expected_mods[i]]

		# Check asset existence
		if not ResourceLoader.exists(theme.sky_texture_path):
			return "Missing sky texture for %s: %s" % [theme.world_name, theme.sky_texture_path]
		if not ResourceLoader.exists(theme.distant_texture_path):
			return "Missing distant texture for %s: %s" % [theme.world_name, theme.distant_texture_path]
		if not ResourceLoader.exists(theme.mid_texture_path):
			return "Missing mid texture for %s: %s" % [theme.world_name, theme.mid_texture_path]
		if not ResourceLoader.exists(theme.ground_tile_path):
			return "Missing ground tile for %s: %s" % [theme.world_name, theme.ground_tile_path]

	return true

# 2. Extensibility Test: Dynamic custom test-only world theme
func test_extensibility_custom_world_theme() -> Variant:
	# Spec: "Extensibility test: a test-only world added with no unrelated system changing."
	var custom_theme = WorldTheme.new()
	custom_theme.world_id = "lunar_outpost"
	custom_theme.world_name = "Lunar Outpost"
	custom_theme.mechanic_intro = "Low gravity moon craters and stellar cosmic dust"
	custom_theme.sky_texture_path = "res://assets/sprites/bg_sky.png"
	custom_theme.distant_texture_path = "res://assets/sprites/bg_mountains.png"
	custom_theme.mid_texture_path = "res://assets/sprites/bg_hills.png"
	custom_theme.ground_tile_path = "res://assets/sprites/ground_tile.png"
	custom_theme.ambient_tint = Color(0.7, 0.75, 1.2, 1.0)
	custom_theme.gameplay_modifier = "LOW_GRAVITY"
	custom_theme.transition_distance_m = 2000.0

	var parallax = ParallaxBgScene.instantiate() as ParallaxController
	var tree = Engine.get_main_loop() as SceneTree
	tree.root.add_child(parallax)

	parallax.apply_theme_immediate(custom_theme)

	if parallax.current_theme != custom_theme:
		parallax.queue_free()
		return "Failed to apply custom extensible world theme"

	if parallax.sky_sprite and parallax.sky_sprite.modulate != custom_theme.ambient_tint:
		parallax.queue_free()
		return "Ambient tint was not applied for custom world theme"

	parallax.queue_free()
	return true

# 3. Safe World Transition Chunk Verification (Spec C: Zero hazards, safe landing runway)
func test_safe_transition_chunk_zero_hazards() -> Variant:
	var chunk = TransitionChunkScene.instantiate() as Node2D

	# Check for any hazards in chunk
	var hazard_count = 0
	for child in chunk.get_children():
		if child is Hazard or child.name.to_lower().contains("hazard") or child.name.to_lower().contains("obstacle"):
			hazard_count += 1
		for subchild in child.get_children():
			if subchild is Hazard:
				hazard_count += 1

	if hazard_count > 0:
		chunk.queue_free()
		return "Transition chunk must have 0 hazards, found %d" % hazard_count

	# Check ground body exists for safe landing
	var ground = chunk.get_node_or_null("Ground") as StaticBody2D
	if ground == null:
		chunk.queue_free()
		return "Transition chunk is missing safe ground StaticBody2D"

	chunk.queue_free()
	return true

# 4. Parallax Background Smooth Cross-Fade
func test_parallax_transition_crossfade() -> Variant:
	var parallax = ParallaxBgScene.instantiate() as ParallaxController
	var tree = Engine.get_main_loop() as SceneTree
	tree.root.add_child(parallax)

	var jungle_theme = load("res://resources/themes/theme_02_jungle.tres") as WorldTheme
	parallax.transition_to_theme(jungle_theme, 0.2)

	if parallax.current_theme != jungle_theme:
		parallax.queue_free()
		return "Expected current_theme to update to Jungle"

	parallax.queue_free()
	return true
