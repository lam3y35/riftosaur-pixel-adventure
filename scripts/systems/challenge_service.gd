class_name ChallengeService
extends RefCounted

signal challenge_unlocked(id: String, title: String, reward: int)
signal level_up(new_level: int, diamond_bonus: int)

var save_service: SaveService

var session_jumps: int = 0
var session_slides: int = 0
var session_gems: int = 0
var session_skills: int = 0
var session_distance: int = 0
var session_score: int = 0
var session_spicy_score: int = 0
var session_combo: int = 0
var session_world: int = 1

const CHALLENGES: Array[Dictionary] = [
	{
		"id": "jump_5",
		"title": "Leap Frog",
		"desc": "Execute 5 jumps across runs",
		"target": 5,
		"reward": 30,
		"xp": 25,
		"tier": "EASY",
		"type": "jumps"
	},
	{
		"id": "dist_50",
		"title": "Warm Up",
		"desc": "Reach 75 score in a single run",
		"target": 75,
		"reward": 50,
		"xp": 25,
		"tier": "EASY",
		"type": "score"
	},
	{
		"id": "slide_3",
		"title": "Low Rider",
		"desc": "Execute 3 slides under obstacles",
		"target": 3,
		"reward": 60,
		"xp": 25,
		"tier": "EASY",
		"type": "slides"
	},
	{
		"id": "dist_100",
		"title": "Century Dash",
		"desc": "Reach 150 score in a single run",
		"target": 150,
		"reward": 100,
		"xp": 40,
		"tier": "EASY",
		"type": "score"
	},
	{
		"id": "score_250",
		"title": "Score Seeker",
		"desc": "Reach 250 score in a single run",
		"target": 250,
		"reward": 120,
		"xp": 50,
		"tier": "MED",
		"type": "score"
	},
	{
		"id": "spicy_100",
		"title": "Spicy Survivor",
		"desc": "Reach 150 score in Spicy Jump mode",
		"target": 150,
		"reward": 150,
		"xp": 60,
		"tier": "MED",
		"type": "spicy_score"
	},
	{
		"id": "dist_250",
		"title": "Endurance Legend",
		"desc": "Reach 400 score in a single run",
		"target": 400,
		"reward": 200,
		"xp": 75,
		"tier": "MED",
		"type": "score"
	},
	{
		"id": "score_600",
		"title": "Apex Champion",
		"desc": "Reach 600 score in a single run",
		"target": 600,
		"reward": 300,
		"xp": 90,
		"tier": "MED",
		"type": "score"
	},
	{
		"id": "gems_run_15",
		"title": "Amber Hunter",
		"desc": "Collect 15 gems in a single run",
		"target": 15,
		"reward": 200,
		"xp": 60,
		"tier": "MED",
		"type": "run_gems"
	},
	{
		"id": "skills_run_4",
		"title": "Arcane Tactician",
		"desc": "Activate 4 skills in a single run",
		"target": 4,
		"reward": 220,
		"xp": 65,
		"tier": "MED",
		"type": "run_skills"
	},
	{
		"id": "world_2",
		"title": "Jungle Explorer",
		"desc": "Reach World 2 (Overgrown Jungle)",
		"target": 2,
		"reward": 250,
		"xp": 80,
		"tier": "MED",
		"type": "world"
	},
	{
		"id": "dist_500m",
		"title": "Marathon Runner",
		"desc": "Run 500m in a single run",
		"target": 500,
		"reward": 350,
		"xp": 100,
		"tier": "HARD",
		"type": "distance"
	},
	{
		"id": "score_1000",
		"title": "Rift Crusher",
		"desc": "Reach 1,000 score in a single run",
		"target": 1000,
		"reward": 400,
		"xp": 110,
		"tier": "HARD",
		"type": "score"
	},
	{
		"id": "combo_12",
		"title": "Flow Master",
		"desc": "Reach a 12x combo streak",
		"target": 12,
		"reward": 350,
		"xp": 100,
		"tier": "HARD",
		"type": "combo"
	},
	{
		"id": "spicy_500",
		"title": "Inferno Hopper",
		"desc": "Reach 500 score in Spicy Jump mode",
		"target": 500,
		"reward": 450,
		"xp": 120,
		"tier": "HARD",
		"type": "spicy_score"
	},
	{
		"id": "world_3",
		"title": "Frostbreaker",
		"desc": "Reach World 3 (Frozen Glacier)",
		"target": 3,
		"reward": 500,
		"xp": 130,
		"tier": "HARD",
		"type": "world"
	},
	{
		"id": "gems_total_150",
		"title": "Diamond Hoarder",
		"desc": "Collect 150 total gems across runs",
		"target": 150,
		"reward": 550,
		"xp": 140,
		"tier": "HARD",
		"type": "total_gems"
	},
	{
		"id": "broken_total_25",
		"title": "Demolition Dino",
		"desc": "Destroy 25 hazards across runs",
		"target": 25,
		"reward": 500,
		"xp": 140,
		"tier": "HARD",
		"type": "total_broken"
	},
	{
		"id": "dist_1000m",
		"title": "Kilometer King",
		"desc": "Run 1,000m in a single run",
		"target": 1000,
		"reward": 750,
		"xp": 180,
		"tier": "EXPERT",
		"type": "distance"
	},
	{
		"id": "score_2500",
		"title": "Dimension Striker",
		"desc": "Reach 2,500 score in a single run",
		"target": 2500,
		"reward": 850,
		"xp": 200,
		"tier": "EXPERT",
		"type": "score"
	},
	{
		"id": "gems_run_40",
		"title": "Treasure Frenzy",
		"desc": "Collect 40 gems in a single run",
		"target": 40,
		"reward": 800,
		"xp": 180,
		"tier": "EXPERT",
		"type": "run_gems"
	},
	{
		"id": "skills_total_50",
		"title": "Grand Sorcerer",
		"desc": "Use 50 skills across runs",
		"target": 50,
		"reward": 900,
		"xp": 200,
		"tier": "EXPERT",
		"type": "total_skills"
	},
	{
		"id": "world_4",
		"title": "Volcanic Conqueror",
		"desc": "Reach World 4 (Volcanic Caldera)",
		"target": 4,
		"reward": 1000,
		"xp": 220,
		"tier": "EXPERT",
		"type": "world"
	},
	{
		"id": "score_5000",
		"title": "Mythic Riftosaur",
		"desc": "Reach 5,000 score in a single run",
		"target": 5000,
		"reward": 1500,
		"xp": 300,
		"tier": "LEGEND",
		"type": "score"
	},
	{
		"id": "dist_2000m",
		"title": "Endless Odyssey",
		"desc": "Run 2,000m in a single run",
		"target": 2000,
		"reward": 1600,
		"xp": 320,
		"tier": "LEGEND",
		"type": "distance"
	},
	{
		"id": "combo_25",
		"title": "Untouchable God",
		"desc": "Reach a 25x combo streak",
		"target": 25,
		"reward": 1800,
		"xp": 350,
		"tier": "LEGEND",
		"type": "combo"
	},
	{
		"id": "score_10000",
		"title": "Prismatic Sovereign",
		"desc": "Reach 10,000 score in a single run",
		"target": 10000,
		"reward": 2500,
		"xp": 500,
		"tier": "LEGEND",
		"type": "score"
	}
]

func _init(p_save_service: SaveService = null) -> void:
	save_service = p_save_service

func reset_session_run_stats() -> void:
	session_gems = 0
	session_skills = 0
	session_distance = 0
	session_score = 0
	session_spicy_score = 0
	session_combo = 0

func record_jump() -> void:
	session_jumps += 1
	_check_stat("jumps", session_jumps)

func record_slide() -> void:
	session_slides += 1
	_check_stat("slides", session_slides)

func record_gem(amount: int = 1) -> void:
	session_gems += amount
	_check_stat("run_gems", session_gems)
	if save_service:
		_check_stat("total_gems", save_service.get_milestone("gems_collected_total"))

func record_skill_used() -> void:
	session_skills += 1
	_check_stat("run_skills", session_skills)
	if save_service:
		_check_stat("total_skills", save_service.get_milestone("skills_used_total"))

func record_hazard_broken() -> void:
	if save_service:
		_check_stat("total_broken", save_service.get_milestone("hazards_broken_total"))

func record_combo(combo: int) -> void:
	if combo > session_combo:
		session_combo = combo
	_check_stat("combo", session_combo)

func record_world(world_num: int) -> void:
	if world_num > session_world:
		session_world = world_num
	_check_stat("world", session_world)

func check_run_progress(distance_m: float, score: int, mode: int) -> void:
	session_distance = maxi(session_distance, int(distance_m))
	session_score = maxi(session_score, score)
	_check_stat("score", score)
	_check_stat("distance", int(distance_m))
	if mode == 0:
		session_spicy_score = maxi(session_spicy_score, score)
		_check_stat("spicy_score", score)

func _check_stat(stat_type: String, value: int) -> void:
	if save_service == null:
		return
	for c in CHALLENGES:
		if c["type"] == stat_type:
			if not save_service.is_challenge_completed(c["id"]):
				if value >= c["target"]:
					if save_service.complete_challenge(c["id"], c["reward"]):
						challenge_unlocked.emit(c["id"], c["title"], c["reward"])
						var xp_gain: int = int(c.get("xp", 50))
						var lv_res: Dictionary = save_service.add_xp(xp_gain, true)
						if lv_res.get("leveled_up", false):
							level_up.emit(int(lv_res["new_level"]), int(lv_res["diamond_bonus"]))

func get_challenge_progress(ch: Dictionary) -> Dictionary:
	var target: int = int(ch.get("target", 1))
	var cid: String = str(ch.get("id", ""))
	if save_service and save_service.is_challenge_completed(cid):
		return {"current": target, "target": target}
	var cur := 0
	match str(ch.get("type", "")):
		"jumps": cur = session_jumps
		"slides": cur = session_slides
		"run_gems": cur = session_gems
		"run_skills": cur = session_skills
		"distance": cur = maxi(session_distance, int(save_service.get_best_distance()) if save_service else 0)
		"score": cur = maxi(session_score, save_service.get_best_score() if save_service else 0)
		"spicy_score": cur = maxi(session_spicy_score, save_service.get_mode_best_score(0) if save_service else 0)
		"combo": cur = maxi(session_combo, save_service.get_milestone("max_combo_best") if save_service else 0)
		"world": cur = maxi(session_world, save_service.get_milestone("max_world_reached") if save_service else 1)
		"total_gems": cur = save_service.get_milestone("gems_collected_total") if save_service else 0
		"total_skills": cur = save_service.get_milestone("skills_used_total") if save_service else 0
		"total_broken": cur = save_service.get_milestone("hazards_broken_total") if save_service else 0
	return {"current": mini(cur, target), "target": target}

func get_all_challenges() -> Array[Dictionary]:
	return CHALLENGES

func is_completed(id: String) -> bool:
	return save_service.is_challenge_completed(id) if save_service else false
