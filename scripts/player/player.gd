class_name Player
extends CharacterBody2D

signal state_changed(old_state: int, new_state: int)
signal jumped()
signal landed()
signal died()

@export var config: GameplayConfig

var state_machine: PlayerStateMachine = PlayerStateMachine.new()
var current_speed: float = 0.0
var jump_buffer_timer: float = 0.0
var coyote_timer: float = 0.0
var jump_hold_timer: float = 0.0
var is_jump_holding: bool = false
var jump_held: bool = false # Virtual/simulated hold flag for touch/tests
var slide_held: bool = false # Virtual/simulated slide hold flag for touch/tests
var slide_timer: float = 0.0
var run_anim_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var ceiling_ray: RayCast2D = $CeilingRay
@onready var ceiling_ray_back: RayCast2D = $CeilingRayBack

var box_shape: RectangleShape2D

func _init() -> void:
	state_machine.state_changed.connect(_on_state_machine_state_changed)
	state_machine.change_state(PlayerStateMachine.State.RUN)

func _ready() -> void:
	if config == null:
		config = load("res://resources/gameplay_config/gameplay_config.tres")
		if config == null:
			config = GameplayConfig.new()

	current_speed = config.opening_speed

	# Ensure separate instance of shape to avoid mutating shared resource
	if box_shape == null:
		box_shape = RectangleShape2D.new()
	box_shape.size = config.standing_extents * 2.0
	if collision_shape:
		collision_shape.shape = box_shape
		collision_shape.position = config.standing_offset

func _physics_process(delta: float) -> void:
	# Update timers
	_update_timers(delta)

	# Process state and inputs
	_process_state(delta)

	# Horizontal speed progression
	if state_machine.current_state != PlayerStateMachine.State.DEAD and state_machine.current_state != PlayerStateMachine.State.IDLE:
		current_speed = minf(current_speed + config.acceleration_rate * delta, config.speed_cap)
		velocity.x = current_speed
	else:
		velocity.x = 0.0

	# Apply physics movement
	move_and_slide()

	# Post-movement ground checks & state reconciliation
	_post_movement_check(delta)

	# Update visual presentation
	_update_presentation(delta)

func _update_timers(delta: float) -> void:
	state_machine.update(delta)

	if jump_buffer_timer > 0.0:
		jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)

	if is_on_floor():
		coyote_timer = config.coyote_time
	else:
		coyote_timer = maxf(coyote_timer - delta, 0.0)

func _process_state(delta: float) -> void:
	var state = state_machine.current_state

	if state == PlayerStateMachine.State.DEAD:
		velocity.y += config.gravity * delta
		return

	# Buffer jump input
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = config.jump_buffer_time

	# Jump release early
	var is_holding = Input.is_action_pressed("jump") or jump_held
	if Input.is_action_just_released("jump") and is_jump_holding:
		is_jump_holding = false
		if velocity.y < 0.0:
			velocity.y *= config.early_jump_release_multiplier

	match state:
		PlayerStateMachine.State.RUN, PlayerStateMachine.State.IDLE:
			_handle_ground_state(delta)

		PlayerStateMachine.State.JUMP_RISE:
			_handle_jump_rise_state(delta)

		PlayerStateMachine.State.JUMP_APEX:
			_handle_jump_apex_state(delta)

		PlayerStateMachine.State.JUMP_FALL:
			_handle_jump_fall_state(delta)

		PlayerStateMachine.State.LAND:
			_handle_land_state(delta)

		PlayerStateMachine.State.SLIDE:
			_handle_slide_state(delta)

		PlayerStateMachine.State.DIVE:
			_handle_dive_state(delta)

func _handle_ground_state(_delta: float) -> void:
	# Check for buffered or immediate jump
	if jump_buffer_timer > 0.0:
		_execute_jump()
		return

	# Check for slide
	if Input.is_action_pressed("slide"):
		_enter_slide()
		return

	# Check if walked off a ledge
	if not is_on_floor():
		state_machine.change_state(PlayerStateMachine.State.JUMP_FALL)

func _handle_jump_rise_state(delta: float) -> void:
	var is_holding = Input.is_action_pressed("jump") or jump_held
	# Variable jump hold boost
	if is_jump_holding and is_holding:
		jump_hold_timer += delta
		if jump_hold_timer < config.max_jump_hold_time:
			velocity.y -= config.jump_hold_force * delta
		else:
			is_jump_holding = false
	else:
		is_jump_holding = false

	# Apply gravity
	velocity.y += config.gravity * delta

	# Check for dive input
	if Input.is_action_just_pressed("slide"):
		state_machine.change_state(PlayerStateMachine.State.DIVE)
		return

	# Transition to apex when vertical speed nears peak
	if velocity.y >= -40.0:
		state_machine.change_state(PlayerStateMachine.State.JUMP_APEX)

func _handle_jump_apex_state(delta: float) -> void:
	velocity.y += config.gravity * 0.75 * delta # Slight float at apex

	if Input.is_action_just_pressed("slide"):
		state_machine.change_state(PlayerStateMachine.State.DIVE)
		return

	if velocity.y > 40.0:
		state_machine.change_state(PlayerStateMachine.State.JUMP_FALL)

func _handle_jump_fall_state(delta: float) -> void:
	# Fall gravity multiplier for snappy descent
	velocity.y += config.gravity * config.fall_gravity_multiplier * delta

	# Coyote jump check
	if coyote_timer > 0.0 and jump_buffer_timer > 0.0:
		_execute_jump()
		return

	# Dive check
	if Input.is_action_just_pressed("slide"):
		state_machine.change_state(PlayerStateMachine.State.DIVE)
		return

func _handle_land_state(_delta: float) -> void:
	# Responsiveness: allow buffered or new jumps during squash
	if jump_buffer_timer > 0.0:
		_execute_jump()
		return

	if Input.is_action_pressed("slide"):
		_enter_slide()
		return

	# Land state plays squash, then transitions back to run
	if state_machine.time_in_state >= config.squash_duration:
		state_machine.change_state(PlayerStateMachine.State.RUN)

func _handle_slide_state(delta: float) -> void:
	slide_timer += delta

	# Try to stand if duration expired or slide key released
	var is_sliding = Input.is_action_pressed("slide") or slide_held
	var wants_to_recover = slide_timer >= config.slide_duration or not is_sliding
	if wants_to_recover:
		# Ensure ceiling is clear (both front and back rays) before standing
		var front_blocked = ceiling_ray != null and ceiling_ray.is_colliding()
		var back_blocked = ceiling_ray_back != null and ceiling_ray_back.is_colliding()
		if not front_blocked and not back_blocked:
			_exit_slide()
		# If ceiling is blocked, stay sliding safely

func _handle_dive_state(_delta: float) -> void:
	velocity.y = config.dive_velocity

func _execute_jump() -> void:
	jump_buffer_timer = 0.0
	coyote_timer = 0.0
	jump_hold_timer = 0.0
	is_jump_holding = true
	velocity.y = -config.initial_jump_velocity
	state_machine.change_state(PlayerStateMachine.State.JUMP_RISE)
	jumped.emit()
	_apply_takeoff_stretch()

func _enter_slide() -> void:
	slide_timer = 0.0
	state_machine.change_state(PlayerStateMachine.State.SLIDE)
	if box_shape:
		box_shape.size = config.sliding_extents * 2.0
	if collision_shape:
		collision_shape.position = config.sliding_offset

func _exit_slide() -> void:
	if box_shape:
		box_shape.size = config.standing_extents * 2.0
	if collision_shape:
		collision_shape.position = config.standing_offset
	state_machine.change_state(PlayerStateMachine.State.RUN)

func _post_movement_check(_delta: float) -> void:
	if is_on_floor():
		var st = state_machine.current_state
		if st == PlayerStateMachine.State.JUMP_FALL or st == PlayerStateMachine.State.JUMP_RISE or st == PlayerStateMachine.State.JUMP_APEX or st == PlayerStateMachine.State.DIVE:
			# Just landed
			velocity.y = 0.0
			landed.emit()
			_spawn_dust_puff()
			_apply_landing_squash()

			# Check if jump was buffered during fall
			if jump_buffer_timer > 0.0:
				_execute_jump()
			elif Input.is_action_pressed("slide"):
				_enter_slide()
			else:
				state_machine.change_state(PlayerStateMachine.State.LAND)

func _apply_landing_squash() -> void:
	if not is_inside_tree() or sprite == null:
		return
	var tw = create_tween()
	tw.tween_property(sprite, "scale", config.landing_squash_scale, config.squash_duration * 0.5)
	tw.tween_property(sprite, "scale", Vector2.ONE, config.squash_duration * 0.5)

func _apply_takeoff_stretch() -> void:
	if not is_inside_tree() or sprite == null:
		return
	var tw = create_tween()
	tw.tween_property(sprite, "scale", config.takeoff_stretch_scale, config.stretch_duration * 0.5)
	tw.tween_property(sprite, "scale", Vector2.ONE, config.stretch_duration * 0.5)

func _spawn_dust_puff() -> void:
	if not is_inside_tree() or get_parent() == null:
		return
	var dust = preload("res://scripts/player/dust_puff.gd").new()
	dust.global_position = global_position + Vector2(-6, 12)
	get_parent().add_child(dust)

func hit_hazard() -> void:
	if state_machine.current_state == PlayerStateMachine.State.DEAD:
		return
	state_machine.change_state(PlayerStateMachine.State.DEAD)
	velocity = Vector2.ZERO
	died.emit()

func _on_state_machine_state_changed(old_st: PlayerStateMachine.State, new_st: PlayerStateMachine.State) -> void:
	state_changed.emit(old_st, new_st)

func _update_presentation(delta: float) -> void:
	if sprite == null:
		return

	# Frame index mapping based on assets/sprites/dinosaur_frames.json
	match state_machine.current_state:
		PlayerStateMachine.State.IDLE:
			sprite.frame = 0
			sprite.rotation_degrees = 0.0

		PlayerStateMachine.State.RUN:
			run_anim_timer += delta * (current_speed / 45.0)
			sprite.frame = 2 + (int(run_anim_timer) % 6)
			# Subtle forward lean when accelerating
			sprite.rotation_degrees = 3.0

		PlayerStateMachine.State.JUMP_RISE:
			sprite.frame = 8
			sprite.rotation_degrees = -2.0

		PlayerStateMachine.State.JUMP_APEX:
			sprite.frame = 9
			sprite.rotation_degrees = 0.0

		PlayerStateMachine.State.JUMP_FALL:
			sprite.frame = 10
			sprite.rotation_degrees = 2.0

		PlayerStateMachine.State.LAND:
			sprite.frame = 11
			sprite.rotation_degrees = 0.0

		PlayerStateMachine.State.SLIDE:
			sprite.frame = 13 if int(state_machine.time_in_state * 8.0) % 2 == 0 else 14
			sprite.rotation_degrees = 0.0

		PlayerStateMachine.State.DIVE:
			sprite.frame = 15
			sprite.rotation_degrees = 15.0

		PlayerStateMachine.State.HURT:
			sprite.frame = 19
			sprite.rotation_degrees = -10.0

		PlayerStateMachine.State.DEAD:
			var death_f = mini(int(state_machine.time_in_state * 10.0), 5)
			sprite.frame = 21 + death_f
			sprite.rotation_degrees = -20.0
