class_name BoomerangProjectile
extends Area2D

@export var speed: float = 340.0
@export var max_distance: float = 210.0
@export var return_speed: float = 420.0

var start_x: float = 0.0
var rel_x: float = 0.0
var returning: bool = false
var origin_player: Node2D = null

func _ready() -> void:
	start_x = global_position.x
	collision_layer = 0
	collision_mask = 4 # Detect Hazards on layer 3 (bit 4)
	monitoring = true
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	rotation += 20.0 * delta

	if is_instance_valid(origin_player):
		if not returning:
			rel_x += speed * delta
			global_position.x = origin_player.global_position.x + rel_x
			global_position.y = lerpf(global_position.y, origin_player.global_position.y - 6.0, minf(delta * 10.0, 1.0))
			if rel_x >= max_distance:
				returning = true
		else:
			rel_x -= return_speed * delta
			global_position.x = origin_player.global_position.x + rel_x
			global_position.y = lerpf(global_position.y, origin_player.global_position.y - 6.0, minf(delta * 14.0, 1.0))
			if rel_x <= 12.0 or global_position.distance_to(origin_player.global_position) < 20.0:
				queue_free()
	else:
		if not returning:
			global_position.x += speed * delta
			if global_position.x >= start_x + max_distance:
				returning = true
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
