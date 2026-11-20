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
const MAX_ENABLED_MAP_SKILLS: int = 4

const SKIN_CATALOG: Dictionary = {
	"classic": 0,
	"emerald": 100,
	"ruby": 250,
	"cyber": 500,
	"gold": 1000,
	"cobalt": 1500,
	"obsidian": 2200,
	"amethyst": 3000,
	"inferno": 4500,
	"plasma": 6000,
	"jade_emperor": 8000,
	"crimson_rex": 10000,
	"celestial": 13500,
	"void_walker": 17500,
	"diamond_apex": 22000,
	"chromatic_god": 30000
}

const SKIN_PERKS: Dictionary = {
	"classic": {"score_mult": 1.0, "gem_mult": 1, "cd_scale": 1.0, "dur_scale": 1.0, "bounce_bonus": 0.0, "start_shield": false, "magnet": false, "start_gems": 0, "perk_text": "Classic"},
	"emerald": {"score_mult": 1.0, "gem_mult": 1, "cd_scale": 1.0, "dur_scale": 1.0, "bounce_bonus": 0.0, "start_shield": false, "magnet": false, "start_gems": 0, "perk_text": "Jungle"},
	"ruby": {"score_mult": 1.0, "gem_mult": 1, "cd_scale": 1.0, "dur_scale": 1.0, "bounce_bonus": 0.0, "start_shield": false, "magnet": false, "start_gems": 0, "perk_text": "Magma"},
	"cyber": {"score_mult": 1.05, "gem_mult": 1, "cd_scale": 1.0, "dur_scale": 1.0, "bounce_bonus": 0.0, "start_shield": false, "magnet": false, "start_gems": 0, "perk_text": "+5% Score"},
	"gold": {"score_mult": 1.10, "gem_mult": 1, "cd_scale": 1.0, "dur_scale": 1.0, "bounce_bonus": 0.0, "start_shield": false, "magnet": false, "start_gems": 1, "perk_text": "+10% Score, +1 Gem"},
	"cobalt": {"score_mult": 1.12, "gem_mult": 1, "cd_scale": 1.0, "dur_scale": 1.0, "bounce_bonus": 0.0, "start_shield": false, "magnet": false, "start_gems": 0, "perk_text": "+12% Score"},
	"obsidian": {"score_mult": 1.15, "gem_mult": 1, "cd_scale": 0.95, "dur_scale": 1.0, "bounce_bonus": 0.0, "start_shield": false, "magnet": false, "start_gems": 0, "perk_text": "+15% Score, -5% CD"},
	"amethyst": {"score_mult": 1.15, "gem_mult": 1, "cd_scale": 1.0, "dur_scale": 1.15, "bounce_bonus": 0.0, "start_shield": false, "magnet": false, "start_gems": 0, "perk_text": "+15% Skill Dur"},
	"inferno": {"score_mult": 1.20, "gem_mult": 1, "cd_scale": 1.0, "dur_scale": 1.0, "bounce_bonus": 0.0, "start_shield": false, "magnet": false, "start_gems": 2, "perk_text": "+20% Score, +2 Gems"},
	"plasma": {"score_mult": 1.20, "gem_mult": 1, "cd_scale": 0.85, "dur_scale": 1.10, "bounce_bonus": 0.0, "start_shield": false, "magnet": false, "start_gems": 0, "perk_text": "-15% CD, +20% Score"},
	"jade_emperor": {"score_mult": 1.22, "gem_mult": 1, "cd_scale": 0.90, "dur_scale": 1.10, "bounce_bonus": 0.0, "start_shield": false, "magnet": true, "start_gems": 0, "perk_text": "Auto-Magnet +22% Score"},
	"crimson_rex": {"score_mult": 1.25, "gem_mult": 1, "cd_scale": 0.90, "dur_scale": 1.15, "bounce_bonus": 0.10, "start_shield": false, "magnet": false, "start_gems": 0, "perk_text": "+25% Score, +10% Bounce"},
	"celestial": {"score_mult": 1.30, "gem_mult": 1, "cd_scale": 0.85, "dur_scale": 1.15, "bounce_bonus": 0.0, "start_shield": true, "magnet": false, "start_gems": 0, "perk_text": "Start Shield +30% Score"},
	"void_walker": {"score_mult": 1.35, "gem_mult": 1, "cd_scale": 0.80, "dur_scale": 1.20, "bounce_bonus": 0.0, "start_shield": true, "magnet": false, "start_gems": 0, "perk_text": "Shield, -20% CD +35% Score"},
	"diamond_apex": {"score_mult": 1.40, "gem_mult": 2, "cd_scale": 0.85, "dur_scale": 1.20, "bounce_bonus": 0.0, "start_shield": false, "magnet": true, "start_gems": 3, "perk_text": "2x Gems, Magnet +40% Score"},
	"chromatic_god": {"score_mult": 1.50, "gem_mult": 2, "cd_scale": 0.75, "dur_scale": 1.25, "bounce_bonus": 0.12, "start_shield": true, "magnet": true, "start_gems": 5, "perk_text": "ALL PERKS: 2x Gems, Shield, Magnet!"}
}

const COSMETIC_CATALOG: Dictionary = {
	# Obstacle Skins
	"obs_default": {"category": "obstacle", "name": "Classic", "price": 0, "tint": Color(1, 1, 1, 1), "perk_text": "Standard", "near_miss_mult": 1.0, "shatter_bonus": 0},
	"obs_neon": {"category": "obstacle", "name": "Neon Pulse", "price": 1200, "tint": Color(0.55, 1.0, 1.0, 1.0), "perk_text": "+15% Close Call", "near_miss_mult": 1.15, "shatter_bonus": 0},
	"obs_golden": {"category": "obstacle", "name": "Gilded", "price": 3500, "tint": Color(1.0, 0.88, 0.35, 1.0), "perk_text": "+3 Shatter 💎", "near_miss_mult": 1.10, "shatter_bonus": 3},
	"obs_ice_crystal": {"category": "obstacle", "name": "Cryo Ice", "price": 5000, "tint": Color(0.65, 0.86, 1.0, 1.0), "perk_text": "+25% Close Call", "near_miss_mult": 1.25, "shatter_bonus": 2},
	"obs_magma_forged": {"category": "obstacle", "name": "Magma", "price": 7500, "tint": Color(1.0, 0.58, 0.38, 1.0), "perk_text": "+5 Shatter 💎", "near_miss_mult": 1.20, "shatter_bonus": 5},
	"obs_shadow_void": {"category": "obstacle", "name": "Void", "price": 12000, "tint": Color(0.76, 0.52, 1.0, 1.0), "perk_text": "+35% Close +8 💎", "near_miss_mult": 1.35, "shatter_bonus": 8},
	# Map / Atmosphere Skins
	"map_default": {"category": "map", "name": "Original", "price": 0, "tint": Color(1, 1, 1, 1), "perk_text": "Standard", "dist_mult": 1.0},
	"map_retro_night": {"category": "map", "name": "Night Sky", "price": 1500, "tint": Color(0.72, 0.78, 1.0, 1.0), "perk_text": "+10% Dist Score", "dist_mult": 1.10},
	"map_blood_moon": {"category": "map", "name": "Blood Moon", "price": 4000, "tint": Color(1.0, 0.72, 0.76, 1.0), "perk_text": "+15% Dist Score", "dist_mult": 1.15},
	"map_aurora_rift": {"category": "map", "name": "Aurora", "price": 8000, "tint": Color(0.68, 1.0, 0.88, 1.0), "perk_text": "+22% Dist Score", "dist_mult": 1.22},
	"map_golden_kingdom": {"category": "map", "name": "Dynasty", "price": 15000, "tint": Color(1.0, 0.92, 0.68, 1.0), "perk_text": "+35% Dist Score", "dist_mult": 1.35},
	# Trail Skins
	"trail_none": {"category": "trail", "name": "No Trail", "price": 0, "color": Color(1, 1, 1, 0), "perk_text": "Standard", "score_mult": 1.0},
	"trail_sparks": {"category": "trail", "name": "Sparks", "price": 800, "color": Color(1.0, 0.82, 0.28, 1.0), "perk_text": "+5% Score", "score_mult": 1.05},
	"trail_frost": {"category": "trail", "name": "Frost", "price": 2000, "color": Color(0.45, 0.92, 1.0, 1.0), "perk_text": "+8% Score", "score_mult": 1.08},
	"trail_fire": {"category": "trail", "name": "Blaze", "price": 4500, "color": Color(1.0, 0.42, 0.18, 1.0), "perk_text": "+12% Score", "score_mult": 1.12},
	"trail_rainbow": {"category": "trail", "name": "Prismatic", "price": 10000, "color": Color(0.95, 0.35, 1.0, 1.0), "perk_text": "+20% Score", "score_mult": 1.20}
}

const VALID_MILESTONES: PackedStringArray = [
	"gems_collected_total",
	"hazards_broken_total",
	"max_world_reached",
	"total_near_misses",
	"max_combo_best",
	"skills_used_total"
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
		"mode_best_scores": {"0": 0, "1": 0, "2": 0},
		"mode_best_distances": {"0": 0.0, "1": 0.0, "2": 0.0},
		"first_launch_completed": false,
		"enabled_map_skills": [1, 2, 3, 5],
		"custom_maps": [],
		"total_runs": 0,
		"points": 50, # Welcome bonus for first time players
		"player_level": 1,
		"player_xp": 0,
		"unlocked_skins": ["classic"],
		"equipped_skin": "classic",
		"unlocked_cosmetics": ["obs_default", "map_default", "trail_none"],
		"equipped_obstacle_skin": "obs_default",
		"equipped_map_skin": "map_default",
		"equipped_trail_skin": "trail_none",
		"completed_challenges": [],
		"mastery_challenges": [],
		"milestones": {
			"gems_collected_total": 0,
			"hazards_broken_total": 0,
			"max_world_reached": 1,
			"total_near_misses": 0,
			"max_combo_best": 0,
			"skills_used_total": 0
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
			"dev_overlay": false,
			"ps_controller_enabled": false,
			"ps_bindings": {
				"jump": "btn:0",
				"duck": "btn:1",
				"move_right": "btn:14",
				"move_left": "btn:13",
				"skill_1": "btn:2",
				"skill_2": "btn:3",
				"skill_3": "btn:10"
			}
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
		if not loaded_data.has("first_launch_completed"):
			loaded_data["first_launch_completed"] = (_safe_int(loaded_data.get("total_runs", 0), 0) > 0)
		if not loaded_data.has("mode_best_scores"):
			loaded_data["mode_best_scores"] = {"0": 0, "1": _safe_int(loaded_data.get("best_score", 0), 0), "2": 0}
		if not loaded_data.has("mode_best_distances"):
			loaded_data["mode_best_distances"] = {"0": 0.0, "1": _safe_float(loaded_data.get("best_distance", 0.0), 0.0), "2": 0.0}
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
	clean["player_level"] = clampi(_safe_int(raw.get("player_level", 1), 1), 1, 100)
	clean["player_xp"] = clampi(_safe_int(raw.get("player_xp", 0), 0), 0, MAX_POINTS)

	if typeof(raw.get("first_launch_completed", null)) == TYPE_BOOL:
		clean["first_launch_completed"] = bool(raw["first_launch_completed"])
	else:
		clean["first_launch_completed"] = (clean["total_runs"] > 0)

	if typeof(raw.get("mode_best_scores", null)) == TYPE_DICTIONARY:
		var mbs: Dictionary = raw["mode_best_scores"]
		for k in ["0", "1", "2"]:
			if mbs.has(k):
				clean["mode_best_scores"][k] = clampi(_safe_int(mbs[k], 0), 0, MAX_SCORE)
	elif clean["best_score"] > 0:
		clean["mode_best_scores"]["1"] = clean["best_score"]

	if typeof(raw.get("mode_best_distances", null)) == TYPE_DICTIONARY:
		var mbd: Dictionary = raw["mode_best_distances"]
		for k in ["0", "1", "2"]:
			if mbd.has(k):
				clean["mode_best_distances"][k] = clampf(_safe_float(mbd[k], 0.0), 0.0, MAX_DISTANCE)
	elif clean["best_distance"] > 0.0:
		clean["mode_best_distances"]["1"] = clean["best_distance"]

	if typeof(raw.get("enabled_map_skills", null)) == TYPE_ARRAY:
		var valid_skills: Array = []
		for sk in raw["enabled_map_skills"]:
			var sk_id = _safe_int(sk, -1)
			if sk_id >= 1 and sk_id <= 12 and not valid_skills.has(sk_id):
				valid_skills.append(sk_id)
				if valid_skills.size() >= MAX_ENABLED_MAP_SKILLS:
					break
		clean["enabled_map_skills"] = valid_skills

	if typeof(raw.get("custom_maps", null)) == TYPE_ARRAY:
		var valid_maps: Array = []
		for cm in raw["custom_maps"]:
			if typeof(cm) == TYPE_DICTIONARY and valid_maps.size() < 20:
				var m_id = str(cm.get("id", ""))
				if m_id.is_empty():
					continue
				var items_clean: Array = []
				if typeof(cm.get("items", null)) == TYPE_ARRAY:
					for it in cm["items"]:
						if typeof(it) == TYPE_DICTIONARY and items_clean.size() < 300:
							items_clean.append({
								"type": str(it.get("type", "cactus")),
								"x": clampf(_safe_float(it.get("x", 300.0), 300.0), 120.0, 10000.0),
								"y": clampf(_safe_float(it.get("y", 216.0), 216.0), 30.0, 240.0),
								"trap_type": clampi(_safe_int(it.get("trap_type", 0), 0), 0, 3)
							})
				valid_maps.append({
					"id": m_id.substr(0, 48),
					"name": str(cm.get("name", "Custom Map")).substr(0, 32),
					"world_index": clampi(_safe_int(cm.get("world_index", 0), 0), 0, 3),
					"speed_preset": clampi(_safe_int(cm.get("speed_preset", 1), 1), 0, 2),
					"immortal": bool(cm.get("immortal", false)),
					"length_px": clampf(_safe_float(cm.get("length_px", 4800.0), 4800.0), 960.0, 10000.0),
					"linked_next_id": str(cm.get("linked_next_id", "")).substr(0, 48),
					"items": items_clean
				})
		clean["custom_maps"] = valid_maps

	var valid_skins: Array = ["classic"]
	if typeof(raw.get("unlocked_skins", null)) == TYPE_ARRAY:
		for s in raw["unlocked_skins"]:
			if typeof(s) == TYPE_STRING and SKIN_CATALOG.has(s) and not valid_skins.has(s):
				valid_skins.append(s)
	clean["unlocked_skins"] = valid_skins

	var eq_raw = raw.get("equipped_skin", "classic")
	var eq = eq_raw if typeof(eq_raw) == TYPE_STRING else "classic"
	clean["equipped_skin"] = eq if valid_skins.has(eq) else "classic"

	var valid_cosmetics: Array = ["obs_default", "map_default", "trail_none"]
	if typeof(raw.get("unlocked_cosmetics", null)) == TYPE_ARRAY:
		for c_id in raw["unlocked_cosmetics"]:
			if typeof(c_id) == TYPE_STRING and COSMETIC_CATALOG.has(c_id) and not valid_cosmetics.has(c_id):
				valid_cosmetics.append(c_id)
	clean["unlocked_cosmetics"] = valid_cosmetics

	var eq_obs = str(raw.get("equipped_obstacle_skin", "obs_default"))
	clean["equipped_obstacle_skin"] = eq_obs if (valid_cosmetics.has(eq_obs) and COSMETIC_CATALOG.get(eq_obs, {}).get("category", "") == "obstacle") else "obs_default"
	var eq_map = str(raw.get("equipped_map_skin", "map_default"))
	clean["equipped_map_skin"] = eq_map if (valid_cosmetics.has(eq_map) and COSMETIC_CATALOG.get(eq_map, {}).get("category", "") == "map") else "map_default"
	var eq_trail = str(raw.get("equipped_trail_skin", "trail_none"))
	clean["equipped_trail_skin"] = eq_trail if (valid_cosmetics.has(eq_trail) and COSMETIC_CATALOG.get(eq_trail, {}).get("category", "") == "trail") else "trail_none"

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
				elif typeof(def_v) == TYPE_DICTIONARY and typeof(st[k]) == TYPE_DICTIONARY:
					var merged_dict: Dictionary = (def_v as Dictionary).duplicate(true)
					for dk in merged_dict.keys():
						if st[k].has(dk) and typeof(st[k][dk]) == TYPE_STRING:
							var s_val: String = str(st[k][dk]).substr(0, 24)
							if s_val.begins_with("btn:") or s_val.begins_with("axis:"):
								merged_dict[dk] = s_val
					clean["settings"][k] = merged_dict

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
	return update_mode_high_score(1, new_score, new_distance, flush)

func update_mode_high_score(mode: int, new_score: int, new_distance: float, flush: bool = true) -> bool:
	if mode == 3:
		return false # Tutorial & Practice never records high scores
	var mode_key := str(clampi(mode, 0, 2))
	var updated = false
	var safe_score = clampi(new_score, 0, MAX_SCORE)
	var safe_dist = clampf(0.0 if (is_nan(new_distance) or is_inf(new_distance)) else new_distance, 0.0, MAX_DISTANCE)

	if not data.has("mode_best_scores") or typeof(data["mode_best_scores"]) != TYPE_DICTIONARY:
		data["mode_best_scores"] = {"0": 0, "1": 0, "2": 0}
	if not data.has("mode_best_distances") or typeof(data["mode_best_distances"]) != TYPE_DICTIONARY:
		data["mode_best_distances"] = {"0": 0.0, "1": 0.0, "2": 0.0}

	if safe_score > get_mode_best_score(mode):
		data["mode_best_scores"][mode_key] = safe_score
		updated = true
	if safe_dist > get_mode_best_distance(mode):
		data["mode_best_distances"][mode_key] = safe_dist

	if safe_score > get_best_score():
		data["best_score"] = safe_score
	if safe_dist > get_best_distance():
		data["best_distance"] = safe_dist

	data["total_runs"] = clampi(get_lifetime_stat("total_runs") + 1, 0, MAX_RUNS)
	if flush:
		save_game()
	else:
		_dirty = true
	return updated

func get_mode_best_score(mode: int) -> int:
	if mode == 3:
		return 0
	var mode_key := str(clampi(mode, 0, 2))
	var mbs = data.get("mode_best_scores", {})
	if typeof(mbs) == TYPE_DICTIONARY and mbs.has(mode_key):
		return clampi(_safe_int(mbs[mode_key], 0), 0, MAX_SCORE)
	if mode == 1:
		return get_best_score()
	return 0

func get_mode_best_distance(mode: int) -> float:
	if mode == 3:
		return 0.0
	var mode_key := str(clampi(mode, 0, 2))
	var mbd = data.get("mode_best_distances", {})
	if typeof(mbd) == TYPE_DICTIONARY and mbd.has(mode_key):
		return clampf(_safe_float(mbd[mode_key], 0.0), 0.0, MAX_DISTANCE)
	if mode == 1:
		return get_best_distance()
	return 0.0

func is_first_launch_completed() -> bool:
	return bool(data.get("first_launch_completed", false))

func set_first_launch_completed(completed: bool = true, flush: bool = true) -> void:
	data["first_launch_completed"] = completed
	if flush:
		save_game()
	else:
		_dirty = true

func get_enabled_map_skills() -> Array[int]:
	var raw = data.get("enabled_map_skills", [1, 2, 3, 5])
	var out: Array[int] = []
	if typeof(raw) == TYPE_ARRAY:
		for sk in raw:
			var sk_id = _safe_int(sk, -1)
			if sk_id >= 1 and sk_id <= 12 and not out.has(sk_id):
				out.append(sk_id)
				if out.size() >= MAX_ENABLED_MAP_SKILLS:
					break
	return out

func set_enabled_map_skills(skills: Array[int], flush: bool = true) -> void:
	var clean_list: Array = []
	for sk in skills:
		if sk >= 1 and sk <= 12 and not clean_list.has(sk):
			clean_list.append(sk)
			if clean_list.size() >= MAX_ENABLED_MAP_SKILLS:
				break
	data["enabled_map_skills"] = clean_list
	if flush:
		save_game()
	else:
		_dirty = true

func get_custom_maps() -> Array:
	var raw = data.get("custom_maps", [])
	return raw if typeof(raw) == TYPE_ARRAY else []

func save_custom_map(map_data: Dictionary, flush: bool = true) -> bool:
	var maps = get_custom_maps().duplicate(true)
	var m_id = str(map_data.get("id", ""))
	if m_id.is_empty():
		return false
	var replaced = false
	for i in range(maps.size()):
		if str(maps[i].get("id", "")) == m_id:
			maps[i] = map_data.duplicate(true)
			replaced = true
			break
	if not replaced:
		if maps.size() >= 20:
			maps.pop_front()
		maps.append(map_data.duplicate(true))
	data["custom_maps"] = maps
	if flush:
		save_game()
	else:
		_dirty = true
	return true

func delete_custom_map(map_id: String, flush: bool = true) -> bool:
	var maps = get_custom_maps()
	var filtered: Array = []
	var found = false
	for m in maps:
		if str(m.get("id", "")) == map_id:
			found = true
		else:
			filtered.append(m)
	if found:
		data["custom_maps"] = filtered
		if flush:
			save_game()
		else:
			_dirty = true
	return found

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

func get_equipped_skin_perks() -> Dictionary:
	var eq := get_equipped_skin()
	return SKIN_PERKS.get(eq, SKIN_PERKS["classic"])

# Cosmetics Management (Obstacle, Map, Trail)
func get_unlocked_cosmetics() -> Array:
	var val = data.get("unlocked_cosmetics", ["obs_default", "map_default", "trail_none"])
	return val if typeof(val) == TYPE_ARRAY else ["obs_default", "map_default", "trail_none"]

func is_cosmetic_unlocked(cosmetic_id: String) -> bool:
	return get_unlocked_cosmetics().has(cosmetic_id)

func get_equipped_cosmetic(category: String) -> String:
	match category:
		"obstacle":
			return str(data.get("equipped_obstacle_skin", "obs_default"))
		"map":
			return str(data.get("equipped_map_skin", "map_default"))
		"trail":
			return str(data.get("equipped_trail_skin", "trail_none"))
	return ""

func get_equipped_cosmetic_data(category: String) -> Dictionary:
	var cid := get_equipped_cosmetic(category)
	return COSMETIC_CATALOG.get(cid, {})

func purchase_cosmetic(cosmetic_id: String) -> bool:
	if not COSMETIC_CATALOG.has(cosmetic_id):
		return false
	if is_cosmetic_unlocked(cosmetic_id):
		return equip_cosmetic(cosmetic_id)
	var price: int = int(COSMETIC_CATALOG[cosmetic_id].get("price", -1))
	if price < 0:
		return false
	var current: int = _safe_int(data.get("points", 0), 0)
	if current < price:
		return false
	data["points"] = current - price
	var unlocked := get_unlocked_cosmetics()
	unlocked.append(cosmetic_id)
	data["unlocked_cosmetics"] = unlocked
	return equip_cosmetic(cosmetic_id)

func equip_cosmetic(cosmetic_id: String) -> bool:
	if not COSMETIC_CATALOG.has(cosmetic_id) or not is_cosmetic_unlocked(cosmetic_id):
		return false
	var cat: String = str(COSMETIC_CATALOG[cosmetic_id].get("category", ""))
	match cat:
		"obstacle":
			data["equipped_obstacle_skin"] = cosmetic_id
		"map":
			data["equipped_map_skin"] = cosmetic_id
		"trail":
			data["equipped_trail_skin"] = cosmetic_id
		_:
			return false
	save_game()
	return true

# Player Level & XP Management
func get_player_level() -> int:
	return clampi(_safe_int(data.get("player_level", 1), 1), 1, 100)

func get_player_xp() -> int:
	return clampi(_safe_int(data.get("player_xp", 0), 0), 0, MAX_POINTS)

func get_xp_for_next_level(level: int = -1) -> int:
	var lv := level if level > 0 else get_player_level()
	return 100 + (lv - 1) * 75

func add_xp(amount: int, flush: bool = true) -> Dictionary:
	if amount <= 0:
		return {"leveled_up": false, "new_level": get_player_level(), "levels_gained": 0, "diamond_bonus": 0}
	var lv := get_player_level()
	var xp := get_player_xp() + amount
	var levels_gained := 0
	var total_bonus := 0
	while lv < 100:
		var needed := get_xp_for_next_level(lv)
		if xp >= needed:
			xp -= needed
			lv += 1
			levels_gained += 1
			total_bonus += mini(lv * 100, MAX_REWARD)
		else:
			break
	data["player_level"] = lv
	data["player_xp"] = xp
	if total_bonus > 0:
		add_points(total_bonus, false)
	if flush:
		save_game()
	else:
		_dirty = true
	return {
		"leveled_up": levels_gained > 0,
		"new_level": lv,
		"levels_gained": levels_gained,
		"diamond_bonus": total_bonus
	}

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
	elif typeof(def_v) == TYPE_DICTIONARY and typeof(val) == TYPE_DICTIONARY:
		data["settings"][key] = val.duplicate(true)
	else:
		return
	save_game()

func get_ps_binding(action: String) -> String:
	var bindings = get_setting("ps_bindings", {})
	if typeof(bindings) == TYPE_DICTIONARY and bindings.has(action):
		return str(bindings[action])
	var def_bindings: Dictionary = get_default_data()["settings"]["ps_bindings"]
	return str(def_bindings.get(action, ""))

func set_ps_binding(action: String, code: String) -> void:
	var def_bindings: Dictionary = get_default_data()["settings"]["ps_bindings"]
	if not def_bindings.has(action):
		return
	var bindings = get_setting("ps_bindings", def_bindings)
	var updated: Dictionary = bindings.duplicate(true) if typeof(bindings) == TYPE_DICTIONARY else def_bindings.duplicate(true)
	updated[action] = code.substr(0, 24)
	set_setting("ps_bindings", updated)

func _backup_corrupted_file(content: String) -> void:
	var f = FileAccess.open(CORRUPT_BACKUP_PATH, FileAccess.WRITE)
	if f:
		f.store_string(content.left(65536))
		f.close()
