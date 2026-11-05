class_name GameCamera
extends Camera2D

@export var target: Node2D
@export var horizontal_lead: float = 120.0 # Keeps dinosaur at x=120 in 480px view (left third)
@export var vertical_offset: float = -30.0

func _physics_process(_delta: float) -> void:
	if target == null:
		return

	# Smooth horizontal tracking snapped to whole integer pixels
	var target_x = target.global_position.x + horizontal_lead
	global_position.x = roundf(target_x)
	global_position.y = roundf(target.global_position.y + vertical_offset)
