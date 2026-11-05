class_name GameCamera
extends Camera2D

@export var target: Node2D
@export var horizontal_lead: float = 120.0 # Keeps dinosaur at x=120 in 480px view (left third)
@export var baseline_y: float = 135.0 # Perfectly centers 480x270 viewport on ground track

var current_grounded_y: float = 135.0

func _ready() -> void:
	global_position.y = baseline_y

func _physics_process(delta: float) -> void:
	if target == null:
		return

	# Smooth horizontal tracking snapped to whole integer pixels
	var target_x = target.global_position.x + horizontal_lead
	global_position.x = roundf(target_x)

	# Vertical camera stability:
	# Ground jumps must NEVER move the camera up/down (prevents background/ground disconnect).
	# Camera only eases vertically when the player is solidly standing on an elevated platform.
	if target is CharacterBody2D:
		if target.is_on_floor():
			# If on ground track (y ~ 218), stay locked to baseline 135
			# If on an elevated platform, adjust baseline smoothly
			var platform_offset = target.global_position.y - 218.0
			current_grounded_y = baseline_y + platform_offset

	# Smooth easing towards the grounded height (deadzone for mid-air jumps)
	global_position.y = roundf(lerpf(global_position.y, current_grounded_y, 8.0 * delta))
