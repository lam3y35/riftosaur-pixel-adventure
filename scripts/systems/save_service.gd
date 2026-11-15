class_name SaveService
extends RefCounted

const SAVE_PATH: String = "user://save_game.json"
const TEMP_PATH: String = "user://save_game.tmp"
const BACKUP_PATH: String = "user://save_game.bak"
const CORRUPT_BACKUP_PATH: String = "user://save_corrupt.bak"
const CURRENT_VERSION: int = 2
const SAVE_ENVELOPE_ALG: String = "HMAC-SHA256"
const _APP_HMAC_PEPPER: String = "Riftosaur::v2::LocalIntegrity::2026::7f9a3d"

const MAX_SCORE: int = 10000000
const MAX_DISTANCE: float = 1000000.0
const MAX_POINTS: int = 10000000
const MAX_REWARD: int = 5000
const MAX_RUNS: int = 1000000
const MAX_SAVE_FILE_BYTES: int = 262144

const SKIN_CATALOG: Dictionary = {
	"classic": 0,
	"emerald": 100,
	"ruby": 250,
	"cyber": 500,
	"gold": 1000
}

const VALID_MILESTONES: PackedStringArray = [
	"gems_collected_total",
	"hazards_broken_total",
	"max_world_reached",
	"total_near_misses",
	"max_combo_best"
]

var data: Dictionary = {}
var _dirty: bool = false

func mark_dirty() -> void:
	_dirty = true

func flush_if_dirty() -> bool:
	if _dirty:
		return save_game()
	return true

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
			"max_world_reached": 1,
			"total_near_misses": 0,
			"max_combo_best": 0
		},
		"settings": {
			"sound_enabled": true,
			"vibration_enabled": true,
			"master_volume": 1.0,
			"volume_sfx": 1.0,
			"volume_music": 0.75,
			"reduce_motion": false,
			"high_contrast": false,
			"left_handed": false,
			"auto_hold_jump": false,
			"dev_overlay": false
		},
		"unlocks": ["classic_desert"]
	}

func migrate_data(loaded_data: Dictionary) -> Dictionary:
	var ver = _safe_int(loaded_data.get("version", 1), 1)

	# Migration: Version 1 -> Version 2
	if ver < 2:
		if not loaded_data.has("mastery_challenges"):
			loaded_data["mastery_challenges"] = []
		if not loaded_data.has("milestones"):
			loaded_data["milestones"] = get_default_data()["milestones"]
		if not loaded_data.has("settings") or typeof(loaded_data["settings"]) != TYPE_DICTIONARY:
			loaded_data["settings"] = get_default_data()["settings"]
		else:
			var defaults = get_default_data()["settings"]
			for k in defaults:
				if not loaded_data["settings"].has(k):
					loaded_data["settings"][k] = defaults[k]
		loaded_data["version"] = 2

	return _sanitize_data(loaded_data)

func _get_hmac_key() -> PackedByteArray:
	var device_id = OS.get_unique_id()
	if device_id.is_empty():
		device_id = "riftosaur_offline_host"
	return (_APP_HMAC_PEPPER + "|" + device_id).to_utf8_buffer()

func _compute_hmac_hex(payload_str: String) -> String:
	var ctx = HMACContext.new()
	if ctx.start(HashingContext.HASH_SHA256, _get_hmac_key()) != OK:
		return ""
	ctx.update(payload_str.to_utf8_buffer())
	var digest: PackedByteArray = ctx.finish()
	return digest.hex_encode()

func _constant_time_eq(a: String, b: String) -> bool:
	if a.length() != b.length() or a.is_empty():
		return false
	var diff: int = 0
	for i in range(a.length()):
		diff |= (a.unicode_at(i) ^ b.unicode_at(i))
	return diff == 0

func _try_parse_verified_envelope(content: String) -> Dictionary:
	var json = JSON.new()
	if json.parse(content) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return {}
	var env: Dictionary = json.data
	if str(env.get("alg", "")) != SAVE_ENVELOPE_ALG:
		return {}
	if typeof(env.get("payload", null)) != TYPE_STRING or typeof(env.get("sig", null)) != TYPE_STRING:
		return {}
	var payload_str: String = env["payload"]
	var sig_hex: String = env["sig"]
	var expected_sig: String = _compute_hmac_hex(payload_str)
	if not _constant_time_eq(sig_hex, expected_sig):
		return {}

	var payload_json = JSON.new()
	if payload_json.parse(payload_str) != OK or typeof(payload_json.data) != TYPE_DICTIONARY:
		return {}
	var loaded_data: Dictionary = payload_json.data
	if not loaded_data.has("version") or not loaded_data.has("best_score"):
		return {}
	return loaded_data

func _safe_int(val, fallback: int) -> int:
	if typeof(val) == TYPE_INT:
		return int(val)
	if typeof(val) == TYPE_FLOAT:
		var f: float = float(val)
		if is_nan(f) or is_inf(f):
			return fallback
		return int(clampf(f, -2147483647.0, 2147483647.0))
	return fallback

func _safe_float(val, fallback: float) -> float:
	if typeof(val) == TYPE_FLOAT or typeof(val) == TYPE_INT:
		var f: float = float(val)
		if is_nan(f) or is_inf(f):
			return fallback
		return f
	return fallback

func _is_valid_id(id_str: String, required_prefix: String = "") -> bool:
	if id_str.length() < maxi(2, required_prefix.length() + 1) or id_str.length() > 64:
		return false
	if not required_prefix.is_empty() and not id_str.begins_with(required_prefix):
		return false
	for i in range(id_str.length()):
		var c := id_str.unicode_at(i)
		var ok := (c >= 97 and c <= 122) or (c >= 48 and c <= 57) or c == 95
		if not ok:
			return false
	return true

func _sanitize_data(raw: Dictionary) -> Dictionary:
	var defaults = get_default_data()
	var clean: Dictionary = defaults.duplicate(true)

	clean["version"] = CURRENT_VERSION
	clean["best_score"] = clampi(_safe_int(raw.get("best_score", 0), 0), 0, MAX_SCORE)
	clean["best_distance"] = clampf(_safe_float(raw.get("best_distance", 0.0), 0.0), 0.0, MAX_DISTANCE)
	clean["total_runs"] = clampi(_safe_int(raw.get("total_runs", 0), 0), 0, MAX_RUNS)
	clean["points"] = clampi(_safe_int(raw.get("points", defaults["points"]), int(defaults["points"])), 0, MAX_POINTS)

	var valid_skins: Array = ["classic"]
	if typeof(raw.get("unlocked_skins", null)) == TYPE_ARRAY:
		for s in raw["unlocked_skins"]:
			if typeof(s) == TYPE_STRING and SKIN_CATALOG.has(s) and not valid_skins.has(s):
				valid_skins.append(s)
	clean["unlocked_skins"] = valid_skins

	var eq_raw = raw.get("equipped_skin", "classic")
	var eq = eq_raw if typeof(eq_raw) == TYPE_STRING else "classic"
	clean["equipped_skin"] = eq if valid_skins.has(eq) else "classic"

	clean["completed_challenges"] = _sanitize_string_array(raw.get("completed_challenges", []), "")
	clean["mastery_challenges"] = _sanitize_string_array(raw.get("mastery_challenges", []), "mastery_")
	clean["unlocks"] = _sanitize_string_array(raw.get("unlocks", defaults["unlocks"]))

	if typeof(raw.get("milestones", null)) == TYPE_DICTIONARY:
		var ms: Dictionary = raw["milestones"]
		for k in clean["milestones"].keys():
			if ms.has(k):
				var min_val = 1 if k == "max_world_reached" else 0
				clean["milestones"][k] = clampi(_safe_int(ms[k], min_val), min_val, MAX_SCORE)

	if typeof(raw.get("settings", null)) == TYPE_DICTIONARY:
		var st: Dictionary = raw["settings"]
		var def_st: Dictionary = defaults["settings"]
		for k in def_st.keys():
			if st.has(k):
				var def_v = def_st[k]
				if typeof(def_v) == TYPE_BOOL and typeof(st[k]) == TYPE_BOOL:
					clean["settings"][k] = st[k]
				elif typeof(def_v) == TYPE_FLOAT and (typeof(st[k]) == TYPE_FLOAT or typeof(st[k]) == TYPE_INT):
					var fv = _safe_float(st[k], float(def_v))
					clean["settings"][k] = clampf(fv, 0.0, 1.0)

	return clean

func _sanitize_string_array(val, required_prefix: String = "") -> Array:
	var out: Array = []
	if typeof(val) != TYPE_ARRAY:
		return out
	for item in val:
		if typeof(item) == TYPE_STRING and _is_valid_id(item, required_prefix) and not out.has(item):
			out.append(item)
	return out

func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		data = get_default_data()
		return data

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("[SaveService] Failed to open save file for reading. Using defaults.")
		data = get_default_data()
		return data

	if file.get_length() > MAX_SAVE_FILE_BYTES:
		file.close()
		push_warning("[SaveService] Save file exceeds max safe size. Resetting to defaults.")
		data = get_default_data()
		return data

	var content = file.get_as_text()
	file.close()

	var loaded_data = _try_parse_verified_envelope(content)
	if loaded_data.is_empty():
		push_warning("[SaveService] Corrupt or tampered save file detected. Quarantining and resetting to defaults.")
		_backup_corrupted_file(content)
		data = get_default_data()
		return data

	data = migrate_data(loaded_data)
	return data

func save_game() -> bool:
	data = _sanitize_data(data)
	data["version"] = CURRENT_VERSION
	var payload_str = JSON.stringify(data)
	var envelope: Dictionary = {
		"alg": SAVE_ENVELOPE_ALG,
		"payload": payload_str,
		"sig": _compute_hmac_hex(payload_str)
	}
	var json_string = JSON.stringify(envelope, "  ")
	if _try_parse_verified_envelope(json_string).is_empty():
		push_warning("[SaveService] Serialized save failed self-verification. Aborting write.")
		return false

	# 1. Atomic write to temporary file
	var tmp_file = FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if tmp_file == null:
		push_warning("[SaveService] Failed to create temp save file: %s" % str(FileAccess.get_open_error()))
		return false

	tmp_file.store_string(json_string)
	tmp_file.flush()
	tmp_file.close()

	# 2. Backup existing primary save if present
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.copy_absolute(SAVE_PATH, BACKUP_PATH)

	# 3. Atomic rename temp file to main save file
	var dir = DirAccess.open("user://")
	if dir == null:
		push_warning("[SaveService] Failed to open user:// directory.")
		return false

	var rename_err = dir.rename(TEMP_PATH.replace("user://", ""), SAVE_PATH.replace("user://", ""))
	if rename_err != OK:
		var copy_err = DirAccess.copy_absolute(TEMP_PATH, SAVE_PATH)
		if copy_err == OK:
			DirAccess.remove_absolute(TEMP_PATH)
		else:
			# Direct write fallback when Windows AV holds transient locks on TEMP/SAVE rename
			var direct = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
			if direct == null:
				push_warning("[SaveService] Failed to finalize save write: %s" % str(copy_err))
				return false
			direct.store_string(json_string)
			direct.close()
			if FileAccess.file_exists(TEMP_PATH):
				DirAccess.remove_absolute(TEMP_PATH)

	_dirty = false
	return true

func update_high_score(new_score: int, new_distance: float, flush: bool = true) -> bool:
	var updated = false
	var safe_score = clampi(new_score, 0, MAX_SCORE)
	var safe_dist = clampf(0.0 if (is_nan(new_distance) or is_inf(new_distance)) else new_distance, 0.0, MAX_DISTANCE)
	if safe_score > get_best_score():
		data["best_score"] = safe_score
		updated = true
	if safe_dist > get_best_distance():
		data["best_distance"] = safe_dist
		updated = true

	data["total_runs"] = clampi(get_lifetime_stat("total_runs") + 1, 0, MAX_RUNS)
	if flush:
		save_game()
	else:
		_dirty = true
	return updated

func get_best_score() -> int:
	return clampi(_safe_int(data.get("best_score", 0), 0), 0, MAX_SCORE)

func get_best_distance() -> float:
	return clampf(_safe_float(data.get("best_distance", 0.0), 0.0), 0.0, MAX_DISTANCE)

func get_lifetime_stat(stat_name: String) -> int:
	if stat_name == "total_runs":
		return clampi(_safe_int(data.get("total_runs", 0), 0), 0, MAX_RUNS)
	if stat_name == "max_distance":
		return int(get_best_distance())
	return get_milestone(stat_name)

# Points Management
func get_points() -> int:
	return clampi(_safe_int(data.get("points", 0), 0), 0, MAX_POINTS)

func add_points(amount: int, flush: bool = true) -> int:
	if amount <= 0:
		return get_points()
	var clamped = mini(amount, MAX_REWARD)
	var current = _safe_int(data.get("points", 0), 0)
	data["points"] = clampi(current + clamped, 0, MAX_POINTS)
	if flush:
		save_game()
	else:
		_dirty = true
	return data["points"]

func spend_points(amount: int) -> bool:
	if amount <= 0:
		return false
	var current = _safe_int(data.get("points", 0), 0)
	if current < amount:
		return false
	data["points"] = current - amount
	save_game()
	return true

# Skins Management
func get_skin_price(skin_id: String) -> int:
	return int(SKIN_CATALOG.get(skin_id, -1))

func purchase_skin(skin_id: String) -> bool:
	if not SKIN_CATALOG.has(skin_id):
		return false
	if is_skin_unlocked(skin_id):
		return equip_skin(skin_id)
	var price: int = int(SKIN_CATALOG[skin_id])
	if price < 0:
		return false
	var current = _safe_int(data.get("points", 0), 0)
	if current < price:
		return false
	data["points"] = current - price
	var skins = get_unlocked_skins()
	skins.append(skin_id)
	data["unlocked_skins"] = skins
	data["equipped_skin"] = skin_id
	save_game()
	return true

func get_unlocked_skins() -> Array:
	var val = data.get("unlocked_skins", ["classic"])
	return val if typeof(val) == TYPE_ARRAY else ["classic"]

func is_skin_unlocked(skin_id: String) -> bool:
	var skins = get_unlocked_skins()
	return skins.has(skin_id)

func unlock_skin(skin_id: String) -> bool:
	if not SKIN_CATALOG.has(skin_id):
		return false
	var skins = get_unlocked_skins()
	if not skins.has(skin_id):
		skins.append(skin_id)
		data["unlocked_skins"] = skins
		save_game()
	return true

func get_equipped_skin() -> String:
	var eq = data.get("equipped_skin", "classic")
	return eq if (typeof(eq) == TYPE_STRING and SKIN_CATALOG.has(eq)) else "classic"

func equip_skin(skin_id: String) -> bool:
	if not SKIN_CATALOG.has(skin_id) or not is_skin_unlocked(skin_id):
		return false
	data["equipped_skin"] = skin_id
	save_game()
	return true

# Challenges Management
func get_completed_challenges() -> Array:
	var val = data.get("completed_challenges", [])
	return val if typeof(val) == TYPE_ARRAY else []

func is_challenge_completed(challenge_id: String) -> bool:
	var comp = get_completed_challenges()
	return comp.has(challenge_id)

func complete_challenge(challenge_id: String, reward: int) -> bool:
	if not _is_valid_id(challenge_id, "") or reward <= 0 or reward > MAX_REWARD:
		return false
	var comp = get_completed_challenges()
	if comp.has(challenge_id):
		return false # Already claimed
	comp.append(challenge_id)
	data["completed_challenges"] = comp
	add_points(reward) # Automatically awards points and saves
	return true

# Mastery Challenges & Milestones (Session 10)
func get_mastery_challenges() -> Array:
	var val = data.get("mastery_challenges", [])
	return val if typeof(val) == TYPE_ARRAY else []

func is_mastery_completed(challenge_id: String) -> bool:
	var comp = get_mastery_challenges()
	return comp.has(challenge_id)

func complete_mastery_challenge(challenge_id: String, reward: int = 50) -> bool:
	if not _is_valid_id(challenge_id, "mastery_") or reward <= 0 or reward > MAX_REWARD:
		return false
	var comp = get_mastery_challenges()
	if comp.has(challenge_id):
		return false
	comp.append(challenge_id)
	data["mastery_challenges"] = comp
	add_points(reward)
	return true

func record_milestone(key: String, amount: int = 1, flush: bool = true) -> void:
	if not VALID_MILESTONES.has(key) or amount <= 0:
		return
	if not data.has("milestones") or typeof(data["milestones"]) != TYPE_DICTIONARY:
		data["milestones"] = get_default_data()["milestones"]
	var cur = _safe_int(data["milestones"].get(key, 0), 0)
	data["milestones"][key] = clampi(cur + amount, 0, MAX_SCORE)
	if flush:
		save_game()
	else:
		_dirty = true

func get_milestone(key: String) -> int:
	if not data.has("milestones") or typeof(data["milestones"]) != TYPE_DICTIONARY:
		return 0
	return _safe_int(data["milestones"].get(key, 0), 0)

# Settings & Accessibility Management
func get_setting(key: String, default_val = null) -> Variant:
	var s = data.get("settings", null)
	if typeof(s) == TYPE_DICTIONARY and s.has(key):
		return s[key]
	var defaults = get_default_data()["settings"]
	if defaults.has(key):
		return defaults[key]
	return default_val

func set_setting(key: String, val) -> void:
	var defaults = get_default_data()["settings"]
	if not defaults.has(key):
		return
	if not data.has("settings") or typeof(data["settings"]) != TYPE_DICTIONARY:
		data["settings"] = defaults.duplicate(true)
	var def_v = defaults[key]
	if typeof(def_v) == TYPE_BOOL:
		data["settings"][key] = bool(val)
	elif typeof(def_v) == TYPE_FLOAT:
		var fv = _safe_float(val, float(def_v))
		data["settings"][key] = clampf(fv, 0.0, 1.0)
	else:
		return
	save_game()

func _backup_corrupted_file(content: String) -> void:
	var f = FileAccess.open(CORRUPT_BACKUP_PATH, FileAccess.WRITE)
	if f:
		f.store_string(content.left(65536))
		f.close()
