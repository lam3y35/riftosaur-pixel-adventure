class_name TestTrack
extends Node2D

@onready var player: Player = $Player
@onready var camera: GameCamera = $GameCamera
@onready var debug_label: Label = $CanvasLayer/DebugLabel
@onready var ground_container: Node2D = $GroundContainer
@onready var obstacle_container: Node2D = $ObstacleContainer

@export var autonomous_bot: bool = false

var ground_tile_tex: Texture2D
var obstacle_low_scene: PackedScene
var obstacle_high_scene: PackedScene

var next_ground_x: float = 0.0
var next_obstacle_x: float = 600.0
const CHUNK_WIDTH: float = 480.0
const GROUND_Y: float = 230.0

func _ready() -> void:
	ground_tile_tex = preload("res://assets/sprites/ground_tile.png")
	obstacle_low_scene = preload("res://scenes/obstacles/obstacle_ground_low.tscn")
	obstacle_high_scene = preload("res://scenes/obstacles/obstacle_overhang.tscn")

	# Initial ground generation
	for i in range(5):
		_spawn_ground_chunk()

	if player:
		player.position = Vector2(100, GROUND_Y - 14)
		player.died.connect(_on_player_died)

func _physics_process(delta: float) -> void:
	if player == null:
		return

	# Autonomous bot logic for endurance testing / L3 verification
	if autonomous_bot and player.state_machine.current_state != PlayerStateMachine.State.DEAD:
		_process_autonomous_pilot()

	# Generate ground chunks ahead of player
	if player.global_position.x + CHUNK_WIDTH * 2.0 > next_ground_x:
		_spawn_ground_chunk()

	# Generate test obstacles spaced with ample reaction window (> 400px at ~300px/s => > 1.3s)
	if player.global_position.x + CHUNK_WIDTH * 2.0 > next_obstacle_x:
		_spawn_obstacle()

	# Cleanup far behind chunks to keep memory bounded
	_cleanup_behind(player.global_position.x - 600.0)

	# Update debug overlay
	if debug_label and player.state_machine:
		debug_label.text = "State: %s | Speed: %.1f px/s | Dist: %.0f px | FPS: %d" % [
			player.state_machine.get_state_name(),
			player.current_speed,
			player.global_position.x,
			Engine.get_frames_per_second()
		]

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_tree().reload_current_scene()

func _spawn_ground_chunk() -> void:
	var body = StaticBody2D.new()
	body.collision_layer = 2
	body.collision_mask = 1
	body.position = Vector2(next_ground_x, GROUND_Y)

	# Collision
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(CHUNK_WIDTH, 40.0)
	shape.shape = rect
	shape.position = Vector2(CHUNK_WIDTH * 0.5, 20.0)
	body.add_child(shape)

	# Visual tiles (16x16)
	var tiles_count = int(CHUNK_WIDTH / 16.0)
	for i in range(tiles_count):
		var sp = Sprite2D.new()
		sp.texture = ground_tile_tex
		sp.position = Vector2(i * 16.0 + 8.0, 8.0)
		body.add_child(sp)

	ground_container.add_child(body)
	next_ground_x += CHUNK_WIDTH

func _spawn_obstacle() -> void:
	var is_low = (int(next_obstacle_x / 400.0) % 2) == 0
	var obs = obstacle_low_scene.instantiate() if is_low else obstacle_high_scene.instantiate()
	obs.position = Vector2(next_obstacle_x, GROUND_Y)
	obstacle_container.add_child(obs)
	next_obstacle_x += 450.0 # Spaced generously for reaction window

func _process_autonomous_pilot() -> void:
	var nearest_dist: float = 9999.0
	var nearest_obs: Node2D = null

	for obs in obstacle_container.get_children():
		if obs is Node2D:
			var d = obs.global_position.x - player.global_position.x
			if d > -40.0 and d < nearest_dist:
				nearest_dist = d
				nearest_obs = obs

	if nearest_obs != null:
		var is_overhang = nearest_obs.name.contains("Overhang") or nearest_obs.name.contains("High")
		if is_overhang:
			if nearest_dist > -30.0 and nearest_dist < 60.0:
				player.slide_held = true
				if player.state_machine.current_state != PlayerStateMachine.State.SLIDE:
					player._enter_slide()
			else:
				player.slide_held = false
		else:
			if nearest_dist > 15.0 and nearest_dist < 75.0:
				if player.is_on_floor() and player.state_machine.current_state != PlayerStateMachine.State.JUMP_RISE:
					player._execute_jump()
					player.jump_held = true
			elif nearest_dist <= 15.0:
				player.jump_held = false
	else:
		player.slide_held = false
		player.jump_held = false

func _cleanup_behind(cutoff_x: float) -> void:
	for c in ground_container.get_children():
		if c is Node2D and c.position.x + CHUNK_WIDTH < cutoff_x:
			c.queue_free()

	for obs in obstacle_container.get_children():
		if obs is Node2D and obs.position.x < cutoff_x:
			obs.queue_free()

func _on_player_died(cause: String = "Collision") -> void:
	print("[TestTrack] Dinosaur died (%s)! Restarting track in 1.0s..." % cause)
	get_tree().create_timer(1.0).timeout.connect(func():
		get_tree().reload_current_scene()
	)
