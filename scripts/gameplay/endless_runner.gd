class_name EndlessRunner
extends Node2D

const ChallengeService = preload("res://scripts/systems/challenge_service.gd")
const LevelGenerator = preload("res://scripts/world/level_generator.gd")
const LevelPattern = preload("res://scripts/world/level_pattern.gd")

@onready var player: Player = $Player
@onready var camera: GameCamera = $GameCamera
@onready var hud: GameHUD = $GameHUD
@onready var chunk_container: Node2D = $ChunkContainer
@onready var parallax_bg = get_node_or_null("ParallaxBackground")

var save_service: SaveService
var challenge_service: ChallengeService
var is_game_over: bool = false
var is_paused: bool = false
var is_game_started: bool = false
var current_mode: int = 1 # 0 = Casual, 1 = Runner, 2 = Freestyle

# Session 7 World Themes & Transitions
var world_themes: Array[WorldTheme] = []
var current_world_index: int = 0
var next_transition_distance_m: float = 250.0

var start_x: float = 100.0
var distance_px: float = 0.0
var distance_m: float = 0.0
var current_score: int = 0
var next_chunk_x: float = 0.0

var chunk_scenes: Array[PackedScene] = []
var chunk_pool: Array[Node2D] = []
const CHUNK_WIDTH: float = 480.0

# Session 8 Level Generator & Deterministic Seeding
var level_generator: LevelGenerator = LevelGenerator.new()
var run_seed: int = 0

func _ready() -> void:
	save_service = SaveService.new()
	challenge_service = ChallengeService.new(save_service)
	hud.bind_services(save_service, challenge_service)

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
	hud.skill_requested.connect(_on_hud_skill)
	hud.flight_up_requested.connect(func(p): player.flight_up_input = p)
	hud.flight_down_requested.connect(func(p): player.flight_down_input = p)

	# Connect Player signals
	player.died.connect(_on_player_died)
	player.jumped.connect(_on_player_jumped)
	player.gem_collected.connect(_on_player_gem_collected)
	player.flight_started.connect(func(t, d): hud.show_flight_hud(t, d))
	player.flight_time_updated.connect(func(r, tot): hud.update_flight_timer(r, tot))
	player.flight_ended.connect(func(): hud.hide_flight_hud())

	if player.skill_manager:
		player.skill_manager.skill_equipped.connect(_on_skill_equipped)
		player.skill_manager.skill_replaced.connect(_on_skill_replaced)
		player.skill_manager.skill_updated.connect(_on_skill_updated)

	# Apply initial skin
	player.set_skin(save_service.get_equipped_skin())

	# Load world themes
	world_themes = [
		load("res://resources/themes/theme_01_plains.tres"),
		load("res://resources/themes/theme_02_jungle.tres"),
		load("res://resources/themes/theme_03_frozen.tres"),
		load("res://resources/themes/theme_04_volcanic.tres")
	]

	init_title_screen()

func _on_mode_selected(mode: int) -> void:
	current_mode = mode

func _apply_mode_settings() -> void:
	match current_mode:
		0: # Arcade Jump (Spicy): fast opening speed, pure jump focus
			player.is_steer_enabled = false
			player.current_speed = 310.0
		1: # Runner: accelerating speed, jump & slide
			player.is_steer_enabled = false
			player.current_speed = 280.0
		2: # Freestyle: steering enabled
			player.is_steer_enabled = true
			player.current_speed = 280.0

func init_title_screen() -> void:
	is_game_started = false
	is_game_over = false
	is_paused = false
	get_tree().paused = false

	# Disable physics on player and chunk container so dino is 100% frozen in title screen
	player.set_physics_process(false)
	chunk_container.process_mode = Node.PROCESS_MODE_DISABLED

	# Setup initial safe chunks
	_reset_world_state()

	# Put player in idle breathing pose at start line
	player.reset()
	player.state_machine.change_state(PlayerStateMachine.State.IDLE)
	player.set_skin(save_service.get_equipped_skin())

	hud.show_start_menu(save_service.get_best_score(), save_service.get_points())
	hud.update_hud(0, 0.0, save_service.get_best_score(), save_service.get_points())

func begin_run() -> void:
	if is_game_started:
		return
	is_game_started = true
	hud.hide_start_menu()

	# Re-enable physics
	player.set_physics_process(true)
	chunk_container.process_mode = Node.PROCESS_MODE_PAUSABLE

	_apply_mode_settings()
	player.state_machine.change_state(PlayerStateMachine.State.RUN)

func start_new_run() -> void:
	is_game_over = false
	is_paused = false
	is_game_started = true
	get_tree().paused = false
	hud.hide_game_over()
	hud.hide_pause_menu()
	hud.hide_start_menu()

	player.set_physics_process(true)
	chunk_container.process_mode = Node.PROCESS_MODE_PAUSABLE

	_reset_world_state()

	# Reset player directly into RUN
	player.reset()
	_apply_mode_settings()

	hud.update_hud(0, 0.0, save_service.get_best_score(), save_service.get_points())

func _reset_world_state() -> void:
	# Immediately detach from scene tree to destroy all active colliders
	for c in chunk_container.get_children():
		chunk_container.remove_child(c)
		c.queue_free()
	chunk_pool.clear()

	# Reset player position
	start_x = 100.0
	player.position = Vector2(start_x, 216.0)
	if camera:
		camera.global_position.x = roundf(player.global_position.x + camera.horizontal_lead)

	next_chunk_x = 0.0
	distance_px = 0.0
	distance_m = 0.0
	current_score = 0
	hud.update_gems(0)
	hud.update_skill_slot({}, 0.0, 0.0, 0)
	hud.hide_flight_hud()

	# Reset world theme to World 1 (Plains)
	current_world_index = 0
	if not world_themes.is_empty():
		var t0 = world_themes[0]
		next_transition_distance_m = t0.transition_distance_m
		if parallax_bg:
			parallax_bg.apply_theme_immediate(t0)
		hud.update_world_name(t0.world_name)

	# Initialize deterministic generator seed
	if run_seed == 0:
		run_seed = int(Time.get_ticks_msec() % 900000 + 100000)
	level_generator.set_seed(run_seed)
	hud.update_seed(run_seed)

	# Spawn initial safe chunks: 0..960px is 100% open, guaranteed safe runway!
	_spawn_chunk_by_index(0) # Chunk 1: Safe runway (0 to 480)
	_spawn_chunk_by_index(0) # Chunk 2: Safe runway (480 to 960)
	_spawn_chunk_by_index(1) # Chunk 3: First low hurdle (960 to 1440)

func _physics_process(_delta: float) -> void:
	if not is_game_started or is_game_over or is_paused:
		return

	# Calculate distance & score
	distance_px = maxf(player.global_position.x - start_x, 0.0)
	distance_m = distance_px * 0.1 # 10 px = 1 meter
	current_score = int(distance_m * 1.5)

	# Dynamic speed progression based on difficulty mode
	match current_mode:
		0: # Arcade Jump (Spicy): fast, escalating jump challenge!
			player.current_speed = minf(310.0 + (distance_m * 0.25), 520.0)
		1: # Runner: fast, exciting acceleration curve with jump & slide!
			player.current_speed = minf(280.0 + (distance_m * 0.22), 520.0)
		2: # Freestyle: high speed with manual air control & steering
			player.current_speed = minf(280.0 + (distance_m * 0.20), 520.0)

	if challenge_service:
		challenge_service.check_run_progress(distance_m, current_score, current_mode)

	# Check World Transition
	if distance_m >= next_transition_distance_m and current_world_index < world_themes.size() - 1:
		_trigger_world_transition()

	hud.update_hud(current_score, distance_m, save_service.get_best_score(), save_service.get_points())

	# Spawn chunks ahead
	if player.global_position.x + CHUNK_WIDTH * 2.0 > next_chunk_x:
		_spawn_next_procedural_chunk()

	# Despawn distant chunks behind player
	_cleanup_chunks_behind(player.global_position.x - 600.0)

func _unhandled_input(event: InputEvent) -> void:
	if not is_game_started:
		if event.is_action_pressed("jump") or event.is_action_pressed("ui_accept"):
			begin_run()
		return

	if event.is_action_pressed("pause"):
		toggle_pause()
	elif event.is_action_pressed("jump") and is_game_over:
		restart_run()

func _spawn_chunk_by_index(idx: int) -> void:
	var scene = chunk_scenes[idx % chunk_scenes.size()]
	var chunk = scene.instantiate() as Node2D
	chunk.position = Vector2(next_chunk_x, 0.0)
	chunk_container.add_child(chunk)
	chunk_pool.append(chunk)
	next_chunk_x += CHUNK_WIDTH

func _spawn_next_procedural_chunk() -> void:
	var world_id = "plains"
	if current_world_index < world_themes.size() and world_themes[current_world_index] != null:
		world_id = world_themes[current_world_index].world_id

	var pat = level_generator.select_next_pattern(distance_m, player.current_speed, world_id)
	if pat == null:
		_spawn_chunk_by_index(0)
		return

	var scene = load(pat.chunk_scene_path) as PackedScene
	if scene == null:
		_spawn_chunk_by_index(0)
		return

	var chunk = scene.instantiate() as Node2D
	chunk.position = Vector2(next_chunk_x, 0.0)
	chunk_container.add_child(chunk)
	chunk_pool.append(chunk)
	next_chunk_x += pat.chunk_width

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

	var run_pts: int = int(distance_m * 0.5) + int(current_score * 0.1)
	if run_pts < 1 and distance_m > 5.0:
		run_pts = 1
	save_service.add_points(run_pts)
	var is_new_best = save_service.update_high_score(current_score, distance_m)
	hud.show_game_over(cause, current_score, distance_m, save_service.get_best_score(), is_new_best, run_pts, save_service.get_points())

func toggle_pause() -> void:
	if is_game_over or not is_game_started:
		return
	if is_paused:
		resume_game()
	else:
		pause_game()

func pause_game() -> void:
	is_paused = true
	get_tree().paused = true
	hud.show_pause_menu()

func resume_game() -> void:
	is_paused = false
	get_tree().paused = false
	hud.hide_pause_menu()

func restart_run() -> void:
	start_new_run()

func go_to_title_menu() -> void:
	hud.hide_pause_menu()
	hud.hide_game_over()
	init_title_screen()

func _on_player_jumped() -> void:
	if challenge_service:
		challenge_service.record_jump()

func _on_skin_selected(skin_id: String) -> void:
	player.set_skin(skin_id)

func _on_hud_jump(pressed: bool) -> void:
	if not is_game_started:
		if pressed:
			begin_run()
		return
	if is_game_over or is_paused:
		return
	player.jump_held = pressed
	if pressed and player.is_on_floor():
		player._execute_jump()

func _on_hud_slide(pressed: bool) -> void:
	if not is_game_started or is_game_over or is_paused:
		return
	player.slide_held = pressed
	if pressed:
		if challenge_service:
			challenge_service.record_slide()
		if player.is_on_floor():
			if player.state_machine.current_state != PlayerStateMachine.State.SLIDE:
				player._enter_slide()
		else:
			# Mid-air slide executes a fast downward dive
			player.state_machine.change_state(PlayerStateMachine.State.DIVE)
			player.velocity.y = player.config.dive_velocity

func _on_hud_steer(dir: float) -> void:
	if is_game_started and not is_game_over and not is_paused:
		player.steer_input = dir

func _on_hud_skill() -> void:
	if not is_game_started or is_game_over or is_paused:
		return
	player.use_skill()

func _on_player_gem_collected(count: int, bonus: int) -> void:
	current_score += bonus
	hud.update_gems(count)
	save_service.add_points(1)

func _on_skill_equipped(_type: int, info: Dictionary) -> void:
	hud.update_skill_slot(info, 0.0, 0.0, player.skill_manager.current_charges)
	hud.show_skill_toast("%s Equipped!" % info.get("name", "Skill"))

func _on_skill_replaced(old_name: String, new_name: String) -> void:
	hud.show_skill_toast("Replaced %s with %s!" % [old_name, new_name])

func _on_skill_updated(cd: float, dur: float, charges: int) -> void:
	hud.update_skill_status(cd, dur, charges)

# --- Session 7 World Transitions ---

func _trigger_world_transition() -> void:
	current_world_index += 1
	if current_world_index >= world_themes.size():
		return
	var new_theme = world_themes[current_world_index]
	next_transition_distance_m = new_theme.transition_distance_m

	# 1. Spawn safe transition runway ahead (zero hazards, safe landing area)
	var pat = level_generator.get_world_transition_pattern()
	var trans_scene = preload("res://scenes/obstacles/chunks/chunk_00_world_transition.tscn")
	var trans_chunk = trans_scene.instantiate() as Node2D
	trans_chunk.position = Vector2(next_chunk_x, 0.0)
	chunk_container.add_child(trans_chunk)
	chunk_pool.append(trans_chunk)
	var w = pat.chunk_width if pat != null else CHUNK_WIDTH
	next_chunk_x += w

	# 2. Smooth cross-fade of parallax background over 1.5s
	if parallax_bg:
		parallax_bg.transition_to_theme(new_theme, 1.5)

	# 3. HUD announcement & label update
	hud.update_world_name(new_theme.world_name)
	hud.show_world_transition_card(new_theme.world_name, new_theme.mechanic_intro)
