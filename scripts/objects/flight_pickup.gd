class_name FlightPickup
extends Area2D

enum FlightType {
	NONE = 0,
	MECHANICAL_WINGS = 1,
	ROCKET_RELIC = 2
}

signal picked_up(pickup: FlightPickup)

@export var flight_type: FlightType = FlightType.MECHANICAL_WINGS
@export var flight_duration: float = 7.0

var base_y: float = 0.0
var bob_timer: float = 0.0
var is_picked_up: bool = false

func _ready() -> void:
	base_y = position.y
	bob_timer = randf() * TAU
	add_to_group("flight_pickups")
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if is_picked_up:
		return
	bob_timer += delta * 3.5
	position.y = base_y + sin(bob_timer) * 4.0

func _on_body_entered(body: Node2D) -> void:
	if is_picked_up:
		return
	if body is Player:
		collect(body)

func collect(player: Player) -> void:
	if is_picked_up:
		return
	is_picked_up = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	if player and player.has_method("start_flight"):
		player.start_flight(int(flight_type), flight_duration)

	picked_up.emit(self)

	if is_inside_tree():
		var tw = create_tween()
		if tw:
			tw.set_parallel(true)
			tw.tween_property(self, "scale", Vector2(1.6, 1.6), 0.18)
			tw.tween_property(self, "modulate:a", 0.0, 0.18)
			tw.chain().tween_callback(queue_free)
			return
	queue_free()
