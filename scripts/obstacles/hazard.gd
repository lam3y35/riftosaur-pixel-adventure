class_name Hazard
extends Area2D

enum Category {
	SOLID,
	BREAKABLE,
	AIRBORNE,
	CRAWLER,
	PROJECTILE,
	ENVIRONMENTAL
}

signal destroyed(hazard: Hazard)

@export var hazard_name: String = "Cactus Rock"
@export var category: Category = Category.SOLID
@export var speed: float = 0.0

var base_speed: float = 0.0
var is_destroyed: bool = false
var time_scale: float = 1.0

func _ready() -> void:
	base_speed = speed
	add_to_group("hazards")
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if is_destroyed or speed == 0.0:
		return
	# Move left relative to world
	position.x -= speed * time_scale * delta

func _on_body_entered(body: Node2D) -> void:
	if is_destroyed:
		return
	if body is Player:
		body.hit_hazard("Hit by %s" % hazard_name, false, self)

func destroy_hazard() -> void:
	if is_destroyed:
		return
	is_destroyed = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	destroyed.emit(self)
	
	if is_inside_tree():
		var tw = create_tween()
		if tw:
			tw.tween_property(self, "scale", Vector2.ZERO, 0.12)
			tw.tween_property(self, "modulate:a", 0.0, 0.12)
			tw.tween_callback(queue_free)
			return
	queue_free()

func set_time_scale(multiplier: float) -> void:
	time_scale = multiplier
