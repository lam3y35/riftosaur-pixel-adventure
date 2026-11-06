class_name AudioManager
extends Node

## Centralized audio and haptic feedback manager for Riftosaur.
## Handles sound effects, master volume, SFX toggling, and vibration.

const SaveService = preload("res://scripts/systems/save_service.gd")

var save_service: SaveService
var sound_streams: Dictionary = {}
var player_pool: Array[AudioStreamPlayer] = []
const POOL_SIZE: int = 8

func _init(p_save_service: SaveService = null) -> void:
	save_service = p_save_service
	_load_sounds()

func _ready() -> void:
	for i in range(POOL_SIZE):
		var asp = AudioStreamPlayer.new()
		asp.bus = "Master"
		add_child(asp)
		player_pool.append(asp)

func bind_save_service(p_save_service: SaveService) -> void:
	save_service = p_save_service

func _load_sounds() -> void:
	var sound_files = {
		"jump": "res://assets/audio/sfx_jump.wav",
		"land": "res://assets/audio/sfx_land.wav",
		"slide": "res://assets/audio/sfx_slide.wav",
		"air_dash": "res://assets/audio/sfx_air_dash.wav",
		"collect": "res://assets/audio/sfx_collect.wav",
		"skill_activation": "res://assets/audio/sfx_skill_activation.wav",
		"obstacle_break": "res://assets/audio/sfx_obstacle_break.wav",
		"world_enter": "res://assets/audio/sfx_world_enter.wav",
		"flight_start": "res://assets/audio/sfx_flight_start.wav",
		"flight_end": "res://assets/audio/sfx_flight_end.wav",
		"damage": "res://assets/audio/sfx_damage.wav",
		"game_over": "res://assets/audio/sfx_game_over.wav"
	}

	for sname in sound_files:
		var path = sound_files[sname]
		if ResourceLoader.exists(path):
			sound_streams[sname] = load(path)

func play_sfx(sname: String, pitch_scale: float = 1.0) -> void:
	if save_service:
		var enabled = save_service.get_setting("sound_enabled", true)
		if not enabled:
			return

	if not sound_streams.has(sname):
		return

	var stream = sound_streams[sname]
	var player = _get_available_player()
	if player:
		player.stream = stream
		player.pitch_scale = pitch_scale
		var vol = 1.0
		if save_service:
			vol = float(save_service.get_setting("master_volume", 1.0))
		player.volume_db = linear_to_db(maxf(vol, 0.001))
		player.play()

func trigger_vibration(duration_ms: int = 40) -> void:
	if save_service:
		var vib_enabled = save_service.get_setting("vibration_enabled", true)
		if not vib_enabled:
			return
	Input.vibrate_handheld(duration_ms)

func _get_available_player() -> AudioStreamPlayer:
	for p in player_pool:
		if not p.playing:
			return p
	# Fallback: steal the first player
	if not player_pool.is_empty():
		return player_pool[0]
	return null

# Convenience wrappers
func play_jump() -> void:
	play_sfx("jump")

func play_land() -> void:
	play_sfx("land")
	trigger_vibration(25)

func play_slide() -> void:
	play_sfx("slide")

func play_air_dash() -> void:
	play_sfx("air_dash")
	trigger_vibration(35)

func play_collect() -> void:
	play_sfx("collect")

func play_skill_activation() -> void:
	play_sfx("skill_activation")
	trigger_vibration(50)

func play_obstacle_break() -> void:
	play_sfx("obstacle_break")
	trigger_vibration(40)

func play_world_enter() -> void:
	play_sfx("world_enter")

func play_flight_start() -> void:
	play_sfx("flight_start")
	trigger_vibration(45)

func play_flight_end() -> void:
	play_sfx("flight_end")

func play_damage() -> void:
	play_sfx("damage")
	trigger_vibration(100)

func play_game_over() -> void:
	play_sfx("game_over")
	trigger_vibration(120)
