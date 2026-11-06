class_name SaveService
extends RefCounted

const SAVE_PATH: String = "user://save_game.json"
const TEMP_PATH: String = "user://save_game.tmp"
const BACKUP_PATH: String = "user://save_game.bak"
const CURRENT_VERSION: int = 2

var data: Dictionary = {}

func _init() -> void:
	load_game()

func get_default_data() -> Dictionary:
	return {
		"version": CURRENT_VERSION,
		"best_score": 0,
		"best_distance": 0.0,
		"total_runs": 0,
		"points": 50, # Welcome bonus for first time players
		"unlocked_skins": ["classic"],
		"equipped_skin": "classic",
		"completed_challenges": [],
		"mastery_challenges": [],
		"milestones": {
			"gems_collected_total": 0,
			"hazards_broken_total": 0,
			"max_world_reached": 1
		},
		"settings": {
			"sound_enabled": true,
			"vibration_enabled": true,
			"master_volume": 1.0,
			"volume_sfx": 1.0,
			"volume_music": 1.0,
			"reduce_motion": false,
			"high_contrast": false,
			"left_handed": false,
			"auto_hold_jump": false
		},
		"unlocks": ["classic_desert"]
	}

func migrate_data(loaded_data: Dictionary) -> Dictionary:
	var ver = int(loaded_data.get("version", 1))

	# Migration: Version 1 -> Version 2
	if ver < 2:
		if not loaded_data.has("mastery_challenges"):
			loaded_data["mastery_challenges"] = []
		if not loaded_data.has("milestones"):
			loaded_data["milestones"] = {
				"gems_collected_total": 0,
				"hazards_broken_total": 0,
				"max_world_reached": 1
			}
		if not loaded_data.has("settings") or typeof(loaded_data["settings"]) != TYPE_DICTIONARY:
			loaded_data["settings"] = get_default_data()["settings"]
		else:
			var defaults = get_default_data()["settings"]
			for k in defaults:
				if not loaded_data["settings"].has(k):
					loaded_data["settings"][k] = defaults[k]
		loaded_data["version"] = 2

	return loaded_data

func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		data = get_default_data()
		return data

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("[SaveService] Failed to open save file for reading. Using defaults.")
		data = get_default_data()
		return data

	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	var err = json.parse(content)
	if err != OK or typeof(json.data) != TYPE_DICTIONARY:
		push_warning("[SaveService] Corrupt save file detected. Backing up and resetting to defaults.")
		_backup_corrupted_file(content)
		data = get_default_data()
		return data

	var loaded_data: Dictionary = json.data
	# Validate schema
	if not loaded_data.has("version") or not loaded_data.has("best_score"):
		push_warning("[SaveService] Invalid save schema. Resetting to defaults.")
		data = get_default_data()
		return data

	data = migrate_data(loaded_data)
	return data

func save_game() -> bool:
	data["version"] = CURRENT_VERSION
	var json_string = JSON.stringify(data, "  ")

	# 1. Atomic write to temporary file
	var tmp_file = FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if tmp_file == null:
		push_warning("[SaveService] Failed to create temp save file: %s" % str(FileAccess.get_open_error()))
		return false

	tmp_file.store_string(json_string)
	tmp_file.close()

	# 2. Verify temporary file was written correctly
	var verify_file = FileAccess.open(TEMP_PATH, FileAccess.READ)
	if verify_file == null:
		push_warning("[SaveService] Failed to verify temp save file.")
		return false

	var verify_json = JSON.new()
	var parse_err = verify_json.parse(verify_file.get_as_text())
	verify_file.close()

	if parse_err != OK:
		push_warning("[SaveService] Temp save failed verification. Aborting write.")
		return false

	# 3. Create backup of current save file if it exists
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.copy_absolute(SAVE_PATH, BACKUP_PATH)

	# 4. Atomic rename temp file to main save file
	var dir = DirAccess.open("user://")
	if dir == null:
		push_warning("[SaveService] Failed to open user:// directory.")
		return false

	var rename_err = dir.rename(TEMP_PATH.replace("user://", ""), SAVE_PATH.replace("user://", ""))
	if rename_err != OK:
		# Fallback: copy and remove
		DirAccess.copy_absolute(TEMP_PATH, SAVE_PATH)
		DirAccess.remove_absolute(TEMP_PATH)

	return true

func update_high_score(new_score: int, new_distance: float) -> bool:
	var updated = false
	if new_score > data.get("best_score", 0):
		data["best_score"] = new_score
		updated = true
	if new_distance > data.get("best_distance", 0.0):
		data["best_distance"] = new_distance
		updated = true

	data["total_runs"] = data.get("total_runs", 0) + 1
	save_game()
	return updated

func get_best_score() -> int:
	return data.get("best_score", 0)

func get_best_distance() -> float:
	return data.get("best_distance", 0.0)

# Points Management
func get_points() -> int:
	return data.get("points", 0)

func add_points(amount: int) -> int:
	if amount <= 0:
		return get_points()
	var current = data.get("points", 0)
	data["points"] = current + amount
	save_game()
	return data["points"]

func spend_points(amount: int) -> bool:
	var current = data.get("points", 0)
	if current < amount:
		return false
	data["points"] = current - amount
	save_game()
	return true

# Skins Management
func get_unlocked_skins() -> Array:
	return data.get("unlocked_skins", ["classic"])

func is_skin_unlocked(skin_id: String) -> bool:
	var skins = get_unlocked_skins()
	return skins.has(skin_id)

func unlock_skin(skin_id: String) -> bool:
	var skins = get_unlocked_skins()
	if not skins.has(skin_id):
		skins.append(skin_id)
		data["unlocked_skins"] = skins
		save_game()
	return true

func get_equipped_skin() -> String:
	return data.get("equipped_skin", "classic")

func equip_skin(skin_id: String) -> bool:
	if not is_skin_unlocked(skin_id):
		return false
	data["equipped_skin"] = skin_id
	save_game()
	return true

# Challenges Management
func get_completed_challenges() -> Array:
	return data.get("completed_challenges", [])

func is_challenge_completed(challenge_id: String) -> bool:
	var comp = get_completed_challenges()
	return comp.has(challenge_id)

func complete_challenge(challenge_id: String, reward: int) -> bool:
	var comp = get_completed_challenges()
	if comp.has(challenge_id):
		return false # Already claimed
	comp.append(challenge_id)
	data["completed_challenges"] = comp
	add_points(reward) # Automatically awards points and saves
	return true

# Mastery Challenges & Milestones (Session 10)
func get_mastery_challenges() -> Array:
	return data.get("mastery_challenges", [])

func is_mastery_completed(challenge_id: String) -> bool:
	var comp = get_mastery_challenges()
	return comp.has(challenge_id)

func complete_mastery_challenge(challenge_id: String, reward: int = 50) -> bool:
	var comp = get_mastery_challenges()
	if comp.has(challenge_id):
		return false
	comp.append(challenge_id)
	data["mastery_challenges"] = comp
	add_points(reward)
	return true

func record_milestone(key: String, amount: int = 1) -> void:
	if not data.has("milestones") or typeof(data["milestones"]) != TYPE_DICTIONARY:
		data["milestones"] = get_default_data()["milestones"]
	data["milestones"][key] = int(data["milestones"].get(key, 0)) + amount
	save_game()

func get_milestone(key: String) -> int:
	if not data.has("milestones") or typeof(data["milestones"]) != TYPE_DICTIONARY:
		return 0
	return int(data["milestones"].get(key, 0))

# Settings & Accessibility Management
func get_setting(key: String, default_val = null) -> Variant:
	var s = data.get("settings", {})
	if s.has(key):
		return s[key]
	var defaults = get_default_data()["settings"]
	if defaults.has(key):
		return defaults[key]
	return default_val

func set_setting(key: String, val) -> void:
	if not data.has("settings") or typeof(data["settings"]) != TYPE_DICTIONARY:
		data["settings"] = get_default_data()["settings"]
	data["settings"][key] = val
	save_game()

func _backup_corrupted_file(content: String) -> void:
	var corrupt_path = "user://save_corrupt_%d.txt" % Time.get_unix_time_from_system()
	var f = FileAccess.open(corrupt_path, FileAccess.WRITE)
	if f:
		f.store_string(content)
		f.close()
