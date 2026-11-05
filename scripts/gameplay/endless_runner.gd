class_name EndlessRunner
extends Node2D

@onready var player: Player = $Player
@onready var camera: GameCamera = $GameCamera
@onready var hud: GameHUD = $GameHUD
@onready var chunk_container: Node2D = $ChunkContainer

var save_service: SaveService
var is_game_over: bool = false
var is_paused: bool = false
var is_game_started: bool = false

var start_x: float = 100.0
var distance_px: float = 0.0
var distance_m: float = 0.0
var current_score: int = 0
var next_chunk_x: float = 0.0

var chunk_scenes: Array[PackedScene] = []
var chunk_pool: Array[Node2D] = []
const CHUNK_WIDTH: float = 480.0

func _ready() -> void:
	save_service = SaveService.new()

	# Load chunk scenes
	chunk_scenes = [
		preload("res://scenes/obstacles/chunks/chunk_01_empty.tscn"),
		preload("res://scenes/obstacles/chunks/chunk_02_single_low.tscn"),
		preload("res://scenes/obstacles/chunks/chunk_03_overhang.tscn"),
		preload("res://scenes/obstacles/chunks/chunk_04_double_low.tscn"),
		preload("res://scenes/obstacles/chunks/chunk_05_jump_and_slide.tscn")
	]

	# Connect HUD signals
	hud.start_requested.connect(begin_run)
	hud.jump_requested.connect(_on_hud_jump)
	hud.slide_requested.connect(_on_hud_slide)
	hud.pause_requested.connect(toggle_pause)
	hud.resume_requested.connect(resume_game)
	hud.retry_requested.connect(restart_run)

	# Connect Player signals
	player.died.connect(_on_player_died)

	init_title_screen()

func init_title_screen() -> void:
	is_game_started = false
	is_game_over = false
	is_paused = false
	get_tree().paused = false

	# Setup initial chunks
	_reset_world_state()

	# Put player in idle breathing pose at start
	player.reset()
	player.state_machine.change_state(PlayerStateMachine.State.IDLE)

	hud.show_start_menu(save_service.get_best_score())
	hud.update_hud(0, 0.0, save_service.get_best_score())

func begin_run() -> void:
	if is_game_started:
		return
	is_game_started = true
	hud.hide_start_menu()
	player.state_machine.change_state(PlayerStateMachine.State.RUN)

func start_new_run() -> void:
	is_game_over = false
	is_paused = false
	is_game_started = true
	get_tree().paused = false
	hud.hide_game_over()
	hud.hide_pause_menu()
	hud.hide_start_menu()

	_reset_world_state()

	# Reset player directly into RUN
	player.reset()

	hud.update_hud(0, 0.0, save_service.get_best_score())

func _reset_world_state() -> void:
	# Clear previous chunks
	for c in chunk_container.get_children():
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

	# Spawn initial safe chunks
	_spawn_chunk_by_index(0) # Chunk 1: Empty starter
	_spawn_chunk_by_index(1) # Chunk 2: Single low
	_spawn_chunk_by_index(2) # Chunk 3: Overhang

func _physics_process(_delta: float) -> void:
	if not is_game_started or is_game_over or is_paused:
		return

	# Calculate distance & score
	distance_px = maxf(player.global_position.x - start_x, 0.0)
	distance_m = distance_px * 0.1 # 10 px = 1 meter
	current_score = int(distance_m * 1.5)

	hud.update_hud(current_score, distance_m, save_service.get_best_score())

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
	var chunk_idx: int
	if distance_m < 50.0:
		chunk_idx = randi() % 3 # 0, 1, 2
	elif distance_m < 150.0:
		chunk_idx = (randi() % 4) + 1 # 1, 2, 3, 4
	else:
		chunk_idx = (randi() % 3) + 2 # 2, 3, 4

	_spawn_chunk_by_index(chunk_idx)

func _cleanup_chunks_behind(cutoff_x: float) -> void:
	var remaining: Array[Node2D] = []
	for chunk in chunk_pool:
		if is_instance_valid(chunk):
			if chunk.position.x + CHUNK_WIDTH < cutoff_x:
				chunk.queue_free()
			else:
				remaining.append(chunk)
	chunk_pool = remaining

func _on_player_died(cause: String) -> void:
	if is_game_over:
		return
	is_game_over = true

	var is_new_best = save_service.update_high_score(current_score, distance_m)
	hud.show_game_over(cause, current_score, distance_m, save_service.get_best_score(), is_new_best)

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
	if pressed and player.state_machine.current_state != PlayerStateMachine.State.SLIDE:
		player._enter_slide()
