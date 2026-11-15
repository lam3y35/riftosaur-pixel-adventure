class_name AudioManager
extends Node

## Centralized audio and haptic feedback manager for Riftosaur.
## Handles sound effects, master volume, SFX toggling, and vibration.

const SaveService = preload("res://scripts/systems/save_service.gd")

var save_service: SaveService
var sound_streams: Dictionary = {}
var music_streams: Dictionary = {}
var player_pool: Array[AudioStreamPlayer] = []
var bgm_player: AudioStreamPlayer = null
var current_music_track: String = ""
var _music_ducked: bool = false
var _music_pitch: float = 1.0
var _bgm_fade_tween: Tween = null
const POOL_SIZE: int = 10

func _init(p_save_service: SaveService = null) -> void:
	save_service = p_save_service
	_load_sounds()

func _ready() -> void:
	for i in range(POOL_SIZE):
		var asp = AudioStreamPlayer.new()
		asp.bus = "Master"
		add_child(asp)
		player_pool.append(asp)

	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Master"
	bgm_player.finished.connect(_on_bgm_finished)
	add_child(bgm_player)
	refresh_volumes()

func bind_save_service(p_save_service: SaveService) -> void:
	save_service = p_save_service
	refresh_volumes()

func _load_sounds() -> void:
	var sound_files = {
		"jump": "res://assets/audio/sfx_jump.wav",
		"land": "res://assets/audio/sfx_land.wav",
		"slide": "res://assets/audio/sfx_slide.wav",
		"air_dash": "res://assets/audio/sfx_air_dash.wav",
		"collect": "res://assets/audio/sfx_collect.wav",
		"pickup": "res://assets/audio/sfx_pickup.wav",
		"skill_activation": "res://assets/audio/sfx_skill_activation.wav",
		"obstacle_break": "res://assets/audio/sfx_obstacle_break.wav",
		"world_enter": "res://assets/audio/sfx_world_enter.wav",
		"flight_start": "res://assets/audio/sfx_flight_start.wav",
		"flight_end": "res://assets/audio/sfx_flight_end.wav",
		"damage": "res://assets/audio/sfx_damage.wav",
		"game_over": "res://assets/audio/sfx_game_over.wav",
		"ui_click": "res://assets/audio/sfx_ui_click.wav",
		"bounce": "res://assets/audio/sfx_bounce.wav",
		"combo": "res://assets/audio/sfx_combo.wav",
		"shield_break": "res://assets/audio/sfx_shield_break.wav",
		"boomerang": "res://assets/audio/sfx_boomerang.wav",
		"slam": "res://assets/audio/sfx_slam.wav",
		"new_best": "res://assets/audio/sfx_new_best.wav"
	}

	for sname in sound_files:
		var path = sound_files[sname]
		if ResourceLoader.exists(path):
			sound_streams[sname] = load(path)

	var music_files = {
		"menu": "res://assets/audio/bgm_menu.wav",
		"run": "res://assets/audio/bgm_run.wav"
	}
	for mname in music_files:
		var path = music_files[mname]
		if ResourceLoader.exists(path):
			var stream = load(path)
			if stream is AudioStreamWAV:
				stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
				stream.loop_begin = 0
				stream.loop_end = int(stream.get_length() * stream.mix_rate)
			music_streams[mname] = stream

func _get_effective_sfx_volume() -> float:
	if save_service == null:
		return 1.0
	if not bool(save_service.get_setting("sound_enabled", true)):
		return 0.0
	var master = clampf(float(save_service.get_setting("master_volume", 1.0)), 0.0, 1.0)
	var sfx = clampf(float(save_service.get_setting("volume_sfx", 1.0)), 0.0, 1.0)
	return master * sfx

func _get_effective_music_volume() -> float:
	if save_service == null:
		return 0.75
	if not bool(save_service.get_setting("sound_enabled", true)):
		return 0.0
	var master = clampf(float(save_service.get_setting("master_volume", 1.0)), 0.0, 1.0)
	var mus = clampf(float(save_service.get_setting("volume_music", 0.75)), 0.0, 1.0)
	var duck = 0.45 if _music_ducked else 1.0
	return master * mus * duck

func refresh_volumes() -> void:
	var sfx_vol = _get_effective_sfx_volume()
	var sfx_db = -80.0 if sfx_vol <= 0.001 else linear_to_db(sfx_vol)
	for p in player_pool:
		p.volume_db = sfx_db
	if bgm_player:
		var m_vol = _get_effective_music_volume()
		if m_vol <= 0.001:
			bgm_player.volume_db = -80.0
		else:
			bgm_player.volume_db = linear_to_db(m_vol)
			if not current_music_track.is_empty() and not bgm_player.playing and music_streams.has(current_music_track):
				bgm_player.stream = music_streams[current_music_track]
				bgm_player.play()
		bgm_player.pitch_scale = _music_pitch

func play_music(track: String) -> void:
	if bgm_player == null or not music_streams.has(track):
		return
	if current_music_track == track and bgm_player.playing:
		refresh_volumes()
		return
	current_music_track = track
	bgm_player.stream = music_streams[track]
	bgm_player.pitch_scale = _music_pitch
	var m_vol := _get_effective_music_volume()
	if m_vol <= 0.001:
		bgm_player.volume_db = -80.0
		return
	if _bgm_fade_tween and _bgm_fade_tween.is_valid():
		_bgm_fade_tween.kill()
	bgm_player.volume_db = -28.0
	bgm_player.play()
	if is_inside_tree():
		_bgm_fade_tween = create_tween()
		if _bgm_fade_tween:
			_bgm_fade_tween.tween_property(bgm_player, "volume_db", linear_to_db(m_vol), 0.45)
	else:
		bgm_player.volume_db = linear_to_db(m_vol)

func stop_music() -> void:
	current_music_track = ""
	if _bgm_fade_tween and _bgm_fade_tween.is_valid():
		_bgm_fade_tween.kill()
		_bgm_fade_tween = null
	if bgm_player and bgm_player.playing:
		bgm_player.stop()

func set_music_ducked(ducked: bool) -> void:
	_music_ducked = ducked
	refresh_volumes()

func set_music_pitch(p: float) -> void:
	_music_pitch = clampf(p, 0.85, 1.25)
	if bgm_player:
		bgm_player.pitch_scale = _music_pitch

func _on_bgm_finished() -> void:
	if not current_music_track.is_empty() and bgm_player and _get_effective_music_volume() > 0.001:
		bgm_player.play()

func play_sfx(sname: String, pitch_scale: float = 1.0) -> void:
	var vol = _get_effective_sfx_volume()
	if vol <= 0.001:
		return

	if not sound_streams.has(sname):
		return

	var stream = sound_streams[sname]
	var player = _get_available_player()
	if player:
		player.stream = stream
		player.pitch_scale = clampf(pitch_scale, 0.5, 2.0)
		player.volume_db = linear_to_db(vol)
		player.play()

func trigger_vibration(duration_ms: int = 40) -> void:
	if save_service:
		var vib_enabled = bool(save_service.get_setting("vibration_enabled", true))
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
	play_sfx("jump", randf_range(0.95, 1.07))

func play_land() -> void:
	play_sfx("land", randf_range(0.94, 1.06))
	trigger_vibration(22)

func play_slide() -> void:
	play_sfx("slide", randf_range(0.95, 1.05))

func play_air_dash() -> void:
	play_sfx("air_dash", randf_range(0.97, 1.06))
	trigger_vibration(35)

func play_collect(combo: int = 0) -> void:
	var p = clampf(1.0 + float(mini(combo, 10)) * 0.045, 1.0, 1.48)
	play_sfx("collect", p)

func play_pickup() -> void:
	play_sfx("pickup", randf_range(0.98, 1.04))

func play_skill_activation() -> void:
	play_sfx("skill_activation")
	trigger_vibration(45)

func play_obstacle_break() -> void:
	play_sfx("obstacle_break", randf_range(0.92, 1.08))
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
	trigger_vibration(110)

func play_ui_click() -> void:
	play_sfx("ui_click", randf_range(0.97, 1.05))

func play_bounce() -> void:
	play_sfx("bounce", randf_range(0.95, 1.08))
	trigger_vibration(30)

func play_combo(level: int = 1) -> void:
	play_sfx("combo", clampf(0.95 + float(mini(level, 6)) * 0.07, 0.95, 1.4))

func play_shield_break() -> void:
	play_sfx("shield_break")
	trigger_vibration(65)

func play_boomerang() -> void:
	play_sfx("boomerang")

func play_slam() -> void:
	play_sfx("slam")
	trigger_vibration(80)

func play_new_best() -> void:
	play_sfx("new_best")
