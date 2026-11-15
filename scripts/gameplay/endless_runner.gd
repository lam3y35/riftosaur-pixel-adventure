class_name EndlessRunner
extends Node2D

const ChallengeService = preload("res://scripts/systems/challenge_service.gd")
const LevelGenerator = preload("res://scripts/world/level_generator.gd")
const LevelPattern = preload("res://scripts/world/level_pattern.gd")
const AudioManager = preload("res://scripts/systems/audio_manager.gd")
const FXManagerScript = preload("res://scripts/effects/fx_manager.gd")
const GemScene = preload("res://scenes/objects/collectible_gem.tscn")
const SkillPickupScene = preload("res://scenes/objects/skill_pickup.tscn")
const TrapPickupScene = preload("res://scenes/objects/trap_pickup.tscn")

@onready var player: Player = $Player
@onready var camera: GameCamera = $GameCamera
@onready var hud: GameHUD = $GameHUD
@onready var chunk_container: Node2D = $ChunkContainer
@onready var parallax_bg = get_node_or_null("ParallaxBackground")

var fx_container: Node2D = null
var fx_manager: FXManagerScript = null

var save_service: SaveService
var challenge_service: ChallengeService
var audio_manager: AudioManager = AudioManager.new()
var is_game_over: bool = false
var is_paused: bool = false
var is_game_started: bool = false
var current_mode: int = 1 # 0 = Spicy Jump, 1 = Runner, 2 = Freestyle, 3 = Practice

# Session 7 World Themes & Transitions
var world_themes: Array[WorldTheme] = []
var theme_tile_textures: Dictionary = {}
var current_world_index: int = 0
var next_transition_distance_m: float = 250.0

var start_x: float = 100.0
var distance_px: float = 0.0
var distance_m: float = 0.0
var current_score: int = 0
var bonus_score: int = 0
var next_chunk_x: float = 0.0

# Action Hook: Combo / Fever / Near-Miss / Run Stats
var combo_count: int = 0
var combo_timer: float = 0.0
var combo_max_this_run: int = 0
var combo_multiplier: int = 1
var near_misses_this_run: int = 0
var hazards_broken_this_run: int = 0
var is_fever_active: bool = false
var _hitstop_timer: float = 0.0
var _dash_trail_timer: float = 0.0
var _slide_spark_timer: float = 0.0
var _cosmetic_trail_timer: float = 0.0
var _cached_score_mult: float = 1.0
var _cached_gem_mult: int = 1
var _cached_near_miss_mult: float = 1.0
var _cached_shatter_bonus: int = 0
var _cached_obs_tint: Color = Color.WHITE
var _cached_trail_color: Color = Color(1, 1, 1, 0)
var _procedural_chunks_spawned: int = 0
var _skill_bag: Array[int] = []
var _next_skill_spawn_m: float = 40.0

var chunk_scenes: Array[PackedScene] = []
var chunk_pool: Array[Node2D] = []
const CHUNK_WIDTH: float = 480.0

# Session 8 Level Generator & Deterministic Seeding
var level_generator: LevelGenerator = LevelGenerator.new()
var run_seed: int = 0

# Live Tutorial, Practice Sections, Adaptive Hints & Custom Maps
var tutorial_active: bool = false
var tutorial_phase: int = 0
var _tut_jump_hold_accum: float = 0.0
var _tut_short_jump_done: bool = false
var _tut_long_jump_done: bool = false
var _tut_slide_done: bool = false
var _tut_bounce_done: bool = false
var _tut_crawler_done: bool = false
var _tut_hazard_done: bool = false
var _tut_skill_done: bool = false
var _tut_real_jump_triggered: bool = false
var _tut_hit_current_obstacle: bool = false
var _tut_target_node: Node2D = null
var _tut_extra_node: Node2D = null
var _tut_phase_timer: float = 0.0
var _tut_celebrate_timer: float = 0.0
var _practice_entry_pending: bool = false
var practice_section_index: int = -1
var _practice_section_counter: int = 0
var _practice_pattern_hits: Dictionary = {}
var skill_lab_active: bool = false
var skill_lab_skill_id: int = 1
var _skill_lab_next_wave_x: float = 360.0
var custom_map_active: bool = false
var custom_map_data: Dictionary = {}
var custom_map_chain: Array = []

func _ready() -> void:
	save_service = SaveService.new()
	challenge_service = ChallengeService.new(save_service)
	add_child(audio_manager)
	audio_manager.bind_save_service(save_service)

	fx_container = Node2D.new()
	fx_container.name = "FXContainer"
	fx_container.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(fx_container)

	fx_manager = FXManagerScript.new()
	fx_manager.name = "FXManager"
	fx_manager.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(fx_manager)

	player.fx_container = fx_container

	hud.bind_services(save_service, challenge_service)
	if challenge_service:
		if not challenge_service.challenge_unlocked.is_connected(_on_quest_trick):
			challenge_service.challenge_unlocked.connect(_on_quest_trick)
		if not challenge_service.level_up.is_connected(_on_level_up_trick):
			challenge_service.level_up.connect(_on_level_up_trick)

	# Load chunk scenes
	chunk_scenes = [
		preload("res://scenes/obstacles/chunks/chunk_01_empty.tscn"),                # 0: Safe breather
		preload("res://scenes/obstacles/chunks/chunk_02_single_low.tscn"),            # 1: Single cactus hop
		preload("res://scenes/obstacles/chunks/chunk_03_overhang.tscn"),              # 2: Stone arch slide
		preload("res://scenes/obstacles/chunks/chunk_04_double_low.tscn"),            # 3: Double low rhythm
		preload("res://scenes/obstacles/chunks/chunk_05_jump_and_slide.tscn"),        # 4: Hop + slide combo
		preload("res://scenes/obstacles/chunks/chunk_06_crate_step.tscn"),            # 5: Stepping crate + cactus
		preload("res://scenes/obstacles/chunks/chunk_07_triple_low.tscn"),            # 6: Triple rhythm hurdles
		preload("res://scenes/obstacles/chunks/chunk_08_double_crate.tscn"),          # 7: Double crate stairway
		preload("res://scenes/obstacles/chunks/chunk_09_mushroom_bounce.tscn"),      # 8: Mushroom bounce to high ledge
		preload("res://scenes/obstacles/chunks/chunk_10_multi_tier_platforms.tscn"), # 9: Multi-tier one-way platforms
		preload("res://scenes/obstacles/chunks/chunk_11_bounce_chain.tscn"),          # 10: Spring stump to launch pad chain
		preload("res://scenes/obstacles/chunks/chunk_12_wind_vent_ascent.tscn"),       # 11: Wind vent high terrace bypass
		preload("res://scenes/obstacles/chunks/chunk_13_airborne_pterodactyl.tscn"),   # 12: Airborne pterodactyl & gems
		preload("res://scenes/obstacles/chunks/chunk_14_crawler_and_barrier.tscn"),     # 13: Crawler & breakable barrier + skill
		preload("res://scenes/obstacles/chunks/chunk_15_skill_gem_cache.tscn"),         # 14: Skill & gem platform cache
		preload("res://scenes/obstacles/chunks/chunk_16_flight_wings_route.tscn"),      # 15: Mechanical wings flight route
		preload("res://scenes/obstacles/chunks/chunk_17_flight_rocket_route.tscn")      # 16: Rocket relic flight route
	]

	# Connect HUD signals
	hud.start_requested.connect(begin_run)
	hud.mode_selected.connect(_on_mode_selected)
	hud.jump_requested.connect(_on_hud_jump)
	hud.slide_requested.connect(_on_hud_slide)
	hud.steer_requested.connect(_on_hud_steer)
	hud.pause_requested.connect(toggle_pause)
	hud.resume_requested.connect(resume_game)
	hud.retry_requested.connect(restart_run)
	hud.menu_requested.connect(go_to_title_menu)
	hud.skin_selected.connect(_on_skin_selected)
	if hud.has_signal("cosmetic_selected"):
		hud.cosmetic_selected.connect(_on_cosmetic_selected)
	hud.skill_requested.connect(_on_hud_skill)
	if hud.has_signal("skill_slot_requested"):
		hud.skill_slot_requested.connect(_on_hud_skill_slot)
	hud.flight_up_requested.connect(func(p): player.flight_up_input = p)
	hud.flight_down_requested.connect(func(p): player.flight_down_input = p)
	if hud.has_signal("settings_changed"):
		hud.settings_changed.connect(_sync_settings)
	if hud.has_signal("ui_interacted"):
		hud.ui_interacted.connect(func(): audio_manager.play_ui_click())
	if hud.has_signal("live_tutorial_requested"):
		hud.live_tutorial_requested.connect(_on_hud_live_tutorial_requested)

	# Connect Player signals
	player.died.connect(_on_player_died)
	player.jumped.connect(_on_player_jumped)
	player.landed.connect(_on_player_landed)
	player.slided.connect(_on_player_slided)
	player.dived.connect(_on_player_dived)
	player.air_dashed.connect(_on_player_air_dashed)
	player.ground_slammed.connect(_on_player_ground_slammed)
	player.gem_collected.connect(_on_player_gem_collected)
	player.skill_used.connect(_on_player_skill_used)
	player.shield_broken.connect(_on_player_shield_broken)
	player.practice_hit_absorbed.connect(_on_practice_hit_absorbed)
	player.hearts_changed.connect(_on_player_hearts_changed)
	player.heart_shield_lost.connect(_on_player_heart_shield_lost)
	player.trap_debuff_started.connect(_on_player_trap_debuff_started)
	player.hazard_broken.connect(_on_player_hazard_broken)
	player.flight_started.connect(_on_player_flight_started)
	player.flight_time_updated.connect(func(r, tot): hud.update_flight_timer(r, tot))
	player.flight_ended.connect(_on_player_flight_ended)

	if player.skill_manager:
		player.skill_manager.skill_equipped.connect(_on_skill_equipped)
		player.skill_manager.skill_replaced.connect(_on_skill_replaced)
		player.skill_manager.skill_updated.connect(_on_skill_updated)
		player.skill_manager.slots_changed.connect(_on_skill_slots_changed)

	# Apply initial skin, perks & settings
	player.set_skin(save_service.get_equipped_skin())
	_apply_equipped_perks_and_cosmetics(false)
	_sync_settings()

	# Load world themes and cache ground tile textures
	world_themes = [
		load("res://resources/themes/theme_01_plains.tres"),
		load("res://resources/themes/theme_02_jungle.tres"),
		load("res://resources/themes/theme_03_frozen.tres"),
		load("res://resources/themes/theme_04_volcanic.tres")
	]
	for t in world_themes:
		if t and not t.ground_tile_path.is_empty() and ResourceLoader.exists(t.ground_tile_path):
			theme_tile_textures[t.world_id] = load(t.ground_tile_path)

	if hud.practice_hub:
		hud.practice_hub.start_live_tutorial_requested.connect(_on_start_live_tutorial)
		hud.practice_hub.skip_to_practice_requested.connect(_on_skip_to_practice)
		hud.practice_hub.exit_to_menu_requested.connect(go_to_title_menu)
		hud.practice_hub.test_skill_requested.connect(_on_test_skill_requested)
		hud.practice_hub.map_skills_updated.connect(func(_s): _refill_skill_bag())
		hud.practice_hub.section_practice_requested.connect(_on_section_practice_requested)
		hud.practice_hub.random_practice_requested.connect(_on_random_practice_requested)
		hud.practice_hub.play_custom_map_requested.connect(start_custom_map)
		hud.practice_hub.modal_opened.connect(_on_practice_modal_opened)
		hud.practice_hub.modal_closed.connect(_on_practice_modal_closed)

	init_title_screen()
	if should_auto_launch_tutorial() and DisplayServer.get_name() != "headless":
		enter_first_launch_tutorial_practice()

func should_auto_launch_tutorial() -> bool:
	return save_service != null and not save_service.is_first_launch_completed()

func enter_first_launch_tutorial_practice() -> void:
	hud.select_mode(3)
	current_mode = 3
	begin_run()
	if hud.practice_hub:
		_practice_entry_pending = true
		get_tree().paused = true
		hud.practice_hub.show_entry_choice()

func _sync_settings() -> void:
	if save_service == null:
		return
	var reduce_m: bool = bool(save_service.get_setting("reduce_motion", false))
	var high_c: bool = bool(save_service.get_setting("high_contrast", false))
	var auto_h: bool = bool(save_service.get_setting("auto_hold_jump", false))
	if camera:
		camera.reduce_motion = reduce_m
	if fx_manager:
		fx_manager.reduce_motion = reduce_m
		fx_manager.high_contrast = high_c
	if player:
		player.auto_hold_jump = auto_h
	if audio_manager:
		audio_manager.refresh_volumes()
	if hud and hud.has_method("refresh_accessibility_visuals"):
		hud.refresh_accessibility_visuals()

func _on_mode_selected(mode: int) -> void:
	current_mode = mode

func _apply_mode_settings() -> void:
	var is_practice_mode := (current_mode == 3)
	if player.skill_manager:
		player.skill_manager.skill_lab_infinite = skill_lab_active
	if custom_map_active:
		player.practice_immortal = bool(custom_map_data.get("immortal", false))
		player.practice_shield_enabled = false
	else:
		player.practice_shield_enabled = is_practice_mode
		player.practice_immortal = is_practice_mode
	match current_mode:
		0: # Easy Mode: gentle opening speed, 2 hearts (1 built-in shield hit before dying)
			player.is_steer_enabled = true
			player.set_hearts(2)
			player.current_speed = 196.0
			player.config.coyote_time = 0.10
			player.config.jump_buffer_time = 0.14
			if player.skill_manager:
				player.skill_manager.clear_skill()
		1: # Medium (Runner) Mode: balanced speed & obstacle mix, 1 heart
			player.is_steer_enabled = true
			player.set_hearts(1)
			player.current_speed = 216.0
			player.config.coyote_time = 0.08
			player.config.jump_buffer_time = 0.12
			if player.skill_manager:
				player.skill_manager.clear_skill()
		2: # Hard Mode: intense obstacles & movement, 3 hearts (survive 2 hits, die on 3rd)
			player.is_steer_enabled = true
			player.set_hearts(3)
			player.current_speed = 232.0
			player.config.coyote_time = 0.08
			player.config.jump_buffer_time = 0.12
			if player.skill_manager:
				player.skill_manager.clear_skill()
		3: # Tutorial & Practice mode: 196 px/s opening, 1.5x coyote/buffer, immortal continuous shield
			player.is_steer_enabled = true
			player.set_hearts(1)
			player.current_speed = 196.0
			player.config.coyote_time = 0.12
			player.config.jump_buffer_time = 0.20
			if player.skill_manager and not skill_lab_active:
				player.skill_manager.equip_skill(SkillManager.SkillType.STONE_SHIELD)
	if fx_manager:
		fx_manager.active_immortal_shield = player.practice_immortal
	if hud and hud.has_method("update_hearts"):
		hud.update_hearts(player.current_hearts, player.max_hearts, player.practice_immortal)

func _apply_biome_modifier() -> void:
	if player == null:
		return
	var modifier = "NONE"
	if current_world_index < world_themes.size() and world_themes[current_world_index] != null:
		modifier = world_themes[current_world_index].gameplay_modifier
	# Slippery icy slide momentum surge in Frozen Ruins
	player.icy_slide_boost = 75.0 if modifier == "SLIPPERY_SURFACES" else 0.0

func init_title_screen() -> void:
	is_game_started = false
	is_game_over = false
	is_paused = false
	get_tree().paused = false
	_hitstop_timer = 0.0

	# Disable physics movement cleanly while keeping subtle IDLE breathing via _process()
	player.set_physics_process(false)
	chunk_container.process_mode = Node.PROCESS_MODE_DISABLED

	_reset_world_state()

	player.reset()
	player.state_machine.change_state(PlayerStateMachine.State.IDLE)
	player.set_skin(save_service.get_equipped_skin())

	if hud.practice_hub:
		hud.practice_hub.hide_all()
	if hud.has_method("hide_skill_toast"):
		hud.hide_skill_toast()
	if hud.has_method("clear_trap_hud"):
		hud.clear_trap_hud()
	hud.show_start_menu(save_service.get_best_score(), save_service.get_points())
	hud.update_hud(0, 0.0, save_service.get_best_score(), save_service.get_points())
	audio_manager.set_music_ducked(false)
	audio_manager.set_music_pitch(1.0)
	audio_manager.play_music("menu")

func begin_run() -> void:
	if is_game_started:
		return
	is_game_started = true
	_hitstop_timer = 0.0
	hud.hide_start_menu()
	if get_viewport():
		get_viewport().gui_release_focus()
	_sync_settings()

	# Re-enable physics
	player.set_physics_process(true)
	chunk_container.process_mode = Node.PROCESS_MODE_PAUSABLE

	_apply_mode_settings()
	_apply_biome_modifier()
	player.state_machine.change_state(PlayerStateMachine.State.RUN)
	audio_manager.set_music_ducked(false)
	audio_manager.set_music_pitch(1.0)
	audio_manager.play_music("run")

	if current_mode == 3 and hud.practice_hub:
		hud.update_hud(0, 0.0, 0, save_service.get_points())
		if DisplayServer.get_name() != "headless" and not tutorial_active and practice_section_index < 0 and not custom_map_active and not _practice_entry_pending:
			_practice_entry_pending = true
			get_tree().paused = true
			hud.practice_hub.show_entry_choice()
		else:
			hud.practice_hub.show_practice_bar()
	elif hud.practice_hub:
		hud.practice_hub.hide_all()

func start_new_run() -> void:
	is_game_over = false
	is_paused = false
	is_game_started = true
	_hitstop_timer = 0.0
	get_tree().paused = false
	hud.hide_game_over()
	hud.hide_pause_menu()
	hud.hide_start_menu()
	if get_viewport():
		get_viewport().gui_release_focus()
	if hud.practice_hub:
		hud.practice_hub.hide_adaptive_hint()
		if current_mode != 3 and not custom_map_active:
			hud.practice_hub.hide_all()
	_sync_settings()

	player.set_physics_process(true)
	chunk_container.process_mode = Node.PROCESS_MODE_PAUSABLE

	_practice_pattern_hits.clear()
	_reset_world_state()

	player.reset()
	_apply_mode_settings()
	_apply_biome_modifier()
	_apply_equipped_perks_and_cosmetics(true)

	if custom_map_active and not custom_map_data.is_empty():
		_populate_custom_map_items()

	hud.update_hud(0, 0.0, save_service.get_mode_best_score(current_mode), save_service.get_points())
	audio_manager.set_music_ducked(false)
	audio_manager.set_music_pitch(1.0)
	audio_manager.play_music("run")

func _refill_skill_bag() -> void:
	_skill_bag.clear()
	var enabled: Array[int] = save_service.get_enabled_map_skills() if save_service else [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
	for sk_id in enabled:
		var info: Dictionary = SkillManager.SKILL_DATA.get(sk_id, {})
		if info.is_empty():
			continue
		var weight: int = int(info.get("spawn_weight", 10))
		var copies: int = maxi(1, roundi(float(weight) / 8.0))
		for _c in range(copies):
			_skill_bag.append(sk_id)
	if _skill_bag.is_empty():
		return
	# Deterministic shuffle using level_generator.rng
	for i in range(_skill_bag.size() - 1, 0, -1):
		var j = int(level_generator.rng.randi() % (i + 1))
		var tmp = _skill_bag[i]
		_skill_bag[i] = _skill_bag[j]
		_skill_bag[j] = tmp

func _reset_world_state() -> void:
	for c in chunk_container.get_children():
		chunk_container.remove_child(c)
		c.queue_free()
	chunk_pool.clear()

	if fx_container:
		for f in fx_container.get_children():
			fx_container.remove_child(f)
			f.queue_free()
	if fx_manager:
		fx_manager.clear_all()

	if camera:
		camera.reset_camera()

	start_x = 100.0
	player.position = Vector2(start_x, 218.0)
	player.reset_physics_interpolation()
	if camera:
		camera.global_position.x = player.global_position.x + camera.horizontal_lead
		camera.reset_physics_interpolation()

	next_chunk_x = 0.0
	distance_px = 0.0
	distance_m = 0.0
	current_score = 0
	bonus_score = 0
	combo_count = 0
	combo_timer = 0.0
	combo_max_this_run = 0
	combo_multiplier = 1
	near_misses_this_run = 0
	hazards_broken_this_run = 0
	is_fever_active = false
	_procedural_chunks_spawned = 0
	_skill_bag.clear()
	_next_skill_spawn_m = 40.0
	_skill_lab_next_wave_x = 340.0
	if player.skill_manager:
		player.skill_manager.skill_lab_infinite = skill_lab_active
	if hud.has_method("clear_trap_hud"):
		hud.clear_trap_hud()
	if challenge_service:
		challenge_service.reset_session_run_stats()

	hud.update_gems(0)
	if hud.has_method("update_combo"):
		hud.update_combo(0, 1, false, 0.0)
	if hud.has_method("update_skill_slots") and player.skill_manager:
		hud.update_skill_slots(player.skill_manager.get_slots_snapshot())
	else:
		hud.update_skill_slot({}, 0.0, 0.0, 0)
	hud.hide_flight_hud()
	_apply_equipped_perks_and_cosmetics(false)

	current_world_index = 0
	if not world_themes.is_empty() and world_themes[0] != null:
		var t0 = world_themes[0]
		next_transition_distance_m = t0.transition_distance_m
		if parallax_bg:
			parallax_bg.apply_theme_immediate(t0)
		hud.update_world_name(t0.world_name)

	if run_seed == 0:
		run_seed = int((Time.get_ticks_usec() + randi()) % 900000 + 100000)
	level_generator.set_seed(run_seed)
	hud.update_seed(run_seed)
	_refill_skill_bag()

	# Initial opening chunks: keep runway clear if entering Tutorial or Skill Lab, otherwise smooth opening chunks
	_spawn_left_ground_extension()
	_spawn_chunk_by_index(0, not (tutorial_active or skill_lab_active)) # Chunk 1: Opening breather (0..480)
	if tutorial_active or skill_lab_active or (current_mode == 3 and _practice_entry_pending):
		_spawn_chunk_by_index(0, false)
		_spawn_chunk_by_index(0, false)
	else:
		_spawn_chunk_by_index(1, true)  # Chunk 2: First low hop + glittering gem arc (480..960)
		_spawn_chunk_by_index(5, true)  # Chunk 3: Stepping crate + reward trail (960..1440)

func _physics_process(delta: float) -> void:
	if not is_game_started or is_game_over or is_paused:
		return

	# Hitstop micro-freeze for juicy impacts (pauses player & world briefly without killing HUD)
	if _hitstop_timer > 0.0:
		_hitstop_timer = maxf(_hitstop_timer - delta, 0.0)
		player.set_physics_process(_hitstop_timer <= 0.0)
		chunk_container.process_mode = Node.PROCESS_MODE_DISABLED if _hitstop_timer > 0.0 else Node.PROCESS_MODE_PAUSABLE
		if fx_manager:
			var w_id_hs = world_themes[current_world_index].world_id if current_world_index < world_themes.size() and world_themes[current_world_index] != null else "plains"
			fx_manager.update_fx(delta, camera.global_position.x if camera else player.global_position.x, camera.global_position.y if camera else 135.0, player.global_position, player.current_speed, w_id_hs, true)
		return

	# Calculate distance & score (Volcanic heat modifier gives +25% distance pace)
	distance_px = maxf(player.global_position.x - start_x, 0.0)
	distance_m = distance_px * 0.1
	var world_mult: float = 1.15 if _get_current_modifier() == "VOLCANIC_ERUPTIONS" else 1.0
	current_score = int(distance_m * 1.5 * world_mult * _cached_score_mult) + bonus_score

	# Dynamic speed progression: start readable and smooth, then accelerate steadily over distance
	var base_spd: float = 216.0
	match current_mode:
		0: # Easy: starts gentle and caps cleanly
			base_spd = minf(196.0 + (distance_m * 0.14), 400.0)
		1: # Medium (Runner): smooth acceleration
			base_spd = minf(216.0 + (distance_m * 0.18), 460.0)
		2: # Hard: faster ramp + dense obstacles + full movement
			base_spd = minf(232.0 + (distance_m * 0.22), 495.0)
		3: # Practice / Skill Lab
			base_spd = 196.0 if skill_lab_active else minf(196.0 + (distance_m * 0.10), 310.0)
	if custom_map_active:
		var preset: int = int(custom_map_data.get("speed_preset", 1))
		base_spd = 196.0 if preset == 0 else (330.0 if preset == 2 else 250.0)
	if player.skill_manager and player.skill_manager.world_time_scale < 0.99:
		base_spd *= 0.78
	player.current_speed = base_spd

	if tutorial_active:
		_update_live_tutorial(delta)
	elif skill_lab_active:
		_update_skill_lab_arena()

	# Combo decay & Fever feedback
	if combo_count > 0:
		combo_timer = maxf(combo_timer - delta, 0.0)
		if combo_timer <= 0.0:
			combo_count = 0
			combo_multiplier = 1
			is_fever_active = false
			audio_manager.set_music_pitch(1.0)
		if hud.has_method("update_combo"):
			hud.update_combo(combo_count, combo_multiplier, is_fever_active, combo_timer / 2.8)

	# Camera dynamic speed/flight zoom framing
	if camera:
		var spd_ratio = clampf((player.current_speed - 280.0) / 180.0, 0.0, 1.0)
		var target_z = 0.90 if player.is_flying else (1.0 - 0.08 * spd_ratio)
		camera.set_dynamic_zoom(target_z)

	# Dash / Rocket / Fever afterimages & Slide gravel sparks
	_update_continuous_fx(delta)

	# Near-miss grazing reward check
	_check_near_misses()

	if challenge_service and current_mode != 3 and not custom_map_active:
		challenge_service.check_run_progress(distance_m, current_score, current_mode)
		_check_mastery_progress()

	# World Transition
	if not skill_lab_active and not tutorial_active and not custom_map_active and distance_m >= next_transition_distance_m and not world_themes.is_empty():
		_trigger_world_transition()

	hud.update_hud(current_score, distance_m, save_service.get_mode_best_score(current_mode), save_service.get_points())
	if hud.has_method("update_trap_debuff"):
		hud.update_trap_debuff(player.trap_debuff_timer, player.trap_type, player.trap_glitch_timer)

	if player.global_position.x + CHUNK_WIDTH * 2.0 > next_chunk_x:
		_spawn_next_procedural_chunk()

	_cleanup_chunks_behind(player.global_position.x - 600.0)

func _update_continuous_fx(delta: float) -> void:
	if fx_manager == null or player == null:
		return
	var st = player.state_machine.current_state
	var sm = player.skill_manager
	fx_manager.active_shield = sm != null and sm.has_shield
	fx_manager.active_immortal_shield = player.practice_immortal
	fx_manager.active_magnet = player.is_magnet_active
	fx_manager.active_time_shard = sm != null and sm.world_time_scale < 0.99
	fx_manager.active_fever = is_fever_active
	if player.trap_debuff_timer > 0.0:
		match player.trap_type:
			1: fx_manager.active_trap_color = Color(0.68, 0.34, 1.0, 0.72)
			2: fx_manager.active_trap_color = Color(0.18, 0.92, 0.96, 0.72)
			3: fx_manager.active_trap_color = Color(1.0, 0.25, 0.32, 0.78)
			_: fx_manager.active_trap_color = Color(1.0, 0.84, 0.08, 0.72)
	else:
		fx_manager.active_trap_color = Color(0, 0, 0, 0)

	if st == PlayerStateMachine.State.AIR_DASH or is_fever_active or (player.is_flying and player.flight_type == 2):
		_dash_trail_timer -= delta
		if _dash_trail_timer <= 0.0 and player.sprite and player.sprite.texture:
			_dash_trail_timer = 0.032 if st == PlayerStateMachine.State.AIR_DASH else 0.065
			var region = _get_sprite_frame_rect(player.sprite)
			var tcol = Color(1.0, 0.85, 0.25, 0.5) if is_fever_active else (Color(1.0, 0.55, 0.2, 0.55) if player.is_flying else Color(0.35, 0.95, 1.0, 0.6))
			fx_manager.spawn_afterimage(player.sprite.texture, region, player.global_position, tcol)

	if _cached_trail_color.a > 0.05:
		_cosmetic_trail_timer -= delta
		if _cosmetic_trail_timer <= 0.0:
			_cosmetic_trail_timer = 0.07
			var col := _cached_trail_color
			if save_service and save_service.get_equipped_cosmetic("trail") == "trail_rainbow":
				col = Color.from_hsv(fmod(Time.get_ticks_msec() * 0.001, 1.0), 0.85, 1.0, 0.9)
			fx_manager.spawn_burst(player.global_position + Vector2(-8, 6), col, 2, 30.0, 0.7, 2.2, 15.0, 0.24)

	if st == PlayerStateMachine.State.SLIDE and player.is_on_floor():
		_slide_spark_timer -= delta
		if _slide_spark_timer <= 0.0:
			_slide_spark_timer = 0.06
			var scol = Color(0.68, 0.95, 1.0) if _get_current_modifier() == "SLIPPERY_SURFACES" else Color(0.86, 0.78, 0.62)
			fx_manager.spawn_burst(player.global_position + Vector2(-8, 13), scol, 3, 45.0, PI * 0.6, 2.0, 180.0, 0.24)

	var w_id = "plains"
	if current_world_index < world_themes.size() and world_themes[current_world_index] != null:
		w_id = world_themes[current_world_index].world_id
	var cam_x = camera.global_position.x if camera else player.global_position.x
	var cam_y = camera.global_position.y if camera else 135.0
	fx_manager.update_fx(delta, cam_x, cam_y, player.global_position, player.current_speed, w_id, true)

func _get_sprite_frame_rect(spr: Sprite2D) -> Rect2:
	if spr == null or spr.texture == null:
		return Rect2(0, 0, 32, 32)
	var fw = float(spr.texture.get_width()) / maxf(1.0, float(spr.hframes))
	var fh = float(spr.texture.get_height()) / maxf(1.0, float(spr.vframes))
	var col = spr.frame % maxi(1, spr.hframes)
	var row = spr.frame / maxi(1, spr.hframes)
	return Rect2(col * fw, row * fh, fw, fh)

func _check_near_misses() -> void:
	if player.state_machine.current_state == PlayerStateMachine.State.DEAD or player.invulnerability_timer > 0.0:
		return
	var hazards = get_tree().get_nodes_in_group("hazards")
	for h in hazards:
		if not (h is Hazard) or h.is_destroyed or h._near_miss_awarded:
			continue
		var col := h.get_node_or_null("CollisionShape2D") as CollisionShape2D
		var ref_pos: Vector2 = col.global_position if col else h.global_position
		var dx = player.global_position.x - ref_pos.x
		if h.hazard_name.to_lower().contains("overhang"):
			# Overhang obstacle spans ground_y-24..ground_y-254; reward cleanly sliding underneath!
			if player.state_machine.current_state == PlayerStateMachine.State.SLIDE and dx >= -8.0 and dx <= 32.0:
				h._near_miss_awarded = true
				near_misses_this_run += 1
				if save_service and current_mode != 3:
					save_service.record_milestone("total_near_misses", 1, false)
				var pts = int(roundf(30.0 * _cached_near_miss_mult)) * combo_multiplier
				bonus_score += pts
				_bump_combo(player.global_position + Vector2(0, -14), "", Color(0.45, 0.98, 1.0))
			continue
		# Trigger just as player clears closely past active hazard body
		if dx >= 14.0 and dx <= 38.0:
			var dy = absf(player.global_position.y - ref_pos.y)
			if dy <= 40.0:
				h._near_miss_awarded = true
				near_misses_this_run += 1
				if save_service and current_mode != 3:
					save_service.record_milestone("total_near_misses", 1, false)
				var pts = int(roundf(25.0 * _cached_near_miss_mult)) * combo_multiplier
				bonus_score += pts
				_bump_combo(player.global_position + Vector2(0, -18), "", Color(0.45, 0.98, 1.0))

func _bump_combo(popup_pos: Vector2, label_text: String = "", popup_color: Color = Color(1.0, 0.92, 0.35)) -> void:
	var prev_mult = combo_multiplier
	combo_count += 1
	combo_timer = 2.8
	if combo_count > combo_max_this_run:
		combo_max_this_run = combo_count
		if save_service and current_mode != 3 and combo_max_this_run > save_service.get_milestone("max_combo_best"):
			save_service.data["milestones"]["max_combo_best"] = combo_max_this_run
			save_service.mark_dirty()
	if challenge_service and current_mode != 3 and not custom_map_active:
		challenge_service.record_combo(combo_count)

	if combo_count >= 15:
		combo_multiplier = 5
		if not is_fever_active:
			is_fever_active = true
			audio_manager.set_music_pitch(1.06)
	elif combo_count >= 10:
		combo_multiplier = 4
	elif combo_count >= 6:
		combo_multiplier = 3
	elif combo_count >= 3:
		combo_multiplier = 2
	else:
		combo_multiplier = 1

	if combo_multiplier > prev_mult:
		audio_manager.play_combo(combo_multiplier)
		if fx_manager:
			fx_manager.spawn_shockwave(player.global_position, 46.0, Color(1.0, 0.86, 0.25), 0.26, 2.5)
	if fx_manager and not label_text.is_empty():
		fx_manager.spawn_floating_text(popup_pos, label_text, popup_color, 1.05 if combo_multiplier >= 3 else 1.0)
	if hud.has_method("update_combo"):
		hud.update_combo(combo_count, combo_multiplier, is_fever_active, 1.0)

func _check_mastery_progress() -> void:
	if save_service == null:
		return
	if combo_max_this_run >= 10:
		_unlock_mastery("mastery_combo_10", "Combo Virtuoso (10x Streak)", 75)
	if near_misses_this_run >= 5:
		_unlock_mastery("mastery_near_miss_5", "Daredevil Grazer (5 Close Calls)", 90)
	if hazards_broken_this_run >= 5:
		_unlock_mastery("mastery_destroy_5", "Wrecking Dino (5 Shatters)", 100)
	if current_world_index >= 3:
		_unlock_mastery("mastery_world_4", "Volcanic Pioneer (Reached Caldera)", 150)

func _unlock_mastery(mid: String, _title: String, reward: int) -> void:
	if save_service.complete_mastery_challenge(mid, reward):
		audio_manager.play_new_best()

func _get_current_modifier() -> String:
	if current_world_index < world_themes.size() and world_themes[current_world_index] != null:
		return world_themes[current_world_index].gameplay_modifier
	return "NONE"

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_BACK):
		_handle_back_action()
		return

	if _is_any_modal_open():
		return

	if not is_game_started:
		if event.is_action_pressed("jump") or event.is_action_pressed("ui_accept"):
			begin_run()
		return

	if event.is_action_pressed("pause"):
		toggle_pause()
	elif is_game_over and (event.is_action_pressed("jump") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R)):
		restart_run()
	elif not is_game_over and not is_paused and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			player.use_skill(0)
		elif event.keycode == KEY_2:
			player.use_skill(1)
		elif event.keycode == KEY_3:
			player.use_skill(2)

func _is_any_modal_open() -> bool:
	if hud == null:
		return false
	if hud.settings_dialog and hud.settings_dialog.visible: return true
	if hud.credits_dialog and hud.credits_dialog.visible: return true
	if hud.tutorial_dialog and hud.tutorial_dialog.visible: return true
	if hud.skin_shop_dialog and hud.skin_shop_dialog.visible: return true
	if hud.challenges_dialog and hud.challenges_dialog.visible: return true
	if hud.practice_hub and hud.practice_hub.has_modal_open(): return true
	return false

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_CLOSE_REQUEST:
			if is_game_started and not is_game_over and not is_paused and what != NOTIFICATION_WM_CLOSE_REQUEST:
				pause_game()
			if save_service:
				save_service.flush_if_dirty()
			_clear_all_held_inputs()

func _clear_all_held_inputs() -> void:
	if player:
		player.jump_held = false
		player.slide_held = false
		player.steer_input = 0.0
		player.flight_up_input = false
		player.flight_down_input = false
	if hud and hud.has_method("clear_touch_inputs"):
		hud.clear_touch_inputs()

func _handle_back_action() -> void:
	if hud.practice_hub and hud.practice_hub.close_active_modal():
		return
	if hud.settings_dialog and hud.settings_dialog.visible:
		hud.close_settings()
	elif hud.credits_dialog and hud.credits_dialog.visible:
		hud.close_credits()
	elif hud.tutorial_dialog and hud.tutorial_dialog.visible:
		hud.close_tutorial()
	elif hud.skin_shop_dialog and hud.skin_shop_dialog.visible:
		hud.close_skin_shop()
	elif hud.challenges_dialog and hud.challenges_dialog.visible:
		hud.close_challenges()
	elif is_game_started and not is_game_over:
		if is_paused:
			resume_game()
		else:
			pause_game()
	elif is_game_over:
		go_to_title_menu()

func get_skill_spawn_interval_m(skill_type: int) -> float:
	var s_info: Dictionary = SkillManager.SKILL_DATA.get(skill_type, {})
	var tier: int = int(s_info.get("tier", SkillManager.SkillTier.COMMON))
	match tier:
		SkillManager.SkillTier.RARE:
			return 105.0
		SkillManager.SkillTier.EPIC:
			return 145.0
		SkillManager.SkillTier.LEGENDARY:
			return 195.0
		_:
			return 70.0

func _spawn_left_ground_extension() -> void:
	if chunk_container == null or not ResourceLoader.exists("res://assets/sprites/ground_tile.png"):
		return
	var ext := Node2D.new()
	ext.name = "LeftGroundExtension"
	var tex: Texture2D = theme_tile_textures.get("plains", load("res://assets/sprites/ground_tile.png"))
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.centered = false
	spr.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	spr.region_enabled = true
	spr.region_rect = Rect2(0, 0, 480, 16)
	spr.position = Vector2(-480.0, 230.0)
	ext.add_child(spr)
	chunk_container.add_child(ext)

func _spawn_chunk_by_index(idx: int, inject_starter_rewards: bool = false) -> void:
	var scene = chunk_scenes[idx % chunk_scenes.size()]
	var chunk = scene.instantiate() as Node2D
	chunk.position = Vector2(next_chunk_x, 0.0)
	chunk_container.add_child(chunk)
	chunk_pool.append(chunk)
	_decorate_and_wire_chunk(chunk, inject_starter_rewards, false)
	next_chunk_x += CHUNK_WIDTH

func _spawn_next_procedural_chunk() -> void:
	if tutorial_active or skill_lab_active:
		_spawn_chunk_by_index(0, false)
		return
	if custom_map_active:
		_spawn_chunk_by_index(0, false)
		return
	if practice_section_index >= 0:
		_practice_section_counter += 1
		if _practice_section_counter % 4 == 0:
			_spawn_chunk_by_index(0, false)
		else:
			_spawn_chunk_by_index(practice_section_index, true)
		return

	var world_id = "plains"
	if current_world_index < world_themes.size() and world_themes[current_world_index] != null:
		world_id = world_themes[current_world_index].world_id

	var allowed_moves: Array = []
	var avoid_overhang: bool = player.is_flying
	# Hard mode (mode 2) raises effective distance band so denser, movement-rich obstacle chunks appear sooner!
	var gen_dist: float = distance_m + (180.0 if current_mode == 2 else 0.0)
	var pat = level_generator.select_next_pattern(gen_dist, player.current_speed, world_id, allowed_moves, avoid_overhang)
	if pat == null:
		_spawn_chunk_by_index(0, false)
		return

	var scene = load(pat.chunk_scene_path) as PackedScene
	if scene == null:
		_spawn_chunk_by_index(0, false)
		return

	var chunk = scene.instantiate() as Node2D
	chunk.position = Vector2(next_chunk_x, 0.0)
	chunk_container.add_child(chunk)
	chunk_pool.append(chunk)
	_procedural_chunks_spawned += 1
	_decorate_and_wire_chunk(chunk, true, true)
	next_chunk_x += pat.chunk_width

func _decorate_and_wire_chunk(chunk: Node2D, allow_rewards: bool, is_procedural: bool) -> void:
	var world_id = "plains"
	if current_world_index < world_themes.size() and world_themes[current_world_index] != null:
		world_id = world_themes[current_world_index].world_id

	# 1. Swap biome ground tile texture cleanly
	if theme_tile_textures.has(world_id):
		var tile_tex: Texture2D = theme_tile_textures[world_id]
		var tiles_node = chunk.get_node_or_null("Ground/Tiles")
		if tiles_node:
			for child in tiles_node.get_children():
				if child is Sprite2D:
					child.texture = tile_tex

	# 2. Wire active Time Shard scale, hazard break hooks, bounce SFX, and check existing pickups
	var has_gem := false
	var has_skill := false
	var existing_hazards: Array[Vector2] = []
	var existing_gems: Array[Vector2] = []
	var has_breakable := false
	var breakable_pos: Vector2 = Vector2.ZERO
	var has_flyer_or_crawler := false
	var enemy_pos: Vector2 = Vector2.ZERO
	var has_aerial_or_bounce := false
	var aerial_pos: Vector2 = Vector2.ZERO
	var active_ts = player.skill_manager.world_time_scale if player.skill_manager else 1.0
	var stack: Array[Node] = [chunk]
	while not stack.is_empty():
		var cur = stack.pop_back()
		for ch in cur.get_children():
			stack.append(ch)
		if cur is Hazard:
			var h_pos := (cur as Node2D).position
			existing_hazards.append(h_pos)
			if cur.category == Hazard.Category.BREAKABLE and not has_breakable:
				has_breakable = true
				breakable_pos = h_pos
			elif (cur.category == Hazard.Category.AIRBORNE or cur.category == Hazard.Category.CRAWLER) and not has_flyer_or_crawler:
				has_flyer_or_crawler = true
				enemy_pos = h_pos
			elif cur.category == Hazard.Category.ENVIRONMENTAL and not has_aerial_or_bounce:
				has_aerial_or_bounce = true
				aerial_pos = h_pos
			if _cached_obs_tint != Color.WHITE:
				(cur as Node2D).modulate = _cached_obs_tint
			if active_ts != 1.0:
				cur.set_time_scale(active_ts)
			if not cur.destroyed.is_connected(_on_hazard_destroyed):
				cur.destroyed.connect(_on_hazard_destroyed)
		elif cur is Collectible:
			has_gem = true
			existing_gems.append((cur as Node2D).position)
		elif cur is SkillPickup:
			has_skill = true
		elif cur is BouncePad:
			has_aerial_or_bounce = true
			aerial_pos = (cur as Node2D).position
			var pad := cur as BouncePad
			if not pad.launched.is_connected(_on_bounce_pad_triggered):
				pad.launched.connect(_on_bounce_pad_triggered.bind(pad))

	# Hard Mode extra movement/obstacle injection on breather-style chunks (safely spaced >= 140px)
	if is_procedural and current_mode == 2 and existing_hazards.size() <= 1 and distance_m >= 35.0:
		var extra_x: float = 340.0 if (existing_hazards.is_empty() or existing_hazards[0].x < 210.0) else 155.0
		var safe_spot := true
		for hp in existing_hazards:
			if absf(hp.x - extra_x) < 125.0:
				safe_spot = false
				break
		if safe_spot:
			var roll_ex := int(level_generator.rng.randi() % 3)
			var ex_path := "res://scenes/obstacles/obstacle_crawler.tscn" if roll_ex == 0 else ("res://scenes/obstacles/obstacle_pterodactyl.tscn" if roll_ex == 1 else "res://scenes/obstacles/obstacle_overhang.tscn")
			var ex_y := 222.0 if roll_ex == 0 else (184.0 if roll_ex == 1 else 230.0)
			if ResourceLoader.exists(ex_path):
				var ex_sc := load(ex_path) as PackedScene
				if ex_sc:
					var ex_node := ex_sc.instantiate() as Node2D
					ex_node.position = Vector2(extra_x, ex_y)
					chunk.add_child(ex_node)
					_wire_custom_node_recursive(ex_node)
					existing_hazards.append(ex_node.position)

	# 3. Ensure rewarding gem arcs appear smoothly
	if allow_rewards and not has_gem:
		var arc_base_x = 175.0 if is_procedural else 210.0
		var arc_ys = [184.0, 166.0, 184.0]
		for i in range(3):
			var gem = GemScene.instantiate()
			gem.position = Vector2(arc_base_x + float(i * 28), arc_ys[i])
			existing_gems.append(gem.position)
			chunk.add_child(gem)

	# 4. Distance- & Rarity-Gated Contextual Skill Spawning (only from user's selected pool!)
	if is_procedural and allow_rewards and not has_skill and distance_m >= _next_skill_spawn_m:
		if _skill_bag.is_empty():
			_refill_skill_bag()
		if not _skill_bag.is_empty():
			var chosen_skill: int = _pick_contextual_skill_from_bag(has_breakable, has_flyer_or_crawler, has_aerial_or_bounce, existing_gems.size() >= 3)
			var pickup = SkillPickupScene.instantiate() as SkillPickup
			pickup.skill_type = chosen_skill
			var target_pos: Vector2 = _pick_contextual_skill_pos(chosen_skill, has_breakable, breakable_pos, has_flyer_or_crawler, enemy_pos, has_aerial_or_bounce, aerial_pos, existing_hazards, existing_gems)
			pickup.position = target_pos
			chunk.add_child(pickup)

			# Advance next meter threshold based on spawned skill's rarity tier!
			var base_gap_m: float = get_skill_spawn_interval_m(chosen_skill)
			var jitter: float = float(level_generator.rng.randi_range(-10, 18))
			_next_skill_spawn_m = distance_m + maxf(55.0, base_gap_m + jitter)

	# Spawn varied avoidable hazard traps (Speed Surge, Heavy Gravity, Glitch Static, Skill Jam)
	var trap_mod: int = 3 if current_mode == 2 else 4
	if is_procedural and allow_rewards and current_mode != 3 and distance_m >= 50.0 and (_procedural_chunks_spawned % trap_mod == 1):
		var trap_candidates: Array[Vector2] = [Vector2(210.0, 148.0), Vector2(305.0, 148.0), Vector2(390.0, 148.0)]
		for tcand in trap_candidates:
			var t_clear := true
			for hp in existing_hazards:
				if absf(tcand.x - hp.x) < 62.0:
					t_clear = false
					break
			if t_clear:
				for gp in existing_gems:
					if tcand.distance_to(gp) < 36.0:
						t_clear = false
						break
			if t_clear:
				var trap = TrapPickupScene.instantiate()
				trap.position = tcand
				if trap.has_method("set_trap_type"):
					var t_kind: int = int(level_generator.rng.randi() % 4)
					trap.set_trap_type(t_kind)
				trap.trap_triggered.connect(_on_trap_triggered)
				chunk.add_child(trap)
				break

func _on_quest_trick(_id: String, _title: String, _reward: int) -> void:
	if player and is_game_started and not is_game_over:
		player.perform_trick()

func _on_level_up_trick(_new_level: int, _diamond_bonus: int) -> void:
	if player and is_game_started and not is_game_over:
		player.perform_trick()

func _on_trap_triggered(trap) -> void:
	var t_col: Color = Color(1.0, 0.85, 0.1)
	if trap != null and trap.has_method("get_trap_color"):
		t_col = trap.get_trap_color()
	if camera:
		camera.add_impact_shake(6.0, 0.24)
	if fx_manager and player:
		fx_manager.spawn_burst(player.global_position, t_col, 14, 140.0, TAU, 3.0, 220.0, 0.4)

func _on_player_trap_debuff_started(kind: int, duration: float) -> void:
	if hud and hud.has_method("show_trap_debuff"):
		hud.show_trap_debuff(kind, duration)

func _on_player_hearts_changed(cur: int, maximum: int) -> void:
	if hud and hud.has_method("update_hearts"):
		hud.update_hearts(cur, maximum, player.practice_immortal)

func _on_player_heart_shield_lost(remaining: int) -> void:
	audio_manager.play_shield_break()
	_hitstop_timer = maxf(_hitstop_timer, 0.045)
	if camera:
		camera.add_impact_shake(6.0, 0.22)
	if fx_manager and player:
		fx_manager.spawn_shockwave(player.global_position, 82.0, Color(1.0, 0.42, 0.48), 0.30, 3.0)
		fx_manager.spawn_burst(player.global_position, Color(1.0, 0.55, 0.6), 16, 145.0, TAU, 2.8, 220.0, 0.42)
	if hud and hud.has_method("show_skill_toast") and remaining > 0:
		hud.show_skill_toast("♥ HEART LOST • %d LEFT!" % remaining)

func _on_player_hazard_broken(hazard: Hazard, _source: String) -> void:
	if tutorial_active and tutorial_phase == 3 and is_instance_valid(hazard) and hazard.category == Hazard.Category.CRAWLER:
		_tut_crawler_done = true

func _on_hazard_destroyed(hazard: Hazard) -> void:
	hazards_broken_this_run += 1
	var pts = 40 * combo_multiplier
	bonus_score += pts
	if save_service and current_mode != 3:
		save_service.record_milestone("hazards_broken_total", 1, false)
		if _cached_shatter_bonus > 0:
			save_service.add_points(_cached_shatter_bonus, false)
		if challenge_service and not custom_map_active:
			challenge_service.record_hazard_broken()
	audio_manager.play_obstacle_break()
	if camera:
		camera.add_impact_shake(4.0, 0.16)
	if fx_manager and is_instance_valid(hazard):
		var col = Color(0.92, 0.56, 0.25) if hazard.category == Hazard.Category.BREAKABLE else Color(0.95, 0.35, 0.32)
		fx_manager.spawn_burst(hazard.global_position, col, 14, 130.0, TAU, 3.0, 260.0, 0.45)
		_bump_combo(hazard.global_position, "SMASH! +%d" % pts, Color(1.0, 0.72, 0.22))
	_hitstop_timer = maxf(_hitstop_timer, 0.032)

func _on_bounce_pad_triggered(_body: Node2D, _force: float, pad: BouncePad) -> void:
	if _tut_bounce_done == false and tutorial_phase == 4:
		_tut_bounce_done = true
	audio_manager.play_bounce()
	if fx_manager and is_instance_valid(pad):
		fx_manager.spawn_burst(pad.global_position + Vector2(0, -6), Color(0.45, 1.0, 0.55), 10, 110.0, PI, 2.5, 180.0, 0.35)
		_bump_combo(pad.global_position + Vector2(0, -16), "BOING! +%d" % (15 * combo_multiplier), Color(0.55, 1.0, 0.65))
	bonus_score += 15 * combo_multiplier

func _process(_delta: float) -> void:
	if hud:
		var state_str = "RUN"
		if is_game_over: state_str = "DEAD"
		elif is_paused: state_str = "PAUSED"
		elif not is_game_started: state_str = "TITLE"
		elif player.is_flying: state_str = "FLYING"
		hud.update_dev_overlay(int(Engine.get_frames_per_second()), player.current_speed, state_str, run_seed)

func _cleanup_chunks_behind(cutoff_x: float) -> void:
	var remaining: Array[Node2D] = []
	for chunk in chunk_pool:
		if is_instance_valid(chunk):
			var w = CHUNK_WIDTH
			if "chunk_width" in chunk:
				w = chunk.chunk_width
			if chunk.position.x + w < cutoff_x:
				chunk.queue_free()
			else:
				remaining.append(chunk)
	chunk_pool = remaining

func _on_player_died(cause: String) -> void:
	if is_game_over or not is_game_started:
		return
	is_game_over = true
	_clear_all_held_inputs()

	var run_pts: int = int(distance_m * 0.5) + int(current_score * 0.1)
	if run_pts < 1 and distance_m > 5.0:
		run_pts = 1
	if current_mode == 3:
		run_pts = mini(run_pts, 10) # Cap practice mode participation reward cleanly
	save_service.add_points(run_pts, false)

	var is_new_best = false
	if current_mode != 3:
		is_new_best = save_service.update_mode_high_score(current_mode, current_score, distance_m, true)
	else:
		save_service.flush_if_dirty()

	audio_manager.set_music_ducked(true)
	audio_manager.play_damage()
	if is_new_best:
		audio_manager.play_new_best()
	else:
		audio_manager.play_game_over()

	if camera:
		camera.add_impact_shake(7.5, 0.28)
	if fx_manager:
		fx_manager.spawn_burst(player.global_position, Color(1.0, 0.35, 0.25), 18, 150.0, TAU, 3.0, 260.0, 0.55)
		fx_manager.spawn_shockwave(player.global_position, 56.0, Color(1.0, 0.25, 0.25), 0.28, 3.0)

	var next_biome_hint := ""
	if not world_themes.is_empty():
		var next_idx = (current_world_index + 1) % world_themes.size()
		if world_themes[next_idx] != null:
			var dist_left = maxf(next_transition_distance_m - distance_m, 1.0)
			next_biome_hint = "%.0fm to %s!" % [dist_left, world_themes[next_idx].world_name]

	hud.show_game_over(cause, current_score, distance_m, save_service.get_mode_best_score(current_mode), is_new_best, run_pts, save_service.get_points(), combo_max_this_run, next_biome_hint)

func toggle_pause() -> void:
	if is_game_over or not is_game_started:
		return
	if is_paused:
		resume_game()
	else:
		pause_game()

func pause_game() -> void:
	is_paused = true
	_clear_all_held_inputs()
	if save_service:
		save_service.flush_if_dirty()
	get_tree().paused = true
	audio_manager.set_music_ducked(true)
	hud.show_pause_menu()

func resume_game() -> void:
	is_paused = false
	get_tree().paused = false
	audio_manager.set_music_ducked(false)
	hud.hide_pause_menu()

func restart_run() -> void:
	if save_service:
		save_service.flush_if_dirty()
	run_seed = 0 # Generate a fresh procedural layout on every retry
	start_new_run()

func go_to_title_menu() -> void:
	if save_service:
		if current_mode == 3 and not save_service.is_first_launch_completed():
			save_service.set_first_launch_completed(true, false)
		save_service.flush_if_dirty()
	run_seed = 0
	tutorial_active = false
	skill_lab_active = false
	_practice_entry_pending = false
	practice_section_index = -1
	custom_map_active = false
	custom_map_chain.clear()
	_practice_pattern_hits.clear()
	if player and player.skill_manager:
		player.skill_manager.skill_lab_infinite = false
	if hud.practice_hub:
		hud.practice_hub.hide_all()
	if hud.has_method("clear_trap_hud"):
		hud.clear_trap_hud()
	hud.hide_pause_menu()
	hud.hide_game_over()
	init_title_screen()

func _on_player_jumped() -> void:
	if tutorial_active:
		_tut_real_jump_triggered = true
	audio_manager.play_jump()
	if fx_manager:
		fx_manager.spawn_burst(player.global_position + Vector2(0, 12), Color(0.85, 0.85, 0.72), 6, 65.0, PI * 0.8, 2.0, 160.0, 0.28)
	if challenge_service and current_mode != 3:
		challenge_service.record_jump()

func _on_player_landed() -> void:
	audio_manager.play_land()
	if fx_manager:
		fx_manager.spawn_burst(player.global_position + Vector2(0, 12), Color(0.75, 0.7, 0.55), 7, 70.0, PI * 0.85, 2.2, 200.0, 0.28)

func _on_player_slided() -> void:
	audio_manager.play_slide()
	if challenge_service and current_mode != 3:
		challenge_service.record_slide()

func _on_player_dived() -> void:
	audio_manager.play_slide()

func _on_player_air_dashed() -> void:
	audio_manager.play_air_dash()
	if camera:
		camera.add_impact_shake(3.0, 0.12)
	if fx_manager:
		fx_manager.spawn_burst(player.global_position + Vector2(-10, 0), Color(0.35, 0.95, 1.0), 12, 130.0, PI, 2.5, 40.0, 0.30)

func _on_player_ground_slammed() -> void:
	audio_manager.play_slam()
	_hitstop_timer = maxf(_hitstop_timer, 0.045)
	if camera:
		camera.add_impact_shake(6.5, 0.24)
	if fx_manager:
		fx_manager.spawn_shockwave(player.global_position + Vector2(0, 8), 140.0, Color(1.0, 0.76, 0.22), 0.34, 3.5)
		fx_manager.spawn_burst(player.global_position + Vector2(0, 10), Color(1.0, 0.82, 0.35), 16, 150.0, PI, 3.0, 260.0, 0.42)

func _on_player_skill_used(skill_type: int) -> void:
	if tutorial_active:
		_tut_skill_done = true
	if current_mode != 3 and not custom_map_active:
		if save_service:
			save_service.record_milestone("skills_used_total", 1, false)
		if challenge_service:
			challenge_service.record_skill_used()
	match skill_type:
		SkillManager.SkillType.BONE_BLADE:
			audio_manager.play_skill_activation()
			if fx_manager:
				fx_manager.spawn_slash_arc(player.global_position)
		SkillManager.SkillType.BOOMERANG:
			audio_manager.play_boomerang()
		SkillManager.SkillType.AIR_DASH:
			pass # Handled by _on_player_air_dashed
		SkillManager.SkillType.GROUND_SLAM:
			audio_manager.play_slide()
		_:
			audio_manager.play_skill_activation()
			if fx_manager:
				fx_manager.spawn_shockwave(player.global_position, 52.0, Color(0.5, 0.92, 1.0), 0.26, 2.0)

func _on_player_shield_broken() -> void:
	audio_manager.play_shield_break()
	_hitstop_timer = maxf(_hitstop_timer, 0.04)
	if camera:
		camera.add_impact_shake(5.5, 0.20)
	if fx_manager:
		fx_manager.spawn_shockwave(player.global_position, 72.0, Color(0.45, 0.95, 1.0), 0.28, 2.5)
		fx_manager.spawn_burst(player.global_position, Color(0.6, 0.95, 1.0), 16, 140.0, TAU, 2.8, 220.0, 0.4)
		fx_manager.spawn_floating_text(player.global_position + Vector2(0, -18), "SHIELD SAVED!", Color(0.45, 0.95, 1.0), 1.1)

func _on_player_flight_started(flight_type: int, duration: float) -> void:
	hud.show_flight_hud(flight_type, duration)
	audio_manager.play_flight_start()
	if camera:
		camera.add_impact_shake(3.0, 0.14)
	if fx_manager:
		var col = Color(1.0, 0.55, 0.2) if flight_type == 2 else Color(0.45, 0.95, 1.0)
		fx_manager.spawn_shockwave(player.global_position, 54.0, col, 0.30, 2.5)
		fx_manager.spawn_floating_text(player.global_position + Vector2(0, -20), "ROCKET BOOST!" if flight_type == 2 else "WINGS DEPLOYED!", col, 1.1)

func _on_player_flight_ended() -> void:
	hud.hide_flight_hud()
	audio_manager.play_flight_end()

func _on_skin_selected(skin_id: String) -> void:
	player.set_skin(skin_id)
	_apply_equipped_perks_and_cosmetics(false)

func _on_cosmetic_selected(_cat: String, _cid: String) -> void:
	_apply_equipped_perks_and_cosmetics(false)

func _apply_equipped_perks_and_cosmetics(is_run_start: bool) -> void:
	if save_service == null or player == null:
		return
	var perks: Dictionary = save_service.get_equipped_skin_perks()
	var obs_data: Dictionary = save_service.get_equipped_cosmetic_data("obstacle")
	var map_data: Dictionary = save_service.get_equipped_cosmetic_data("map")
	var trail_data: Dictionary = save_service.get_equipped_cosmetic_data("trail")

	_cached_score_mult = float(perks.get("score_mult", 1.0)) * float(map_data.get("dist_mult", 1.0)) * float(trail_data.get("score_mult", 1.0))
	_cached_gem_mult = int(perks.get("gem_mult", 1))
	_cached_near_miss_mult = float(obs_data.get("near_miss_mult", 1.0))
	_cached_shatter_bonus = int(obs_data.get("shatter_bonus", 0))
	_cached_obs_tint = obs_data.get("tint", Color.WHITE)
	_cached_trail_color = trail_data.get("color", Color(1, 1, 1, 0))

	if parallax_bg:
		var map_tint: Color = map_data.get("tint", Color.WHITE)
		for child in parallax_bg.get_children():
			if child is CanvasItem:
				child.modulate = map_tint

	player.passive_magnet = bool(perks.get("magnet", false))
	player.is_magnet_active = player.passive_magnet
	player.base_bounce_multiplier = 1.0 + float(perks.get("bounce_bonus", 0.0))
	player.bounce_multiplier = player.base_bounce_multiplier

	if player.skill_manager:
		player.skill_manager.cooldown_scale = float(perks.get("cd_scale", 1.0))
		player.skill_manager.duration_scale = float(perks.get("dur_scale", 1.0))

	if is_run_start and current_mode != 3:
		if bool(perks.get("start_shield", false)) and player.skill_manager:
			player.skill_manager.equip_skill(SkillManager.SkillType.STONE_SHIELD)
		var sg: int = int(perks.get("start_gems", 0))
		if sg > 0:
			player.gems_collected += sg
			hud.update_gems(player.gems_collected)
			save_service.add_points(sg, false)

func _on_hud_jump(pressed: bool) -> void:
	if not is_game_started:
		if pressed and not _is_any_modal_open():
			begin_run()
			if not get_tree().paused and not player.is_flying:
				player.trigger_jump_press()
		return
	if is_game_over or is_paused or player.is_flying:
		return
	var auto_hold = save_service.get_setting("auto_hold_jump", false) if save_service else false
	if pressed:
		player.trigger_jump_press()
	else:
		player.jump_held = false
		if not auto_hold and player.is_jump_holding:
			player.is_jump_holding = false
			if player.velocity.y < 0.0:
				player.velocity.y *= player.config.early_jump_release_multiplier

func _on_hud_slide(pressed: bool) -> void:
	if not is_game_started:
		if pressed and not _is_any_modal_open():
			begin_run()
			if not get_tree().paused and not player.is_flying:
				player.trigger_slide_press()
		return
	if is_game_over or is_paused:
		return
	player.slide_held = pressed
	if pressed and not player.is_flying:
		player.trigger_slide_press()

func _on_hud_steer(dir: float) -> void:
	if is_game_started and not is_game_over and not is_paused:
		player.steer_input = dir

func _on_hud_skill() -> void:
	if not is_game_started or is_game_over or is_paused:
		return
	player.use_skill(0)

func _on_hud_skill_slot(slot_idx: int) -> void:
	if not is_game_started or is_game_over or is_paused:
		return
	player.use_skill(slot_idx)

func _on_player_gem_collected(count: int, bonus: int) -> void:
	var canopy_mult = 1.25 if _get_current_modifier() == "CANOPY_ROUTES" else 1.0
	var skill_gem_mult = 2.0 if (player.skill_manager and player.skill_manager.double_gem_active) else 1.0
	var final_bonus = int(roundf(float(bonus) * canopy_mult * skill_gem_mult * _cached_score_mult)) * combo_multiplier
	bonus_score += final_bonus
	var world_mult: float = 1.15 if _get_current_modifier() == "VOLCANIC_ERUPTIONS" else 1.0
	current_score = int(distance_m * 1.5 * world_mult * _cached_score_mult) + bonus_score
	hud.update_gems(count)
	var diamond_gain := maxi(1, _cached_gem_mult)
	if current_mode != 3:
		save_service.add_points(diamond_gain, false)
		save_service.record_milestone("gems_collected_total", diamond_gain, false)
		if challenge_service:
			challenge_service.record_gem(diamond_gain)
	audio_manager.play_collect(combo_count)
	if fx_manager:
		fx_manager.spawn_burst(player.global_position, Color(0.35, 0.92, 1.0), 8, 95.0, TAU, 2.2, 140.0, 0.30)
	var tag = "+%d x%d" % [final_bonus, combo_multiplier] if combo_multiplier > 1 else "+%d" % final_bonus
	_bump_combo(player.global_position + Vector2(0, -14), tag, Color(0.45, 0.96, 1.0))

func _on_skill_equipped(_type: int, info: Dictionary) -> void:
	if hud.has_method("update_skill_slots") and player.skill_manager:
		hud.update_skill_slots(player.skill_manager.get_slots_snapshot())
	else:
		hud.update_skill_slot(info, 0.0, 0.0, player.skill_manager.current_charges)
	audio_manager.play_pickup()
	if fx_manager:
		fx_manager.spawn_burst(player.global_position, Color(1.0, 0.85, 0.35), 10, 110.0, TAU, 2.4, 120.0, 0.35)

func _on_skill_replaced(_old_name: String, _new_name: String) -> void:
	pass

func _on_skill_slots_changed(slots_snapshot: Array) -> void:
	if hud.has_method("update_skill_slots"):
		hud.update_skill_slots(slots_snapshot)

func _on_skill_updated(cd: float, dur: float, charges: int) -> void:
	if hud.has_method("update_skill_slots") and player and player.skill_manager:
		hud.update_skill_slots(player.skill_manager.get_slots_snapshot())
	elif player and player.skill_manager and player.skill_manager.current_skill == SkillManager.SkillType.NONE:
		hud.update_skill_slot({}, 0.0, 0.0, 0)
	elif player and player.skill_manager and player.skill_manager.current_skill == SkillManager.SkillType.STONE_SHIELD:
		hud.update_skill_slot(player.skill_manager.get_skill_info(SkillManager.SkillType.STONE_SHIELD), cd, dur, charges)
	else:
		hud.update_skill_status(cd, dur, charges)

# --- Session 7 World Transitions ---

func _trigger_world_transition() -> void:
	if world_themes.is_empty():
		return
	var prev_theme = world_themes[current_world_index] if current_world_index < world_themes.size() else null
	current_world_index = (current_world_index + 1) % world_themes.size()
	var new_theme = world_themes[current_world_index]
	var step_dist: float = 250.0
	if new_theme != null and prev_theme != null and new_theme.transition_distance_m > prev_theme.transition_distance_m:
		step_dist = new_theme.transition_distance_m - prev_theme.transition_distance_m
	elif new_theme != null and current_world_index == 0 and new_theme.transition_distance_m > 50.0:
		step_dist = new_theme.transition_distance_m
	next_transition_distance_m += step_dist
	_apply_biome_modifier()

	if save_service and current_mode != 3 and current_world_index + 1 > save_service.get_milestone("max_world_reached"):
		save_service.data["milestones"]["max_world_reached"] = current_world_index + 1
		save_service.mark_dirty()
	if challenge_service and current_mode != 3 and not custom_map_active:
		challenge_service.record_world(current_world_index + 1)

	var pat = level_generator.get_world_transition_pattern()
	var trans_scene = preload("res://scenes/obstacles/chunks/chunk_00_world_transition.tscn")
	var trans_chunk = trans_scene.instantiate() as Node2D
	trans_chunk.position = Vector2(next_chunk_x, 0.0)
	chunk_container.add_child(trans_chunk)
	chunk_pool.append(trans_chunk)
	_decorate_and_wire_chunk(trans_chunk, false, false)
	var w = pat.chunk_width if pat != null else CHUNK_WIDTH
	next_chunk_x += w

	if parallax_bg and new_theme:
		parallax_bg.transition_to_theme(new_theme, 1.5)

	if fx_manager:
		fx_manager.spawn_shockwave(player.global_position + Vector2(40, 0), 180.0, Color(0.35, 0.95, 1.0), 0.55, 3.5)
		fx_manager.spawn_burst(player.global_position + Vector2(20, -10), Color(0.45, 0.98, 1.0), 18, 160.0, TAU, 3.0, 90.0, 0.55)

	if new_theme:
		hud.update_world_name(new_theme.world_name)
	audio_manager.play_world_enter()

# ==============================================================================
# Live Interactive Tutorial, Adaptive Hints, Section Practice & Custom Maps
# ==============================================================================

func _on_hud_live_tutorial_requested() -> void:
	_practice_entry_pending = false
	practice_section_index = -1
	custom_map_active = false
	tutorial_active = true
	get_tree().paused = false
	is_paused = false
	hud.select_mode(3)
	current_mode = 3
	start_new_run()
	start_live_tutorial()

func _on_start_live_tutorial() -> void:
	_practice_entry_pending = false
	practice_section_index = -1
	custom_map_active = false
	_practice_pattern_hits.clear()
	get_tree().paused = false
	is_paused = false
	start_live_tutorial()

func _on_skip_to_practice() -> void:
	_practice_entry_pending = false
	tutorial_active = false
	_clear_tutorial_lane_hazards()
	get_tree().paused = false
	is_paused = false
	if save_service and not save_service.is_first_launch_completed():
		save_service.set_first_launch_completed(true)
	if hud.practice_hub:
		hud.practice_hub.hide_tutorial_banner()
		hud.practice_hub.show_practice_bar("🛡 FREE PRACTICE • NO DEATH • NO SCORE")

func _pick_contextual_skill_from_bag(has_breakable: bool, has_enemy: bool, has_aerial: bool, has_gems: bool) -> int:
	if _skill_bag.is_empty():
		return int(SkillManager.SkillType.BONE_BLADE)
	var preferred: Array[int] = []
	if has_breakable:
		preferred.append_array([int(SkillManager.SkillType.BONE_BLADE), int(SkillManager.SkillType.SHOCKWAVE_ROAR), int(SkillManager.SkillType.GROUND_SLAM)])
	if has_enemy:
		preferred.append_array([int(SkillManager.SkillType.BOOMERANG), int(SkillManager.SkillType.SHOCKWAVE_ROAR), int(SkillManager.SkillType.GROUND_SLAM), int(SkillManager.SkillType.STONE_SHIELD)])
	if has_aerial:
		preferred.append_array([int(SkillManager.SkillType.AIR_DASH), int(SkillManager.SkillType.BOUNCE_POWER), int(SkillManager.SkillType.FEATHER_FALL), int(SkillManager.SkillType.PHOENIX_WINGS)])
	if has_gems:
		preferred.append_array([int(SkillManager.SkillType.MAGNET_RELIC), int(SkillManager.SkillType.DOUBLE_GEM)])

	for i in range(_skill_bag.size()):
		if preferred.has(_skill_bag[i]):
			var sk: int = _skill_bag[i]
			_skill_bag.remove_at(i)
			return sk
	return _skill_bag.pop_front()

func _pick_contextual_skill_pos(skill_id: int, has_breakable: bool, breakable_pos: Vector2, has_enemy: bool, enemy_pos: Vector2, has_aerial: bool, aerial_pos: Vector2, existing_hazards: Array[Vector2], existing_gems: Array[Vector2]) -> Vector2:
	var candidates: Array[Vector2] = []
	if (skill_id == SkillManager.SkillType.BONE_BLADE or skill_id == SkillManager.SkillType.SHOCKWAVE_ROAR) and has_breakable:
		candidates.append(Vector2(maxf(80.0, breakable_pos.x - 115.0), 192.0))
	elif (skill_id == SkillManager.SkillType.BOOMERANG or skill_id == SkillManager.SkillType.SHOCKWAVE_ROAR) and has_enemy:
		candidates.append(Vector2(maxf(80.0, enemy_pos.x - 125.0), 190.0))
	elif (skill_id == SkillManager.SkillType.AIR_DASH or skill_id == SkillManager.SkillType.BOUNCE_POWER or skill_id == SkillManager.SkillType.FEATHER_FALL or skill_id == SkillManager.SkillType.PHOENIX_WINGS) and has_aerial:
		candidates.append(Vector2(maxf(80.0, aerial_pos.x - 95.0), 182.0))
	elif (skill_id == SkillManager.SkillType.MAGNET_RELIC or skill_id == SkillManager.SkillType.DOUBLE_GEM) and not existing_gems.is_empty():
		candidates.append(Vector2(maxf(80.0, existing_gems[0].x - 75.0), 182.0))
	candidates.append_array([Vector2(140.0, 184.0), Vector2(240.0, 178.0), Vector2(315.0, 176.0), Vector2(405.0, 180.0)])

	for cand in candidates:
		var clear := true
		for hp in existing_hazards:
			if absf(cand.x - hp.x) < 42.0 and absf(cand.y - hp.y) < 34.0:
				clear = false
				break
		if clear:
			for gp in existing_gems:
				if cand.distance_to(gp) < 26.0:
					clear = false
					break
		if clear:
			return cand
	return Vector2(240.0, 176.0)

func _clear_tutorial_lane_hazards() -> void:
	if _tut_target_node and is_instance_valid(_tut_target_node):
		_tut_target_node.queue_free()
	_tut_target_node = null
	if _tut_extra_node and is_instance_valid(_tut_extra_node):
		_tut_extra_node.queue_free()
	_tut_extra_node = null
	if chunk_container == null:
		return
	var cutoff: float = player.global_position.x - 40.0
	for ch in chunk_container.get_children():
		if ch.is_in_group("hazards") or ch is BouncePad:
			if ch.global_position.x >= cutoff:
				ch.queue_free()
		for sub in ch.get_children():
			if (sub is Hazard or sub is BouncePad or sub.name.begins_with("Obstacle")) and sub.global_position.x >= cutoff:
				sub.queue_free()

func start_live_tutorial() -> void:
	tutorial_active = true
	skill_lab_active = false
	if player and player.skill_manager:
		player.skill_manager.skill_lab_infinite = false
	tutorial_phase = 0
	_tut_jump_hold_accum = 0.0
	_tut_short_jump_done = false
	_tut_long_jump_done = false
	_tut_slide_done = false
	_tut_bounce_done = false
	_tut_crawler_done = false
	_tut_hazard_done = false
	_tut_skill_done = false
	_tut_real_jump_triggered = false
	_tut_hit_current_obstacle = false
	_tut_phase_timer = 0.0
	_tut_celebrate_timer = 0.0
	_clear_tutorial_lane_hazards()
	if hud.practice_hub:
		hud.practice_hub.hide_practice_bar()
		hud.practice_hub.hide_adaptive_hint()
	_setup_tutorial_phase(0)

func _setup_tutorial_phase(phase: int) -> void:
	tutorial_phase = phase
	_tut_phase_timer = 0.0
	_tut_hit_current_obstacle = false
	_tut_jump_hold_accum = 0.0
	_tut_short_jump_done = false
	_tut_long_jump_done = false
	_tut_slide_done = false
	_tut_bounce_done = false
	_tut_crawler_done = false
	_tut_hazard_done = false
	_tut_skill_done = false
	_tut_real_jump_triggered = false
	if _tut_target_node and is_instance_valid(_tut_target_node):
		_tut_target_node.queue_free()
	_tut_target_node = null
	if _tut_extra_node and is_instance_valid(_tut_extra_node):
		_tut_extra_node.queue_free()
	_tut_extra_node = null
	if not hud.practice_hub:
		return
	match phase:
		0:
			hud.practice_hub.show_tutorial_step(
				"STEP 1/7 • TAP JUMP",
				"TAP Jump (Space / W / Bottom-Right) over spikes & cacti!",
				"TAP\nJUMP", Color(0.22, 0.65, 0.35), "Tap Jump to leap over the cactus!"
			)
			_tut_target_node = _spawn_tutorial_obstacle("res://scenes/obstacles/obstacle_ground_low.tscn", Vector2(player.global_position.x + 250.0, 230.0))
		1:
			hud.practice_hub.show_tutorial_step(
				"STEP 2/7 • HOLD HIGH JUMP",
				"HOLD Jump longer to climb over tall Crates & Boulders!",
				"HOLD\nJUMP", Color(0.25, 0.55, 0.92), "Hold Jump high over the crate!"
			)
			_tut_target_node = _spawn_tutorial_obstacle("res://scenes/obstacles/obstacle_crate_block.tscn", Vector2(player.global_position.x + 275.0, 230.0))
		2:
			hud.practice_hub.show_tutorial_step(
				"STEP 3/7 • SLIDE UNDER ARCHES",
				"Hold SLIDE (Down / S / Bottom-Left) to duck under Stone Arches & Icicles! Mid-air = Fast Dive!",
				"SLIDE\n▼", Color(0.85, 0.55, 0.2), "Slide underneath the stone arch!"
			)
			_tut_target_node = _spawn_tutorial_obstacle("res://scenes/obstacles/obstacle_overhang.tscn", Vector2(player.global_position.x + 275.0, 230.0))
		3:
			hud.practice_hub.show_tutorial_step(
				"STEP 4/7 • STOMP CRAWLERS",
				"Jump ON TOP of moving Crawlers to crush them, or leap clean over!",
				"STOMP\n⬇", Color(0.92, 0.42, 0.32), "Jump over or land on top to stomp!"
			)
			_tut_target_node = _spawn_tutorial_obstacle("res://scenes/obstacles/obstacle_crawler.tscn", Vector2(player.global_position.x + 275.0, 222.0))
		4:
			hud.practice_hub.show_tutorial_step(
				"STEP 5/7 • BOUNCE PADS & FLYERS",
				"Hit Bounce Pads to launch skyward, and watch for swooping Pterodactyls!",
				"BOUNCE\n▲", Color(0.72, 0.42, 0.92), "Bounce on the mushroom & clear the flyer!"
			)
			_tut_target_node = _spawn_tutorial_obstacle("res://scenes/objects/bounce_mushroom.tscn", Vector2(player.global_position.x + 240.0, 230.0))
			_tut_extra_node = _spawn_tutorial_obstacle("res://scenes/obstacles/obstacle_pterodactyl.tscn", Vector2(player.global_position.x + 365.0, 198.0))
		5:
			hud.practice_hub.show_tutorial_step(
				"STEP 6/7 • TRAPS & LAVA PITS",
				"Dodge glowing Hazard Triangles (Speed/Gravity/Glitch/Jam) & jump across Lava Pits!",
				"AVOID\n⚠", Color(0.96, 0.72, 0.14), "Jump over the lava & dodge traps!"
			)
			_tut_extra_node = _spawn_tutorial_obstacle("res://scenes/objects/trap_pickup.tscn", Vector2(player.global_position.x + 210.0, 148.0))
			_tut_target_node = _spawn_tutorial_obstacle("res://scenes/obstacles/hazard_lava_pit.tscn", Vector2(player.global_position.x + 310.0, 230.0))
		6:
			hud.practice_hub.show_tutorial_step(
				"STEP 7/7 • BREAKABLES & SKILLS",
				"Press SKILL (E / 1 / Skill Button) right before Wooden Barriers to smash through!",
				"SKILL\n⚡", Color(0.95, 0.72, 0.2), "Slash the wooden barrier with Bone Blade!"
			)
			if player.skill_manager:
				player.skill_manager.equip_skill(SkillManager.SkillType.BONE_BLADE)
			_tut_target_node = _spawn_tutorial_obstacle("res://scenes/obstacles/obstacle_wooden_barrier.tscn", Vector2(player.global_position.x + 280.0, 216.0))

func _spawn_tutorial_obstacle(scene_path: String, world_pos: Vector2) -> Node2D:
	if not ResourceLoader.exists(scene_path):
		return null
	var packed = load(scene_path) as PackedScene
	if not packed:
		return null
	var inst = packed.instantiate() as Node2D
	inst.position = world_pos
	chunk_container.add_child(inst)
	_wire_custom_node_recursive(inst)
	return inst

func _respawn_tutorial_target(scene_path: String, x_offset: float, y_pos: float, retry_hint: String) -> void:
	if _tut_target_node and is_instance_valid(_tut_target_node):
		_tut_target_node.queue_free()
	if _tut_extra_node and is_instance_valid(_tut_extra_node):
		_tut_extra_node.queue_free()
	_tut_extra_node = null
	_tut_hit_current_obstacle = false
	_tut_real_jump_triggered = false
	_tut_phase_timer = 0.0
	_tut_target_node = _spawn_tutorial_obstacle(scene_path, Vector2(player.global_position.x + x_offset, y_pos))
	if hud.practice_hub:
		hud.practice_hub.update_tutorial_status(retry_hint, false)

func _update_live_tutorial(delta: float) -> void:
	if _tut_celebrate_timer > 0.0:
		_tut_celebrate_timer -= delta
		if _tut_celebrate_timer <= 0.0:
			if tutorial_phase < 6:
				_setup_tutorial_phase(tutorial_phase + 1)
			else:
				_finish_live_tutorial()
		return
	_tut_phase_timer += delta
	var target_valid := _tut_target_node != null and is_instance_valid(_tut_target_node)
	var target_x: float = _tut_target_node.global_position.x if target_valid else (player.global_position.x + 100.0)
	var passed_target: bool = target_valid and (player.global_position.x > target_x + 30.0)

	match tutorial_phase:
		0:
			# Require an ACTUAL jump triggered by player input (never auto-pass on spawn)
			if _tut_real_jump_triggered and player.state_machine.current_state in [PlayerStateMachine.State.JUMP_RISE, PlayerStateMachine.State.JUMP_APEX, PlayerStateMachine.State.JUMP_FALL]:
				_tut_short_jump_done = true
			if passed_target:
				if _tut_short_jump_done and not _tut_hit_current_obstacle:
					_advance_tutorial_phase()
				else:
					_tut_short_jump_done = false
					_respawn_tutorial_target("res://scenes/obstacles/obstacle_ground_low.tscn", 260.0, 230.0, "You must tap JUMP to leap over the cactus!")
		1:
			if _tut_real_jump_triggered and (player.is_jump_holding or Input.is_action_pressed("jump") or player.jump_held):
				_tut_jump_hold_accum += delta
			if _tut_real_jump_triggered and player.state_machine.current_state in [PlayerStateMachine.State.JUMP_RISE, PlayerStateMachine.State.JUMP_APEX] and _tut_jump_hold_accum >= 0.08:
				_tut_long_jump_done = true
			if passed_target:
				if _tut_long_jump_done and not _tut_hit_current_obstacle:
					_advance_tutorial_phase()
				else:
					_tut_long_jump_done = false
					_tut_jump_hold_accum = 0.0
					_respawn_tutorial_target("res://scenes/obstacles/obstacle_crate_block.tscn", 280.0, 230.0, "Hold JUMP longer to soar high over the crate!")
		2:
			if player.state_machine.current_state in [PlayerStateMachine.State.SLIDE, PlayerStateMachine.State.DIVE]:
				_tut_slide_done = true
			if passed_target:
				if _tut_slide_done and not _tut_hit_current_obstacle:
					_advance_tutorial_phase()
				else:
					_tut_slide_done = false
					_respawn_tutorial_target("res://scenes/obstacles/obstacle_overhang.tscn", 280.0, 230.0, "Hold SLIDE (Down / Bottom-Left) under the stone arch!")
		3:
			if _tut_real_jump_triggered:
				_tut_crawler_done = true
			var stomped: bool = (not target_valid) or (_tut_target_node is Hazard and (_tut_target_node as Hazard).is_destroyed)
			if stomped or (passed_target and _tut_crawler_done and not _tut_hit_current_obstacle):
				_advance_tutorial_phase()
			elif passed_target:
				_tut_crawler_done = false
				_respawn_tutorial_target("res://scenes/obstacles/obstacle_crawler.tscn", 275.0, 222.0, "Jump onto the Crawler to stomp or clear it!")
		4:
			var past_both: bool = player.global_position.x > ((_tut_extra_node.global_position.x if _tut_extra_node and is_instance_valid(_tut_extra_node) else target_x) + 32.0)
			if _tut_bounce_done and _tut_phase_timer > 0.35 and not _tut_hit_current_obstacle:
				_advance_tutorial_phase()
			elif past_both:
				_tut_bounce_done = false
				_respawn_tutorial_target("res://scenes/objects/bounce_mushroom.tscn", 240.0, 230.0, "Hit the Bounce Pad and avoid the Pterodactyl!")
				_tut_extra_node = _spawn_tutorial_obstacle("res://scenes/obstacles/obstacle_pterodactyl.tscn", Vector2(player.global_position.x + 365.0, 198.0))
		5:
			if _tut_real_jump_triggered and player.trap_debuff_timer <= 0.0 and not _tut_hit_current_obstacle:
				_tut_hazard_done = true
			if passed_target:
				if _tut_hazard_done and player.trap_debuff_timer <= 0.0 and not _tut_hit_current_obstacle:
					_advance_tutorial_phase()
				else:
					_tut_hazard_done = false
					player.trap_debuff_timer = 0.0
					_respawn_tutorial_target("res://scenes/obstacles/hazard_lava_pit.tscn", 300.0, 230.0, "Jump cleanly over the Lava Pit & dodge the Triangle Trap!")
					_tut_extra_node = _spawn_tutorial_obstacle("res://scenes/objects/trap_pickup.tscn", Vector2(player.global_position.x + 210.0, 148.0))
		6:
			var barrier_broken: bool = (not target_valid) or (_tut_target_node is Hazard and (_tut_target_node as Hazard).is_destroyed)
			if barrier_broken:
				_tut_skill_done = true
				_advance_tutorial_phase()
			elif player.skill_manager and player.skill_manager.current_charges == 0 and player.skill_manager.cooldown_timer <= 0.0 and player.global_position.x < target_x - 24.0:
				player.skill_manager.equip_skill(SkillManager.SkillType.BONE_BLADE)
			elif passed_target:
				if player.skill_manager:
					player.skill_manager.equip_skill(SkillManager.SkillType.BONE_BLADE)
				_tut_skill_done = false
				_respawn_tutorial_target("res://scenes/obstacles/obstacle_wooden_barrier.tscn", 280.0, 216.0, "Press SKILL [E] right in front of the barrier!")

func _advance_tutorial_phase() -> void:
	if hud.practice_hub:
		hud.practice_hub.update_tutorial_status("✔ Great job!", true)
	_tut_celebrate_timer = 0.65

func _finish_live_tutorial() -> void:
	tutorial_active = false
	if save_service and not save_service.is_first_launch_completed():
		save_service.set_first_launch_completed(true)
	if hud.practice_hub:
		hud.practice_hub.hide_tutorial_banner()
		hud.practice_hub.show_practice_bar("🛡 PRACTICE • TUTORIAL DONE!")
		hud.practice_hub.show_adaptive_hint("Tutorial complete! Open Skills Lab to test all 12 skills & pick map spawns!", 5.0)

func _on_practice_hit_absorbed(cause: String, hazard: Hazard) -> void:
	audio_manager.play_shield_break()
	if fx_manager:
		fx_manager.spawn_floating_text(player.global_position + Vector2(0, -18), "NO DEATH!", Color(0.55, 0.95, 1.0), 1.0)
	if tutorial_active:
		_tut_hit_current_obstacle = true
		if hud.practice_hub:
			hud.practice_hub.update_tutorial_status("Oops! Missed timing — spawning another!", false)
		return
	# Adaptive Hint tracking strictly in Practice & Tutorial mode only (never in normal modes)
	if current_mode != 3 or custom_map_active or skill_lab_active:
		return
	var h_key := _classify_practice_hit(cause, hazard)
	_practice_pattern_hits[h_key] = int(_practice_pattern_hits.get(h_key, 0)) + 1
	if int(_practice_pattern_hits[h_key]) >= 2 and hud.practice_hub:
		hud.practice_hub.show_adaptive_hint(_get_adaptive_hint_for_key(h_key), 6.0)

func _classify_practice_hit(cause: String, hazard: Hazard) -> String:
	var c := cause.to_lower()
	if is_instance_valid(hazard):
		c = (c + " " + hazard.hazard_name.to_lower())
	if c.contains("overhang") or c.contains("arch"):
		return "overhang"
	if c.contains("crate"):
		return "crate_step"
	if c.contains("pterodactyl") or c.contains("fly") or c.contains("cloud"):
		return "airborne"
	if c.contains("lava"):
		return "lava"
	if c.contains("crawler"):
		return "crawler"
	return "cactus"

func _get_adaptive_hint_for_key(key: String) -> String:
	match key:
		"overhang":
			return "Stone Arch: Slide/Duck early before reaching it, or dive mid-air to drop underneath!"
		"crate_step":
			return "Crate + Cactus: A light tap hits the cactus after; HOLD Jump to clear both, or land on the crate first!"
		"airborne":
			return "Flying Hazard: Stay low and slide underneath, or hit it with Boomerang / Shockwave Roar!"
		"lava":
			return "Lava Pit: Hold Jump for a full arc, or use Bounce Pads / Air Dash to cross safely!"
		"crawler":
			return "Crawler: Jump clean over it, or smash it with Ground Slam / Boomerang!"
		_:
			return "Cactus Timing: Tap Jump for a single cactus, or HOLD Jump longer to clear wide doubles/triples!"

func _on_practice_modal_opened() -> void:
	if is_game_started and not is_game_over and not is_paused:
		get_tree().paused = true

func _on_practice_modal_closed() -> void:
	if is_game_started and not is_game_over and not is_paused and not _practice_entry_pending:
		get_tree().paused = false

func _on_test_skill_requested(skill_id: int) -> void:
	_practice_entry_pending = false
	tutorial_active = false
	custom_map_active = false
	practice_section_index = -1
	skill_lab_active = true
	skill_lab_skill_id = skill_id
	get_tree().paused = false
	is_paused = false
	if current_mode != 3:
		hud.select_mode(3)
		current_mode = 3
	start_new_run()
	if player.skill_manager:
		player.skill_manager.skill_lab_infinite = true
		player.skill_manager.clear_skill()
		player.skill_manager.equip_skill(skill_id as SkillManager.SkillType)
	_skill_lab_next_wave_x = player.global_position.x + 220.0
	_update_skill_lab_arena()
	var s_name := str(SkillManager.SKILL_DATA.get(skill_id, {}).get("name", "Skill"))
	if hud.practice_hub:
		hud.practice_hub.show_practice_bar("🧪 SKILL LAB: %s (∞ INFINITE USES)" % s_name.to_upper())
		hud.practice_hub.show_adaptive_hint("Test %s infinitely on matching targets ahead! It never runs out here." % s_name, 5.0)

func _update_skill_lab_arena() -> void:
	if not skill_lab_active or player == null or chunk_container == null:
		return
	while _skill_lab_next_wave_x < player.global_position.x + 760.0:
		var bx := _skill_lab_next_wave_x
		match skill_lab_skill_id:
			SkillManager.SkillType.BONE_BLADE:
				_spawn_tutorial_obstacle("res://scenes/obstacles/obstacle_wooden_barrier.tscn", Vector2(bx, 216.0))
				_spawn_tutorial_obstacle("res://scenes/obstacles/obstacle_wooden_barrier.tscn", Vector2(bx + 150.0, 216.0))
			SkillManager.SkillType.SHOCKWAVE_ROAR:
				_spawn_tutorial_obstacle("res://scenes/obstacles/obstacle_wooden_barrier.tscn", Vector2(bx, 216.0))
				_spawn_tutorial_obstacle("res://scenes/obstacles/obstacle_crawler.tscn", Vector2(bx + 70.0, 222.0))
				_spawn_tutorial_obstacle("res://scenes/obstacles/obstacle_pterodactyl.tscn", Vector2(bx + 115.0, 186.0))
			SkillManager.SkillType.BOOMERANG:
				_spawn_tutorial_obstacle("res://scenes/obstacles/obstacle_pterodactyl.tscn", Vector2(bx + 40.0, 188.0))
				_spawn_tutorial_obstacle("res://scenes/obstacles/obstacle_crawler.tscn", Vector2(bx + 150.0, 222.0))
			SkillManager.SkillType.GROUND_SLAM:
				_spawn_tutorial_obstacle("res://scenes/objects/bounce_mushroom.tscn", Vector2(bx - 55.0, 230.0))
				_spawn_tutorial_obstacle("res://scenes/obstacles/obstacle_crawler.tscn", Vector2(bx + 45.0, 222.0))
				_spawn_tutorial_obstacle("res://scenes/obstacles/obstacle_crate_block.tscn", Vector2(bx + 100.0, 230.0))
			SkillManager.SkillType.AIR_DASH, SkillManager.SkillType.FEATHER_FALL, SkillManager.SkillType.PHOENIX_WINGS:
				_spawn_tutorial_obstacle("res://scenes/obstacles/hazard_lava_pit.tscn", Vector2(bx + 20.0, 230.0))
				_spawn_tutorial_obstacle("res://scenes/objects/platform_one_way.tscn", Vector2(bx + 90.0, 175.0))
				_spawn_tutorial_obstacle("res://scenes/obstacles/obstacle_ground_low.tscn", Vector2(bx + 175.0, 230.0))
			SkillManager.SkillType.BOUNCE_POWER:
				_spawn_tutorial_obstacle("res://scenes/objects/bounce_mushroom.tscn", Vector2(bx, 230.0))
				_spawn_tutorial_obstacle("res://scenes/objects/platform_one_way.tscn", Vector2(bx + 110.0, 145.0))
				for gi in range(3):
					_spawn_tutorial_obstacle("res://scenes/objects/collectible_gem.tscn", Vector2(bx + 75.0 + float(gi * 28), 118.0))
			SkillManager.SkillType.MAGNET_RELIC, SkillManager.SkillType.DOUBLE_GEM:
				for gi in range(5):
					_spawn_tutorial_obstacle("res://scenes/objects/collectible_gem.tscn", Vector2(bx + float(gi * 28), 140.0 if (gi % 2 == 0) else 196.0))
			SkillManager.SkillType.STONE_SHIELD:
				_spawn_tutorial_obstacle("res://scenes/obstacles/obstacle_ground_low.tscn", Vector2(bx, 230.0))
				_spawn_tutorial_obstacle("res://scenes/obstacles/obstacle_crawler.tscn", Vector2(bx + 140.0, 222.0))
			SkillManager.SkillType.TIME_SHARD:
				_spawn_tutorial_obstacle("res://scenes/obstacles/obstacle_ground_low.tscn", Vector2(bx, 230.0))
				_spawn_tutorial_obstacle("res://scenes/obstacles/obstacle_pterodactyl.tscn", Vector2(bx + 120.0, 186.0))
				_spawn_tutorial_obstacle("res://scenes/obstacles/obstacle_overhang.tscn", Vector2(bx + 230.0, 230.0))
			_:
				_spawn_tutorial_obstacle("res://scenes/obstacles/obstacle_wooden_barrier.tscn", Vector2(bx, 216.0))
		_skill_lab_next_wave_x += 340.0

func _on_section_practice_requested(chunk_idx: int, section_name: String) -> void:
	_practice_entry_pending = false
	tutorial_active = false
	custom_map_active = false
	practice_section_index = chunk_idx
	_practice_section_counter = 0
	get_tree().paused = false
	is_paused = false
	if current_mode != 3:
		hud.select_mode(3)
		current_mode = 3
	start_new_run()
	if hud.practice_hub:
		hud.practice_hub.show_practice_bar("🎯 SECTION: %s" % section_name.to_upper())

func _on_random_practice_requested() -> void:
	_practice_entry_pending = false
	tutorial_active = false
	custom_map_active = false
	practice_section_index = -1
	get_tree().paused = false
	is_paused = false
	if current_mode != 3:
		hud.select_mode(3)
		current_mode = 3
	start_new_run()
	if hud.practice_hub:
		hud.practice_hub.show_practice_bar("🛡 FREE PRACTICE • NO DEATH • NO SCORE")

func start_custom_map(map_dict: Dictionary) -> void:
	_practice_entry_pending = false
	tutorial_active = false
	skill_lab_active = false
	if player and player.skill_manager:
		player.skill_manager.skill_lab_infinite = false
	practice_section_index = -1
	custom_map_active = true
	custom_map_data = map_dict.duplicate(true)
	# Build linked custom map chain following linked_next_id cleanly (no cycles)
	custom_map_chain = [custom_map_data]
	if save_service:
		var all_maps := save_service.get_custom_maps()
		var by_id: Dictionary = {}
		for m in all_maps:
			by_id[str(m.get("id", ""))] = m
		var seen: Array[String] = [str(custom_map_data.get("id", ""))]
		var next_id: String = str(custom_map_data.get("linked_next_id", ""))
		while not next_id.is_empty() and by_id.has(next_id) and not seen.has(next_id) and custom_map_chain.size() < 10:
			seen.append(next_id)
			var nm: Dictionary = by_id[next_id].duplicate(true)
			custom_map_chain.append(nm)
			next_id = str(nm.get("linked_next_id", ""))
	get_tree().paused = false
	is_paused = false
	if current_mode != 3:
		hud.select_mode(3)
		current_mode = 3
	start_new_run()
	if hud.practice_hub:
		var chain_suffix: String = (" (+%d LINKED)" % (custom_map_chain.size() - 1)) if custom_map_chain.size() > 1 else ""
		hud.practice_hub.show_practice_bar("🛠 CUSTOM MAP: %s%s" % [str(custom_map_data.get("name", "Custom")).to_upper(), chain_suffix])

func _populate_custom_map_items() -> void:
	var w_idx: int = clampi(int(custom_map_data.get("world_index", 0)), 0, world_themes.size() - 1)
	if w_idx >= 0 and w_idx < world_themes.size() and world_themes[w_idx] != null:
		current_world_index = w_idx
		if parallax_bg:
			parallax_bg.apply_theme_immediate(world_themes[w_idx])
		hud.update_world_name(world_themes[w_idx].world_name)

	for c in chunk_container.get_children():
		chunk_container.remove_child(c)
		c.queue_free()
	chunk_pool.clear()
	next_chunk_x = 0.0

	var chain_list: Array = custom_map_chain if not custom_map_chain.is_empty() else [custom_map_data]
	var total_span: float = 0.0
	for m in chain_list:
		total_span += maxf(960.0, float(m.get("length_px", 1800.0)))
	var num_chunks: int = maxi(8, int(ceilf(total_span / CHUNK_WIDTH)) + 3)
	for _i in range(num_chunks):
		_spawn_chunk_by_index(0, false)

	var item_scenes: Dictionary = {
		"cactus": "res://scenes/obstacles/obstacle_ground_low.tscn",
		"overhang": "res://scenes/obstacles/obstacle_overhang.tscn",
		"crate": "res://scenes/obstacles/obstacle_crate_block.tscn",
		"barrier": "res://scenes/obstacles/obstacle_wooden_barrier.tscn",
		"crawler": "res://scenes/obstacles/obstacle_crawler.tscn",
		"flyer": "res://scenes/obstacles/obstacle_pterodactyl.tscn",
		"lava": "res://scenes/obstacles/hazard_lava_pit.tscn",
		"trap": "res://scenes/objects/trap_pickup.tscn",
		"platform": "res://scenes/objects/platform_one_way.tscn",
		"bounce": "res://scenes/objects/bounce_mushroom.tscn",
		"wind": "res://scenes/objects/boost_wind_vent.tscn",
		"gem": "res://scenes/objects/collectible_gem.tscn",
		"skill": "res://scenes/objects/skill_pickup.tscn"
	}
	var base_offset_x: float = 0.0
	for map_entry in chain_list:
		for it in map_entry.get("items", []):
			if typeof(it) != TYPE_DICTIONARY:
				continue
			var t: String = str(it.get("type", "cactus"))
			var path: String = item_scenes.get(t, "")
			if path != "" and ResourceLoader.exists(path):
				var sc = load(path) as PackedScene
				if sc:
					var node = sc.instantiate() as Node2D
					node.position = Vector2(base_offset_x + float(it.get("x", 300.0)), float(it.get("y", 216.0)))
					chunk_container.add_child(node)
					_wire_custom_node_recursive(node)
		base_offset_x += maxf(960.0, float(map_entry.get("length_px", 1800.0))) - 120.0

func _wire_custom_node_recursive(root_node: Node) -> void:
	var stack: Array[Node] = [root_node]
	while not stack.is_empty():
		var cur = stack.pop_back()
		for ch in cur.get_children():
			stack.append(ch)
		if cur is Hazard and not cur.destroyed.is_connected(_on_hazard_destroyed):
			cur.destroyed.connect(_on_hazard_destroyed)
		elif cur is BouncePad:
			var pad := cur as BouncePad
			if not pad.launched.is_connected(_on_bounce_pad_triggered):
				pad.launched.connect(_on_bounce_pad_triggered.bind(pad))
