class_name DustPuff
extends Sprite2D

var elapsed: float = 0.0
var fps: float = 16.0
var total_frames: int = 4

func _ready() -> void:
	texture = preload("res://assets/sprites/dust_puff.png")
	hframes = 4
	vframes = 1
	frame = 0

func _process(delta: float) -> void:
	elapsed += delta
	var current_frame = int(elapsed * fps)
	if current_frame >= total_frames:
		queue_free()
	else:
		frame = current_frame
