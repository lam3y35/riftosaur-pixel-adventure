class_name BoomerangProjectile
extends Area2D

@export var speed: float = 380.0
@export var max_distance: float = 180.0
@export var return_speed: float = 420.0

var start_x: float = 0.0
var returning: bool = false
var origin_player: Node2D = null

func _ready() -> void:
	start_x = global_position.x
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	rotation += 18.0 * delta

	if not returning:
		global_position.x += speed * delta
		if global_position.x >= start_x + max_distance:
			returning = true
	else:
		if is_instance_valid(origin_player):
			var dir = (origin_player.global_position - global_position).normalized()
			global_position += dir * return_speed * delta
			if global_position.distance_to(origin_player.global_position) < 20.0:
				queue_free()
		else:
			global_position.x -= return_speed * delta
			if global_position.x <= start_x - 50.0:
				queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area is Hazard:
		_check_hit_hazard(area)

func _on_body_entered(body: Node2D) -> void:
	if returning and body == origin_player:
		queue_free()

func _check_hit_hazard(hazard: Hazard) -> void:
	# Spec: Boomerang hits Airborne and Crawler hazards on its route
	if hazard.category == Hazard.Category.AIRBORNE or hazard.category == Hazard.Category.CRAWLER:
		hazard.destroy_hazard()
