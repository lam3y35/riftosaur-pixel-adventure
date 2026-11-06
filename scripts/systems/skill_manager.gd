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
	BOUNCE_POWER
}

signal skill_equipped(type: SkillType, info: Dictionary)
signal skill_replaced(old_name: String, new_name: String)
signal skill_activated(type: SkillType)
signal skill_updated(cooldown_remaining: float, duration_remaining: float, charges: int)
signal skill_expired(type: SkillType)

const SKILL_DATA: Dictionary = {
	SkillType.NONE: {
		"name": "None",
		"icon": "",
		"cooldown": 0.0,
		"duration": 0.0,
		"charges": 0,
		"desc": "No skill equipped"
	},
	SkillType.BONE_BLADE: {
		"name": "Bone Blade",
		"icon": "res://assets/sprites/skill_bone_blade.png",
		"cooldown": 0.5,
		"duration": 0.3,
		"charges": 1,
		"desc": "Forward slash destroys Breakable barriers"
	},
	SkillType.BOOMERANG: {
		"name": "Boomerang",
		"icon": "res://assets/sprites/skill_boomerang.png",
		"cooldown": 1.2,
		"duration": 0.0,
		"charges": 1,
		"desc": "Ranged weapon hits Airborne and Crawler hazards"
	},
	SkillType.STONE_SHIELD: {
		"name": "Stone Shield",
		"icon": "res://assets/sprites/skill_stone_shield.png",
		"cooldown": 0.0,
		"duration": -1.0, # Infinite until broken
		"charges": 1,
		"desc": "Blocks one hit from Airborne, Crawler, or Projectile"
	},
	SkillType.GROUND_SLAM: {
		"name": "Ground Slam",
		"icon": "res://assets/sprites/skill_ground_slam.png",
		"cooldown": 2.0,
		"duration": 0.0,
		"charges": 1,
		"desc": "Mid-air dive shockwave destroys Breakable and Crawler"
	},
	SkillType.TIME_SHARD: {
		"name": "Time Shard",
		"icon": "res://assets/sprites/skill_time_shard.png",
		"cooldown": 1.0,
		"duration": 4.0,
		"charges": 1,
		"desc": "Slows moving hazards to 50% speed for 4s"
	},
	SkillType.MAGNET_RELIC: {
		"name": "Magnet Relic",
		"icon": "res://assets/sprites/skill_magnet_relic.png",
		"cooldown": 1.0,
		"duration": 6.0,
		"charges": 1,
		"desc": "Attracts nearby amber gems for 6s"
	},
	SkillType.AIR_DASH: {
		"name": "Air Dash",
		"icon": "res://assets/sprites/skill_air_dash.png",
		"cooldown": 0.6,
		"duration": 0.18,
		"charges": 2,
		"desc": "Burst dash with 2 charges refilled on landing"
	},
	SkillType.BOUNCE_POWER: {
		"name": "Bounce Power",
		"icon": "res://assets/sprites/skill_bounce_power.png",
		"cooldown": 1.0,
		"duration": 8.0,
		"charges": 1,
		"desc": "Spring launch +35% and cushioned landings for 8s"
	}
}

var current_skill: SkillType = SkillType.NONE
var current_charges: int = 0
var max_charges: int = 0
var cooldown_timer: float = 0.0
var duration_timer: float = 0.0
var is_active: bool = false
var has_shield: bool = false

# Optional weak reference to player
var player_ref: WeakRef

func _init(player: Node2D = null) -> void:
	if player:
		player_ref = weakref(player)

func get_skill_info(type: SkillType = current_skill) -> Dictionary:
	if SKILL_DATA.has(type):
		return SKILL_DATA[type]
	return SKILL_DATA[SkillType.NONE]

func equip_skill(type: SkillType) -> void:
	if type == SkillType.NONE:
		clear_skill()
		return

	var old_skill = current_skill
	var old_info = get_skill_info(old_skill)
	var new_info = get_skill_info(type)

	# Clean up any active duration of previous skill
	if is_active:
		_end_skill_effect(current_skill)

	current_skill = type
	max_charges = new_info.get("charges", 1)
	current_charges = max_charges
	cooldown_timer = 0.0
	duration_timer = 0.0
	is_active = false
	has_shield = (type == SkillType.STONE_SHIELD)

	if old_skill != SkillType.NONE and old_skill != type:
		skill_replaced.emit(old_info.get("name", "Previous Skill"), new_info.get("name", "New Skill"))

	skill_equipped.emit(current_skill, new_info)
	skill_updated.emit(cooldown_timer, duration_timer, current_charges)

func clear_skill() -> void:
	if is_active:
		_end_skill_effect(current_skill)
	current_skill = SkillType.NONE
	current_charges = 0
	max_charges = 0
	cooldown_timer = 0.0
	duration_timer = 0.0
	is_active = false
	has_shield = false
	skill_updated.emit(0.0, 0.0, 0)

func can_activate() -> bool:
	if current_skill == SkillType.NONE:
		return false
	if cooldown_timer > 0.0:
		return false
	if current_charges <= 0:
		return false

	var player = player_ref.get_ref() if player_ref else null

	# Skill specific preconditions
	if current_skill == SkillType.GROUND_SLAM:
		if player != null and player.is_on_floor():
			# Ground slam can only be triggered while in mid-air
			return false

	if current_skill == SkillType.STONE_SHIELD:
		# Shield is passive once equipped, but activation can refresh or burst
		return true

	return true

func activate() -> bool:
	if not can_activate():
		return false

	var info = get_skill_info(current_skill)
	var dur = info.get("duration", 0.0)
	var cd = info.get("cooldown", 0.0)

	current_charges -= 1
	cooldown_timer = cd

	if dur > 0.0:
		duration_timer = dur
		is_active = true
	elif dur < 0.0:
		# Permanent / passive until broken
		is_active = true

	_apply_skill_effect(current_skill)
	skill_activated.emit(current_skill)
	skill_updated.emit(cooldown_timer, duration_timer, current_charges)
	return true

func update(delta: float) -> void:
	var needs_signal = false

	if cooldown_timer > 0.0:
		cooldown_timer = maxf(cooldown_timer - delta, 0.0)
		needs_signal = true

	if is_active and duration_timer > 0.0:
		duration_timer = maxf(duration_timer - delta, 0.0)
		needs_signal = true
		if duration_timer <= 0.0:
			_end_skill_effect(current_skill)
			is_active = false
			skill_expired.emit(current_skill)
			if current_charges <= 0:
				# Single use duration skills clear after expiry
				if current_skill != SkillType.AIR_DASH:
					clear_skill()

	if needs_signal:
		skill_updated.emit(cooldown_timer, duration_timer, current_charges)

func on_player_landed() -> void:
	if current_skill == SkillType.AIR_DASH:
		# Refill air dash charges upon touching the ground
		if current_charges < max_charges:
			current_charges = max_charges
			skill_updated.emit(cooldown_timer, duration_timer, current_charges)

func absorb_shield_hit(hazard: Hazard) -> bool:
	if not has_shield or current_skill != SkillType.STONE_SHIELD:
		return false

	# Blocks one hit from Airborne, Crawler, or Projectile
	# Never blocks Solid or Environmental
	var cat = hazard.category if hazard != null else Hazard.Category.SOLID
	if cat == Hazard.Category.AIRBORNE or cat == Hazard.Category.CRAWLER or cat == Hazard.Category.PROJECTILE:
		# Absorbed! Shield breaks
		has_shield = false
		clear_skill()
		return true
	
	# Solid or Environmental cannot be blocked
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

func _set_world_time_scale(multiplier: float) -> void:
	var player = player_ref.get_ref() if player_ref else null
	if player and player.is_inside_tree():
		var hazards = player.get_tree().get_nodes_in_group("hazards")
		for h in hazards:
			if h is Hazard and h.has_method("set_time_scale"):
				h.set_time_scale(multiplier)
