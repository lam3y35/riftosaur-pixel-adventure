class_name GameCamera
extends Camera2D

@export var target: Node2D
@export var horizontal_lead: float = 120.0 # Keeps dinosaur at x=120 in 480px view (left third)
@export var baseline_y: float = 135.0 # Perfectly centers 480x270 viewport on ground track

var current_grounded_y: float = 135.0

func _ready() -> void:
	global_position.y = baseline_y

func _physics_process(_delta: float) -> void:
	if target == null:
		return

	# Smooth horizontal tracking snapped to whole integer pixels
	var target_x = target.global_position.x + horizontal_lead
	global_position.x = roundf(target_x)

	# Keep vertical camera locked to baseline_y (135.0) so ground and parallax
	# layers remain 100% anchored at the bottom of the screen during jumps and crate hops.
	current_grounded_y = baseline_y
	global_position.y = baseline_y
