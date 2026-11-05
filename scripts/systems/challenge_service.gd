class_name ChallengeService
extends RefCounted

signal challenge_unlocked(id: String, title: String, reward: int)

var save_service: SaveService

var session_jumps: int = 0
var session_slides: int = 0

const CHALLENGES: Array[Dictionary] = [
	{
		"id": "jump_5",
		"title": "Leap Frog",
		"desc": "Execute 5 jumps across runs",
		"target": 5,
		"reward": 30,
		"type": "jumps"
	},
	{
		"id": "dist_50",
		"title": "Warm Up",
		"desc": "Reach 75 score in a single run",
		"target": 75,
		"reward": 50,
		"type": "score"
	},
	{
		"id": "slide_3",
		"title": "Low Rider",
		"desc": "Execute 3 slides under obstacles",
		"target": 3,
		"reward": 60,
		"type": "slides"
	},
	{
		"id": "dist_100",
		"title": "Century Dash",
		"desc": "Reach 150 score in a single run",
		"target": 150,
		"reward": 100,
		"type": "score"
	},
	{
		"id": "score_250",
		"title": "Score Seeker",
		"desc": "Reach 250 score in a single run",
		"target": 250,
		"reward": 120,
		"type": "score"
	},
	{
		"id": "spicy_100",
		"title": "Spicy Survivor",
		"desc": "Reach 150 score in Spicy Jump mode",
		"target": 150,
		"reward": 150,
		"type": "spicy_score"
	},
	{
		"id": "dist_250",
		"title": "Endurance Legend",
		"desc": "Reach 400 score in a single run",
		"target": 400,
		"reward": 200,
		"type": "score"
	},
	{
		"id": "score_600",
		"title": "Apex Champion",
		"desc": "Reach 600 score in a single run",
		"target": 600,
		"reward": 300,
		"type": "score"
	}
]

func _init(p_save_service: SaveService = null) -> void:
	save_service = p_save_service

func record_jump() -> void:
	session_jumps += 1
	_check_stat("jumps", session_jumps)

func record_slide() -> void:
	session_slides += 1
	_check_stat("slides", session_slides)

func check_run_progress(_distance_m: float, score: int, mode: int) -> void:
	_check_stat("score", score)
	if mode == 0:
		_check_stat("spicy_score", score)

func _check_stat(stat_type: String, value: int) -> void:
	if save_service == null:
		return
	for c in CHALLENGES:
		if c["type"] == stat_type:
			if not save_service.is_challenge_completed(c["id"]):
				if value >= c["target"]:
					save_service.complete_challenge(c["id"], c["reward"])
					challenge_unlocked.emit(c["id"], c["title"], c["reward"])

func get_all_challenges() -> Array[Dictionary]:
	return CHALLENGES

func is_completed(id: String) -> bool:
	return save_service.is_challenge_completed(id) if save_service else false
