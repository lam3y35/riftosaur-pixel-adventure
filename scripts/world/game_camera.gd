class_name GameCamera
extends Camera2D

@export var target: Node2D
@export var horizontal_lead: float = 120.0 # Keeps dinosaur at x=120 in 480px view (left third)
@export var baseline_y: float = 135.0 # Viewport center on ground track (480x270)
@export var deadzone_threshold_y: float = 185.0 # Normal ground jumps stay locked to baseline
@export var vertical_follow_speed: float = 5.5 # Smooth vertical easing
@export var min_camera_y: float = 10.0 # Upper camera limit for high ascents
@export var max_camera_y: float = 135.0 # Lower camera limit (ground baseline)

@export var reduce_motion: bool = false

var current_target_y: float = 135.0
var target_zoom: float = 1.0
var shake_intensity: float = 0.0
var shake_timer: float = 0.0
var shake_total_duration: float = 0.2

func _ready() -> void:
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	global_position.y = baseline_y
	current_target_y = baseline_y

func _physics_process(delta: float) -> void:
	if target == null:
		return

	# 1. Horizontal Tracking: dinosaur locked in left third (look-ahead), smooth sub-pixel float
	var target_x = target.global_position.x + horizontal_lead
	var final_x = target_x

	# 2. Vertical Tracking with Deadzone & Ground-Safe Framing
	# Ensures that even on very high jumps/bounces/flight, the ground (y=230) and obstacles below stay visible.
	var player_y = target.global_position.y
	var elevation_zoom: float = 1.0
	if player_y > deadzone_threshold_y:
		# Player is on or near ground level — stay anchored at baseline
		current_target_y = baseline_y
	else:
		var span: float = maxf(248.0 - (player_y - 52.0), 270.0)
		elevation_zoom = clampf(270.0 / span, 0.65, 1.0)
		var half_h: float = 135.0 / elevation_zoom
		var min_y_for_ground: float = clampf(248.0 - half_h, min_camera_y, max_camera_y)
		var desired_y: float = clampf(player_y - 20.0, min_y_for_ground, max_camera_y)
		current_target_y = clampf(desired_y, min_camera_y, max_camera_y)

	var smooth_y = lerpf(global_position.y, current_target_y, clampf(vertical_follow_speed * delta, 0.0, 1.0))
	var final_y = clampf(smooth_y, min_camera_y, max_camera_y)

	# 3. Impact Shake via Camera2D.offset (keeps baseline global_position crisp)
	var shake_offset = Vector2.ZERO
	if not reduce_motion and shake_timer > 0.0:
		shake_timer = maxf(shake_timer - delta, 0.0)
		var damp = clampf(shake_timer / maxf(shake_total_duration, 0.001), 0.0, 1.0)
		var current_amp = shake_intensity * damp
		shake_offset = Vector2(randf_range(-current_amp, current_amp), randf_range(-current_amp, current_amp))
	offset = shake_offset

	# 4. Dynamic Speed / Action Zoom + Elevation Ground-Safety Zoom
	# Keep normal zoom stable (0.94..1.04) so fast motion stays razor crisp without shimmering
	var speed_zoom: float = 1.0 if reduce_motion else clampf(target_zoom, 0.94, 1.04)
	var desired_zoom = minf(speed_zoom, elevation_zoom)
	var z_val = lerpf(zoom.x, desired_zoom, clampf(delta * 5.0, 0.0, 1.0))
	zoom = Vector2(z_val, z_val)

	global_position = Vector2(final_x, final_y)

func set_dynamic_zoom(z: float) -> void:
	target_zoom = clampf(z, 0.85, 1.08)

func reset_camera() -> void:
	shake_timer = 0.0
	shake_intensity = 0.0
	offset = Vector2.ZERO
	target_zoom = 1.0
	zoom = Vector2.ONE
	current_target_y = baseline_y
	global_position.y = baseline_y
	reset_physics_interpolation()

func add_impact_shake(amount: float = 4.0, duration: float = 0.2) -> void:
	if reduce_motion:
		return
	if shake_timer > 0.0 and shake_intensity > amount:
		return
	shake_intensity = amount
	shake_total_duration = maxf(duration, 0.05)
	shake_timer = shake_total_duration
