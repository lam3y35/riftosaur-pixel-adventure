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
var shake_intensity: float = 0.0
var shake_timer: float = 0.0
var shake_total_duration: float = 0.2

func _ready() -> void:
	global_position.y = baseline_y
	current_target_y = baseline_y

func _physics_process(delta: float) -> void:
	if target == null:
		return

	# 1. Horizontal Tracking: dinosaur locked in left third (look-ahead)
	var target_x = target.global_position.x + horizontal_lead
	var final_x = roundf(target_x)

	# 2. Vertical Tracking with Deadzone & Smooth Easing (Spec D)
	var player_y = target.global_position.y
	if player_y > deadzone_threshold_y:
		# Player is on or near ground level — stay anchored at baseline
		current_target_y = baseline_y
	else:
		# Player is elevated on high platforms or launched by springs
		# Frame dinosaur nicely in lower-middle of viewport
		var desired_y = player_y - 70.0
		current_target_y = clampf(desired_y, min_camera_y, max_camera_y)

	var smooth_y = lerpf(global_position.y, current_target_y, vertical_follow_speed * delta)
	var final_y = clampf(smooth_y, min_camera_y, max_camera_y)

	# 3. Impact Shake (Optional, disabled by reduce_motion)
	var shake_offset = Vector2.ZERO
	if not reduce_motion and shake_timer > 0.0:
		shake_timer -= delta
		var damp = clampf(shake_timer / maxf(shake_total_duration, 0.001), 0.0, 1.0)
		var current_amp = shake_intensity * damp
		shake_offset = Vector2(randf_range(-current_amp, current_amp), randf_range(-current_amp, current_amp))

	global_position = Vector2(final_x, final_y) + shake_offset

func add_impact_shake(amount: float = 4.0, duration: float = 0.2) -> void:
	if reduce_motion:
		return
	shake_intensity = amount
	shake_total_duration = duration
	shake_timer = duration
