class_name SkillManager
extends RefCounted

enum SkillType {
	NONE,
	BONE_BLADE,
	BOOMERANG,
	STONE_SHIELD,
	GROUND_SLAM,
	TIME_SHARD,
	MAGNET_RELIC,
	AIR_DASH,
	BOUNCE_POWER,
	PHOENIX_WINGS,
	SHOCKWAVE_ROAR,
	DOUBLE_GEM,
	FEATHER_FALL
}

enum SkillTier {
	COMMON = 1,
	RARE = 2,
	EPIC = 3,
	LEGENDARY = 4
}

const MAX_SKILL_SLOTS: int = 3

signal skill_equipped(type: SkillType, info: Dictionary)
signal skill_replaced(old_name: String, new_name: String)
signal skill_activated(type: SkillType)
signal skill_updated(cooldown_remaining: float, duration_remaining: float, charges: int)
signal skill_expired(type: SkillType)
signal slots_changed(slots_snapshot: Array)

const SKILL_DATA: Dictionary = {
	SkillType.NONE: {
		"name": "None",
		"short_tag": "",
		"when_hint": "",
		"color": Color(0.6, 0.6, 0.6),
		"icon": "",
		"cooldown": 0.0,
		"duration": 0.0,
		"charges": 0,
		"tier": 0,
		"tier_name": "None",
		"spawn_weight": 0,
		"desc": "No skill equipped"
	},
	SkillType.BONE_BLADE: {
		"name": "Bone Blade",
		"short_tag": "BLADE",
		"when_hint": "Break Walls",
		"color": Color(1.0, 0.42, 0.25),
		"icon": "res://assets/sprites/skill_bone_blade.png",
		"cooldown": 0.5,
		"duration": 0.3,
		"charges": 1,
		"tier": SkillTier.COMMON,
		"tier_name": "Common",
		"spawn_weight": 70,
		"desc": "Forward slash destroys Breakable barriers"
	},
	SkillType.BOOMERANG: {
		"name": "Boomerang",
		"short_tag": "RANG",
		"when_hint": "Hit Air/Ground",
		"color": Color(0.25, 0.85, 1.0),
		"icon": "res://assets/sprites/skill_boomerang.png",
		"cooldown": 1.2,
		"duration": 0.0,
		"charges": 1,
		"tier": SkillTier.RARE,
		"tier_name": "Rare",
		"spawn_weight": 40,
		"desc": "Ranged weapon hits Airborne and Crawler hazards"
	},
	SkillType.STONE_SHIELD: {
		"name": "Stone Shield",
		"short_tag": "SHIELD",
		"when_hint": "Auto Block 1 Hit",
		"color": Color(0.45, 0.95, 1.0),
		"icon": "res://assets/sprites/skill_stone_shield.png",
		"cooldown": 0.0,
		"duration": -1.0, # Infinite until broken
		"charges": 1,
		"tier": SkillTier.LEGENDARY,
		"tier_name": "Legendary",
		"spawn_weight": 8,
		"desc": "Blocks one hit from Airborne, Crawler, or Projectile"
	},
	SkillType.GROUND_SLAM: {
		"name": "Ground Slam",
		"short_tag": "SLAM",
		"when_hint": "Air Dive Smash",
		"color": Color(1.0, 0.65, 0.15),
		"icon": "res://assets/sprites/skill_ground_slam.png",
		"cooldown": 2.0,
		"duration": 0.0,
		"charges": 1,
		"tier": SkillTier.EPIC,
		"tier_name": "Epic",
		"spawn_weight": 20,
		"desc": "Mid-air dive shockwave destroys Breakable and Crawler"
	},
	SkillType.TIME_SHARD: {
		"name": "Time Shard",
		"short_tag": "SLOW",
		"when_hint": "Slow Hazards 4s",
		"color": Color(0.75, 0.45, 1.0),
		"icon": "res://assets/sprites/skill_time_shard.png",
		"cooldown": 1.0,
		"duration": 4.0,
		"charges": 1,
		"tier": SkillTier.LEGENDARY,
		"tier_name": "Legendary",
		"spawn_weight": 8,
		"desc": "Slows moving hazards to 50% speed for 4s"
	},
	SkillType.MAGNET_RELIC: {
		"name": "Magnet Relic",
		"short_tag": "MAGNET",
		"when_hint": "Pull Gems 6s",
		"color": Color(1.0, 0.85, 0.25),
		"icon": "res://assets/sprites/skill_magnet_relic.png",
		"cooldown": 1.0,
		"duration": 6.0,
		"charges": 1,
		"tier": SkillTier.RARE,
		"tier_name": "Rare",
		"spawn_weight": 40,
		"desc": "Attracts nearby amber gems for 6s"
	},
	SkillType.AIR_DASH: {
		"name": "Air Dash",
		"short_tag": "DASH",
		"when_hint": "2x Air Burst",
		"color": Color(0.25, 1.0, 0.72),
		"icon": "res://assets/sprites/skill_air_dash.png",
		"cooldown": 0.6,
		"duration": 0.18,
		"charges": 2,
		"tier": SkillTier.EPIC,
		"tier_name": "Epic",
		"spawn_weight": 20,
		"desc": "Burst dash with 2 charges refilled on landing"
	},
	SkillType.BOUNCE_POWER: {
		"name": "Bounce Power",
		"short_tag": "BOUNCE",
		"when_hint": "High Springs 8s",
		"color": Color(0.45, 1.0, 0.35),
		"icon": "res://assets/sprites/skill_bounce_power.png",
		"cooldown": 1.0,
		"duration": 8.0,
		"charges": 1,
		"tier": SkillTier.COMMON,
		"tier_name": "Common",
		"spawn_weight": 70,
		"desc": "Spring launch +35% and cushioned landings for 8s"
	},
	SkillType.PHOENIX_WINGS: {
		"name": "Phoenix Wings",
		"short_tag": "WINGS",
		"when_hint": "Fly 5s",
		"color": Color(1.0, 0.35, 0.55),
		"icon": "res://assets/sprites/skill_air_dash.png",
		"cooldown": 1.5,
		"duration": 5.0,
		"charges": 1,
		"tier": SkillTier.LEGENDARY,
		"tier_name": "Legendary",
		"spawn_weight": 8,
		"desc": "Soar above hazards with temporary wings for 5s"
	},
	SkillType.SHOCKWAVE_ROAR: {
		"name": "Shockwave Roar",
		"short_tag": "ROAR",
		"when_hint": "Clear Ahead",
		"color": Color(1.0, 0.28, 0.82),
		"icon": "res://assets/sprites/skill_ground_slam.png",
		"cooldown": 2.5,
		"duration": 0.25,
		"charges": 1,
		"tier": SkillTier.EPIC,
		"tier_name": "Epic",
		"spawn_weight": 20,
		"desc": "Sonic roar clears nearby hazards in front of you"
	},
	SkillType.DOUBLE_GEM: {
		"name": "Amber Multiplier",
		"short_tag": "2x GEM",
		"when_hint": "2x Gems 10s",
		"color": Color(1.0, 0.72, 0.12),
		"icon": "res://assets/sprites/skill_magnet_relic.png",
		"cooldown": 1.0,
		"duration": 10.0,
		"charges": 1,
		"tier": SkillTier.RARE,
		"tier_name": "Rare",
		"spawn_weight": 40,
		"desc": "2x Amber Gems & bonus score for 10s"
	},
	SkillType.FEATHER_FALL: {
		"name": "Feather Fall",
		"short_tag": "GLIDE",
		"when_hint": "Slow Fall 8s",
		"color": Color(0.65, 0.92, 1.0),
		"icon": "res://assets/sprites/skill_bounce_power.png",
		"cooldown": 1.0,
		"duration": 8.0,
		"charges": 1,
		"tier": SkillTier.COMMON,
		"tier_name": "Common",
		"spawn_weight": 70,
		"desc": "Low-gravity glide for smoother, longer jumps (8s)"
	}
}

var slots: Array[Dictionary] = []
var active_slot_index: int = 0
var cooldown_scale: float = 1.0
var duration_scale: float = 1.0
var skill_lab_infinite: bool = false

var current_skill: SkillType = SkillType.NONE
var current_charges: int = 0
var max_charges: int = 0
var cooldown_timer: float = 0.0
var duration_timer: float = 0.0
var is_active: bool = false
var has_shield: bool = false
var world_time_scale: float = 1.0
var double_gem_active: bool = false

# Optional weak reference to player
var player_ref: WeakRef

static func get_all_skill_types() -> Array[SkillType]:
	return [
		SkillType.BONE_BLADE,
		SkillType.BOUNCE_POWER,
		SkillType.FEATHER_FALL,
		SkillType.BOOMERANG,
		SkillType.MAGNET_RELIC,
		SkillType.DOUBLE_GEM,
		SkillType.GROUND_SLAM,
		SkillType.AIR_DASH,
		SkillType.SHOCKWAVE_ROAR,
		SkillType.STONE_SHIELD,
		SkillType.TIME_SHARD,
		SkillType.PHOENIX_WINGS
	]

static func get_tier_color(tier: int) -> Color:
	match tier:
		SkillTier.COMMON:
			return Color(0.65, 0.85, 0.65)
		SkillTier.RARE:
			return Color(0.35, 0.72, 1.0)
		SkillTier.EPIC:
			return Color(0.78, 0.42, 1.0)
		SkillTier.LEGENDARY:
			return Color(1.0, 0.76, 0.22)
	return Color(0.8, 0.8, 0.8)

func _make_empty_slot() -> Dictionary:
	return {
		"type": SkillType.NONE,
		"charges": 0,
		"max_charges": 0,
		"cooldown": 0.0,
		"duration": 0.0,
		"is_active": false,
		"has_shield": false
	}

func _init(player: Node2D = null) -> void:
	if player:
		player_ref = weakref(player)
	slots.clear()
	for i in range(MAX_SKILL_SLOTS):
		slots.append(_make_empty_slot())

func _sync_legacy_fields() -> void:
	if active_slot_index < 0 or active_slot_index >= slots.size():
		active_slot_index = 0
	var s: Dictionary = slots[active_slot_index] if not slots.is_empty() else _make_empty_slot()
	current_skill = s["type"]
	current_charges = s["charges"]
	max_charges = s["max_charges"]
	cooldown_timer = s["cooldown"]
	duration_timer = s["duration"]
	is_active = s["is_active"]
	# has_shield is true if ANY equipped slot holds an active Stone Shield
	var any_shield := false
	for sl in slots:
		if sl["type"] == SkillType.STONE_SHIELD and sl["has_shield"]:
			any_shield = true
			break
	has_shield = any_shield

func get_slots_snapshot() -> Array:
	var out: Array = []
	for i in range(slots.size()):
		var sl: Dictionary = slots[i].duplicate()
		sl["slot_index"] = i
		sl["info"] = get_skill_info(sl["type"])
		out.append(sl)
	return out

func get_equipped_count() -> int:
	var count := 0
	for sl in slots:
		if sl["type"] != SkillType.NONE:
			count += 1
	return count

func has_skill(type: SkillType) -> bool:
	for sl in slots:
		if sl["type"] == type:
			return true
	return false

func get_skill_info(type: SkillType = current_skill) -> Dictionary:
	if SKILL_DATA.has(type):
		return SKILL_DATA[type]
	return SKILL_DATA[SkillType.NONE]

func equip_skill(type: SkillType) -> void:
	if type == SkillType.NONE:
		clear_skill()
		return

	var new_info = get_skill_info(type)

	# 1. If already equipped in a slot, refresh/refill that slot
	for i in range(slots.size()):
		if slots[i]["type"] == type:
			slots[i]["max_charges"] = new_info.get("charges", 1)
			slots[i]["charges"] = slots[i]["max_charges"]
			slots[i]["cooldown"] = 0.0
			slots[i]["has_shield"] = (type == SkillType.STONE_SHIELD)
			active_slot_index = i
			_sync_legacy_fields()
			skill_equipped.emit(type, new_info)
			slots_changed.emit(get_slots_snapshot())
			skill_updated.emit(cooldown_timer, duration_timer, current_charges)
			return

	# 2. If there is an empty slot, place it there (preserving existing skills!)
	var target_idx := -1
	for i in range(slots.size()):
		if slots[i]["type"] == SkillType.NONE:
			target_idx = i
			break

	var replaced_old_name := ""
	if target_idx == -1:
		# All 3 slots full: replace oldest non-active, non-shield slot if possible, else slot 0
		target_idx = 0
		for i in range(slots.size()):
			if not slots[i]["is_active"] and slots[i]["type"] != SkillType.STONE_SHIELD:
				target_idx = i
				break
		var old_type: SkillType = slots[target_idx]["type"]
		replaced_old_name = get_skill_info(old_type).get("name", "Previous Skill")
		if slots[target_idx]["is_active"]:
			_end_skill_effect(old_type)

	slots[target_idx] = {
		"type": type,
		"max_charges": new_info.get("charges", 1),
		"charges": new_info.get("charges", 1),
		"cooldown": 0.0,
		"duration": 0.0,
		"is_active": false,
		"has_shield": (type == SkillType.STONE_SHIELD)
	}
	active_slot_index = target_idx
	_sync_legacy_fields()

	if not replaced_old_name.is_empty():
		skill_replaced.emit(replaced_old_name, new_info.get("name", "New Skill"))

	skill_equipped.emit(type, new_info)
	slots_changed.emit(get_slots_snapshot())
	skill_updated.emit(cooldown_timer, duration_timer, current_charges)

func clear_slot(slot_idx: int) -> void:
	if slot_idx < 0 or slot_idx >= slots.size():
		return
	var sl: Dictionary = slots[slot_idx]
	if sl["is_active"]:
		_end_skill_effect(sl["type"])
	slots[slot_idx] = _make_empty_slot()
	# Compact non-empty slots to the left so UI buttons stay neat? Or keep positions?
	# Compacting left keeps 1..3 skills cleanly ordered without gaps.
	var compacted: Array[Dictionary] = []
	for s in slots:
		if s["type"] != SkillType.NONE:
			compacted.append(s)
	while compacted.size() < MAX_SKILL_SLOTS:
		compacted.append(_make_empty_slot())
	slots = compacted
	if active_slot_index >= get_equipped_count():
		active_slot_index = 0
	_sync_legacy_fields()
	slots_changed.emit(get_slots_snapshot())
	skill_updated.emit(cooldown_timer, duration_timer, current_charges)

func clear_skill() -> void:
	for i in range(slots.size()):
		if slots[i]["is_active"]:
			_end_skill_effect(slots[i]["type"])
		slots[i] = _make_empty_slot()
	if world_time_scale != 1.0:
		_set_world_time_scale(1.0)
	active_slot_index = 0
	double_gem_active = false
	var player = player_ref.get_ref() if player_ref else null
	if player and "gravity_scale_modifier" in player:
		player.gravity_scale_modifier = 1.0
	_sync_legacy_fields()
	slots_changed.emit(get_slots_snapshot())
	skill_updated.emit(0.0, 0.0, 0)

func can_activate_slot(slot_idx: int) -> bool:
	if slot_idx < 0 or slot_idx >= slots.size():
		return false
	var sl: Dictionary = slots[slot_idx]
	var stype: SkillType = sl["type"]
	if stype == SkillType.NONE:
		return false
	if sl["cooldown"] > 0.0:
		return false
	if sl["charges"] <= 0:
		return false

	var player = player_ref.get_ref() if player_ref else null
	if player != null:
		if player.state_machine.current_state == PlayerStateMachine.State.DEAD:
			return false
		if player.is_flying:
			return false
		if "trap_skill_jam_timer" in player and player.trap_skill_jam_timer > 0.0 and not skill_lab_infinite:
			return false

	if stype == SkillType.GROUND_SLAM:
		if player != null and player.is_on_floor():
			return false

	if stype == SkillType.STONE_SHIELD:
		return false

	return true

func can_activate() -> bool:
	if can_activate_slot(active_slot_index):
		return true
	for i in range(slots.size()):
		if can_activate_slot(i):
			return true
	return false

func activate_slot(slot_idx: int) -> bool:
	if not can_activate_slot(slot_idx):
		return false
	var sl: Dictionary = slots[slot_idx]
	var stype: SkillType = sl["type"]
	var info = get_skill_info(stype)
	var dur: float = float(info.get("duration", 0.0))
	var cd: float = float(info.get("cooldown", 0.0))

	if skill_lab_infinite:
		sl["charges"] = maxi(sl["max_charges"], 1)
		sl["cooldown"] = minf(cd * cooldown_scale, 0.30)
	else:
		sl["charges"] -= 1
		sl["cooldown"] = cd * cooldown_scale

	if dur > 0.0:
		sl["duration"] = dur * duration_scale
		sl["is_active"] = true
	elif dur < 0.0:
		sl["is_active"] = true

	active_slot_index = slot_idx
	_sync_legacy_fields()
	_apply_skill_effect(stype)
	skill_activated.emit(stype)
	slots_changed.emit(get_slots_snapshot())
	skill_updated.emit(cooldown_timer, duration_timer, current_charges)
	return true

func activate() -> bool:
	if can_activate_slot(active_slot_index):
		return activate_slot(active_slot_index)
	for i in range(slots.size()):
		if can_activate_slot(i):
			return activate_slot(i)
	return false

func update(delta: float) -> void:
	var needs_signal := false
	var expired_indices: Array[int] = []

	for i in range(slots.size()):
		var sl: Dictionary = slots[i]
		var stype: SkillType = sl["type"]
		if stype == SkillType.NONE:
			continue

		if sl["cooldown"] > 0.0:
			sl["cooldown"] = maxf(sl["cooldown"] - delta, 0.0)
			needs_signal = true

		if sl["is_active"] and sl["duration"] > 0.0:
			sl["duration"] = maxf(sl["duration"] - delta, 0.0)
			needs_signal = true
			if sl["duration"] <= 0.0:
				_end_skill_effect(stype)
				sl["is_active"] = false
				skill_expired.emit(stype)
				if skill_lab_infinite:
					sl["charges"] = maxi(sl["max_charges"], 1)
				elif sl["charges"] <= 0 and stype != SkillType.AIR_DASH:
					expired_indices.append(i)
		elif skill_lab_infinite and sl["charges"] <= 0:
			sl["charges"] = maxi(sl["max_charges"], 1)
			needs_signal = true
		elif not sl["is_active"] and sl["cooldown"] <= 0.0 and sl["charges"] <= 0 and stype != SkillType.AIR_DASH:
			expired_indices.append(i)

	if not expired_indices.is_empty():
		# Clear from highest index down or clear_slot (which compacts)
		for idx in range(expired_indices.size() - 1, -1, -1):
			clear_slot(expired_indices[idx])
		return

	_sync_legacy_fields()
	if needs_signal:
		slots_changed.emit(get_slots_snapshot())
		skill_updated.emit(cooldown_timer, duration_timer, current_charges)

func on_player_landed() -> void:
	var changed := false
	for i in range(slots.size()):
		if slots[i]["type"] == SkillType.AIR_DASH:
			if slots[i]["charges"] < slots[i]["max_charges"]:
				slots[i]["charges"] = slots[i]["max_charges"]
				changed = true
	if changed:
		_sync_legacy_fields()
		slots_changed.emit(get_slots_snapshot())
		skill_updated.emit(cooldown_timer, duration_timer, current_charges)

func absorb_shield_hit(hazard: Hazard, allow_solid: bool = false) -> bool:
	var shield_idx := -1
	for i in range(slots.size()):
		if slots[i]["type"] == SkillType.STONE_SHIELD and slots[i]["has_shield"]:
			shield_idx = i
			break
	if shield_idx == -1:
		return false

	var cat = hazard.category if hazard != null else Hazard.Category.SOLID
	var absorbed := (
		cat == Hazard.Category.AIRBORNE
		or cat == Hazard.Category.CRAWLER
		or cat == Hazard.Category.PROJECTILE
		or (allow_solid and (cat == Hazard.Category.SOLID or cat == Hazard.Category.ENVIRONMENTAL))
	)
	if absorbed:
		if skill_lab_infinite:
			slots[shield_idx]["has_shield"] = true
			slots[shield_idx]["charges"] = maxi(slots[shield_idx]["max_charges"], 1)
			slots_changed.emit(get_slots_snapshot())
			return true
		slots[shield_idx]["has_shield"] = false
		clear_slot(shield_idx)
		return true

	return false

func _apply_skill_effect(type: SkillType) -> void:
	var player = player_ref.get_ref() if player_ref else null

	match type:
		SkillType.BONE_BLADE:
			if player and player.has_method("execute_bone_blade"):
				player.execute_bone_blade()
		SkillType.BOOMERANG:
			if player and player.has_method("execute_boomerang"):
				player.execute_boomerang()
		SkillType.GROUND_SLAM:
			if player and player.has_method("execute_ground_slam"):
				player.execute_ground_slam()
		SkillType.AIR_DASH:
			if player and player.has_method("execute_air_dash"):
				player.execute_air_dash()
		SkillType.TIME_SHARD:
			_set_world_time_scale(0.5)
		SkillType.MAGNET_RELIC:
			if player and player.has_method("set_magnet_active"):
				player.set_magnet_active(true)
		SkillType.BOUNCE_POWER:
			if player and player.has_method("set_bounce_multiplier"):
				player.set_bounce_multiplier(1.35)
		SkillType.PHOENIX_WINGS:
			if player and player.has_method("start_flight"):
				player.start_flight(1, 5.0)
		SkillType.SHOCKWAVE_ROAR:
			if player and player.has_method("execute_shockwave_roar"):
				player.execute_shockwave_roar()
		SkillType.DOUBLE_GEM:
			double_gem_active = true
		SkillType.FEATHER_FALL:
			if player and "gravity_scale_modifier" in player:
				player.gravity_scale_modifier = 0.55

func _end_skill_effect(type: SkillType) -> void:
	var player = player_ref.get_ref() if player_ref else null

	match type:
		SkillType.TIME_SHARD:
			_set_world_time_scale(1.0)
		SkillType.MAGNET_RELIC:
			if player and player.has_method("set_magnet_active"):
				player.set_magnet_active(false)
		SkillType.BOUNCE_POWER:
			if player and player.has_method("set_bounce_multiplier"):
				player.set_bounce_multiplier(1.0)
		SkillType.DOUBLE_GEM:
			double_gem_active = false
		SkillType.FEATHER_FALL:
			if player and "gravity_scale_modifier" in player:
				player.gravity_scale_modifier = 1.0
		SkillType.PHOENIX_WINGS:
			if player and player.is_flying and player.has_method("end_flight"):
				player.end_flight()

func _set_world_time_scale(multiplier: float) -> void:
	world_time_scale = multiplier
	var player = player_ref.get_ref() if player_ref else null
	if player and player.is_inside_tree():
		var hazards = player.get_tree().get_nodes_in_group("hazards")
		for h in hazards:
			if h is Hazard and h.has_method("set_time_scale"):
				h.set_time_scale(multiplier)
