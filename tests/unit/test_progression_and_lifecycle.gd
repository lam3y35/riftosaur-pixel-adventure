class_name TestProgressionAndLifecycle
extends RefCounted

## Unit test suite for Session 10: Progression, save migrations, Android lifecycle,
## mastery challenges, and back button hierarchy.

const SaveService = preload("res://scripts/systems/save_service.gd")
const EndlessRunner = preload("res://scripts/gameplay/endless_runner.gd")

func get_test_name() -> String:
	return "ProgressionAndLifecycleTest"

func test_save_schema_v1_to_v2_migration() -> void:
	var save = SaveService.new()
	var raw_v1: Dictionary = {
		"version": 1,
		"best_score": 1420,
		"best_distance": 950.0,
		"total_runs": 12,
		"points": 240,
		"unlocked_skins": ["classic", "emerald"],
		"equipped_skin": "emerald",
		"completed_challenges": ["ch_first_jump"],
		"settings": {
			"sound_enabled": true,
			"vibration_enabled": false
		}
	}

	var migrated = save.migrate_data(raw_v1)
	assert(migrated["version"] == 2, "Migrated version must be 2")
	assert(migrated.has("mastery_challenges"), "Must create mastery_challenges array")
	assert(typeof(migrated["mastery_challenges"]) == TYPE_ARRAY, "mastery_challenges must be an array")
	assert(migrated.has("milestones"), "Must create milestones dictionary")
	assert(migrated["milestones"]["gems_collected_total"] == 0, "Default gems collected milestone")
	assert(migrated["settings"]["sound_enabled"] == true, "Must preserve existing setting sound_enabled")
	assert(migrated["settings"]["vibration_enabled"] == false, "Must preserve existing setting vibration_enabled")
	assert(migrated["settings"].has("reduce_motion"), "Must populate missing setting reduce_motion")
	assert(migrated["settings"].has("left_handed"), "Must populate missing setting left_handed")
	assert(migrated["best_score"] == 1420, "Must preserve player best_score")
	assert(migrated["equipped_skin"] == "emerald", "Must preserve equipped skin")

func test_mastery_challenges_completion_and_points() -> void:
	var save = SaveService.new()
	var starting_pts = save.get_points()

	var success = save.complete_mastery_challenge("mastery_clean_flight_500m", 75)
	assert(success == true, "First completion should return true")
	assert(save.is_mastery_completed("mastery_clean_flight_500m") == true, "Should report completed")
	assert(save.get_points() == starting_pts + 75, "Points should increment by reward")

	# Duplicate claim prevention
	var dup_success = save.complete_mastery_challenge("mastery_clean_flight_500m", 75)
	assert(dup_success == false, "Duplicate claim must return false")
	assert(save.get_points() == starting_pts + 75, "Points must not be awarded twice")

func test_milestones_tracking() -> void:
	var save = SaveService.new()
	var cur_gems = save.get_milestone("gems_collected_total")
	save.record_milestone("gems_collected_total", 15)
	assert(save.get_milestone("gems_collected_total") == cur_gems + 15, "Milestone should record delta")

	save.record_milestone("hazards_broken_total", 3)
	assert(save.get_milestone("hazards_broken_total") >= 3, "Hazards broken should increment")

func test_android_lifecycle_focus_loss_auto_pauses() -> void:
	var runner_scene = load("res://scenes/gameplay/endless_runner.tscn")
	var runner = runner_scene.instantiate() as EndlessRunner
	Engine.get_main_loop().root.add_child(runner)

	runner.begin_run()
	assert(runner.is_game_started == true and runner.is_paused == false, "Run should be active")

	runner.player.jump_held = true
	runner.player.slide_held = true

	# Simulate Android app focus loss / paused lifecycle
	runner._notification(Node.NOTIFICATION_APPLICATION_PAUSED)

	assert(runner.is_paused == true, "Game must auto-pause on Android focus loss / backgrounding")
	assert(runner.player.jump_held == false, "Held inputs must be released on pause")
	assert(runner.player.slide_held == false, "Held slide must be released on pause")
	assert(runner.hud.pause_menu.visible == true, "Pause menu should be displayed")

	runner.queue_free()

func test_android_back_button_hierarchical_dismissal() -> void:
	var runner_scene = load("res://scenes/gameplay/endless_runner.tscn")
	var runner = runner_scene.instantiate() as EndlessRunner
	Engine.get_main_loop().root.add_child(runner)

	# 1. Back button closes open dialogs without affecting game state
	runner.hud.open_settings("start")
	assert(runner.hud.settings_dialog.visible == true, "Settings dialog should be open")

	runner._handle_back_action()
	assert(runner.hud.settings_dialog.visible == false, "Back action must close Settings dialog")

	# 2. Back button during active run pauses the game
	runner.begin_run()
	assert(runner.is_paused == false, "Run should be unpaused")

	runner._handle_back_action()
	assert(runner.is_paused == true, "Back action during run must pause gameplay")

	# 3. Back button while paused resumes gameplay
	runner._handle_back_action()
	assert(runner.is_paused == false, "Back action on pause menu resumes gameplay")

	runner.queue_free()
