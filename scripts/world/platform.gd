class_name Platform
extends StaticBody2D

@export var is_one_way: bool = false
@export var platform_width: float = 48.0
@export var platform_height: float = 12.0

@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")
@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	if is_one_way:
		add_to_group("one_way_platform")
		if collision_shape:
			collision_shape.one_way_collision = true
			collision_shape.one_way_collision_margin = 2.0
	else:
		add_to_group("solid_platform")
		if collision_shape:
			collision_shape.one_way_collision = false
