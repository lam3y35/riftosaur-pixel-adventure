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
