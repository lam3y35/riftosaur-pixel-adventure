class_name TestSaveService
extends RefCounted

const SaveServiceScript = preload("res://scripts/systems/save_service.gd")

func get_test_name() -> String:
	return "SaveServiceTest"

func test_default_data_schema() -> Variant:
	var service = SaveServiceScript.new()
	var defs = service.get_default_data()

	if defs["version"] != 1:
		return "Default version is not 1"
	if defs["best_score"] != 0:
		return "Default best_score is not 0"
	if not defs.has("settings") or not defs["settings"].has("sound_enabled"):
		return "Default settings schema missing required keys"
	return true

func test_atomic_save_and_load() -> Variant:
	var service = SaveServiceScript.new()
	service.data["best_score"] = 1250
	service.data["best_distance"] = 3450.5
	var success = service.save_game()

	if not success:
		return "SaveService.save_game() returned false"

	# Load in new instance
	var reader = SaveServiceScript.new()
	var loaded = reader.load_game()

	if loaded["best_score"] != 1250:
		return "Loaded best_score (%d) mismatch expected 1250" % loaded["best_score"]
	if loaded["best_distance"] != 3450.5:
		return "Loaded best_distance (%f) mismatch expected 3450.5" % loaded["best_distance"]

	return true

func test_high_score_update() -> Variant:
	var service = SaveServiceScript.new()
	service.data["best_score"] = 500
	service.data["best_distance"] = 1000.0
	service.data["total_runs"] = 5

	var improved = service.update_high_score(600, 1200.0)
	if not improved:
		return "Expected update_high_score to return true on improvement"
	if service.get_best_score() != 600:
		return "Best score not updated to 600"
	if service.data["total_runs"] != 6:
		return "Total runs was not incremented"

	var not_improved = service.update_high_score(400, 800.0)
	if not_improved:
		return "Expected update_high_score to return false when score did not improve"
	if service.get_best_score() != 600:
		return "Best score should remain 600"

	return true

func test_corrupted_save_recovery() -> Variant:
	# Deliberately corrupt the save file
	var corrupt_file = FileAccess.open(SaveServiceScript.SAVE_PATH, FileAccess.WRITE)
	if corrupt_file:
		corrupt_file.store_string("{ INVALID JSON GARBAGE ::: 123 }")
		corrupt_file.close()

	var service = SaveServiceScript.new()
	var recovered = service.load_game()

	if recovered["version"] != 1 or recovered["best_score"] != 0:
		return "Failed to safely recover default values from corrupt save file"

	# Clean up and restore valid save state
	service.data = service.get_default_data()
	service.save_game()

	return true

func test_points_addition_and_spending() -> Variant:
	var service = SaveServiceScript.new()
	service.data = service.get_default_data()
	service.data["points"] = 50

	var new_pts = service.add_points(100)
	if new_pts != 150 or service.get_points() != 150:
		return "Failed to add points correctly, expected 150 got %d" % service.get_points()

	var spent = service.spend_points(100)
	if not spent or service.get_points() != 50:
		return "Failed to spend 100 points, expected balance 50 got %d" % service.get_points()

	var overspent = service.spend_points(100)
	if overspent:
		return "Spend should have failed when points are insufficient"
	if service.get_points() != 50:
		return "Points balance should remain 50 after failed spend"

	return true

func test_skin_unlock_and_equip() -> Variant:
	var service = SaveServiceScript.new()
	service.data = service.get_default_data()

	if not service.is_skin_unlocked("classic"):
		return "Classic skin should be unlocked by default"
	if service.is_skin_unlocked("emerald"):
		return "Emerald skin should NOT be unlocked by default"

	var equip_locked = service.equip_skin("emerald")
	if equip_locked:
		return "Should not be able to equip a locked skin"

	service.unlock_skin("emerald")
	if not service.is_skin_unlocked("emerald"):
		return "Emerald skin should be unlocked after unlock_skin call"

	var equip_ok = service.equip_skin("emerald")
	if not equip_ok or service.get_equipped_skin() != "emerald":
		return "Failed to equip unlocked emerald skin"

	# Persistence check
	var reader = SaveServiceScript.new()
	reader.load_game()
	if reader.get_equipped_skin() != "emerald":
		return "Equipped skin did not persist across save/load"

	return true

func test_challenge_service_progress_tracking() -> Variant:
	var challenge_script = preload("res://scripts/systems/challenge_service.gd")
	var service = SaveServiceScript.new()
	service.data = service.get_default_data()
	service.data["points"] = 50

	var cs = challenge_script.new(service)

	# Simulate 5 jumps
	for i in range(5):
		cs.record_jump()

	if not service.is_challenge_completed("jump_5"):
		return "Challenge 'jump_5' should be completed after 5 jumps"
	if service.get_points() != 80: # 50 welcome + 30 reward
		return "Expected 80 points after 'jump_5' reward, got %d" % service.get_points()

	# Simulate run progress (score 80)
	cs.check_run_progress(55.0, 80, 1)

	if not service.is_challenge_completed("dist_50"):
		return "Challenge 'dist_50' should be completed after 80 score"
	if service.get_points() != 130: # 80 + 50 reward
		return "Expected 130 points after 'dist_50' reward, got %d" % service.get_points()

	# Duplicate check: running again shouldn't re-reward
	cs.check_run_progress(60.0, 90, 1)
	if service.get_points() != 130:
		return "Duplicate challenge completion should not award extra points"

	return true
