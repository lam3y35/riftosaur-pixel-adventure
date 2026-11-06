class_name TestUIAndScreens
extends RefCounted

## Unit test suite for Session 9: Screens, settings, accessibility, controls, and audio.

const SaveService = preload("res://scripts/systems/save_service.gd")
const AudioManager = preload("res://scripts/systems/audio_manager.gd")
const EndlessRunner = preload("res://scripts/gameplay/endless_runner.gd")

func get_test_name() -> String:
	return "UIAndScreensTest"

func test_settings_persistence_and_defaults() -> void:
	var save = SaveService.new()
	assert(save.get_setting("sound_enabled", true) == true, "Default sound enabled should be true")
	assert(save.get_setting("vibration_enabled", true) == true, "Default vibration should be true")
	assert(save.get_setting("reduce_motion", false) == false, "Default reduce motion should be false")
	assert(save.get_setting("left_handed", false) == false, "Default left handed should be false")

	# Modify and save
	save.set_setting("sound_enabled", false)
	save.set_setting("left_handed", true)
	assert(save.get_setting("sound_enabled", true) == false, "Sound enabled should update to false")
	assert(save.get_setting("left_handed", false) == true, "Left handed should update to true")

	# Re-instantiate SaveService and verify persistence
	var save2 = SaveService.new()
	assert(save2.get_setting("sound_enabled", true) == false, "Sound enabled must persist across instances")
	assert(save2.get_setting("left_handed", false) == true, "Left handed must persist across instances")

	# Restore defaults
	save2.set_setting("sound_enabled", true)
	save2.set_setting("left_handed", false)

func test_audio_manager_respects_settings() -> void:
	var save = SaveService.new()
	var audio = AudioManager.new(save)
	Engine.get_main_loop().root.add_child(audio)

	# Sound enabled
	save.set_setting("sound_enabled", true)
	audio.play_jump()
	var p = audio._get_available_player()
	assert(p != null, "Audio player should be available")

	# Sound disabled
	save.set_setting("sound_enabled", false)
	audio.play_jump()
	# Sound should be skipped silently without error

	save.set_setting("sound_enabled", true)
	audio.queue_free()

func test_hud_control_layout_left_handed_switch() -> void:
	var hud_scene = load("res://scenes/ui/hud.tscn")
	var hud = hud_scene.instantiate() as GameHUD
	Engine.get_main_loop().root.add_child(hud)

	# Right handed (default)
	hud.apply_control_layout(false)
	assert(hud.jump_button.anchor_left == 1.0, "Right-handed jump button should anchor right")
	assert(hud.slide_button.anchor_left == 0.0, "Right-handed slide button should anchor left")

	# Left handed
	hud.apply_control_layout(true)
	assert(hud.jump_button.anchor_left == 0.0, "Left-handed jump button should anchor left")
	assert(hud.slide_button.anchor_left == 1.0, "Left-handed slide button should anchor right")

	hud.queue_free()

func test_tutorial_dialog_five_steps_navigation() -> void:
	var hud_scene = load("res://scenes/ui/hud.tscn")
	var hud = hud_scene.instantiate() as GameHUD
	Engine.get_main_loop().root.add_child(hud)

	hud.open_tutorial()
	assert(hud.tutorial_dialog.visible == true, "Tutorial dialog should be open")
	assert(hud.tutorial_step == 0, "Initial step should be 0 (Step 1)")
	assert(hud.tutorial_step_label.text.contains("STEP 1/5"), "Step 1 title should match")

	# Next step
	hud._on_tutorial_next_pressed()
	assert(hud.tutorial_step == 1, "Should advance to Step 2")
	assert(hud.tutorial_step_label.text.contains("STEP 2/5"), "Step 2 title should match")

	# Advance to last step
	hud._on_tutorial_next_pressed() # Step 3
	hud._on_tutorial_next_pressed() # Step 4
	hud._on_tutorial_next_pressed() # Step 5
	assert(hud.tutorial_step == 4, "Should be on Step 5 (index 4)")
	assert(hud.tutorial_next_btn.text.contains("FINISH"), "Final step next button should say FINISH")

	# Finish closes tutorial
	hud._on_tutorial_next_pressed()
	assert(hud.tutorial_dialog.visible == false, "Tutorial should close after final step")

	hud.queue_free()

func test_practice_mode_settings_and_no_highscore() -> void:
	var runner_scene = load("res://scenes/gameplay/endless_runner.tscn")
	var runner = runner_scene.instantiate() as EndlessRunner
	Engine.get_main_loop().root.add_child(runner)

	# Select Practice Mode (mode 3)
	runner.hud.select_mode(3)
	runner.begin_run()

	assert(runner.player.current_speed == 196.0, "Practice mode speed should be 196 px/s (70% of 280)")
	assert(runner.player.config.coyote_time == 0.12, "Practice mode coyote time should be 1.5x (0.12s)")
	assert(runner.player.config.jump_buffer_time == 0.20, "Practice mode buffer time should be 0.20s")
	assert(runner.player.skill_manager.has_shield == true, "Practice mode should grant free hit shield")

	# Die in practice mode with a score
	runner.current_score = 999999
	var old_best = runner.save_service.get_best_score()
	runner._on_player_died("Practice obstacle hit")

	assert(runner.save_service.get_best_score() == old_best, "Practice runs must never update best score")

	runner.queue_free()

func test_screens_open_close_navigation() -> void:
	var hud_scene = load("res://scenes/ui/hud.tscn")
	var hud = hud_scene.instantiate() as GameHUD
	Engine.get_main_loop().root.add_child(hud)

	# Settings
	hud.open_settings("start")
	assert(hud.settings_dialog.visible == true, "Settings dialog should open")
	hud.close_settings()
	assert(hud.settings_dialog.visible == false, "Settings dialog should close")

	# Credits
	hud.open_credits()
	assert(hud.credits_dialog.visible == true, "Credits dialog should open")
	hud.close_credits()
	assert(hud.credits_dialog.visible == false, "Credits dialog should close")

	hud.queue_free()
