class_name TrapPickup
extends Area2D

signal trap_triggered(pickup: TrapPickup)

@export var debuff_duration: float = 4.0
@export var speed_penalty: float = 125.0

var base_y: float = 0.0
var bob_timer: float = 0.0
var is_triggered: bool = false

func _ready() -> void:
	base_y = position.y
	bob_timer = randf() * TAU
	z_index = 6
	add_to_group("trap_pickups")
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	queue_redraw()

func _draw() -> void:
	var pts := PackedVector2Array([
		Vector2(0.0, -11.0),
		Vector2(11.0, 9.0),
		Vector2(-11.0, 9.0)
	])
	# Outer dark border
	var border_pts := PackedVector2Array([
		Vector2(0.0, -13.0),
		Vector2(13.0, 10.5),
		Vector2(-13.0, 10.5)
	])
	draw_colored_polygon(border_pts, Color(0.1, 0.08, 0.05, 0.98))
	draw_colored_polygon(pts, Color(1.0, 0.84, 0.05, 1.0))
	# Exclamation mark (!)
	draw_rect(Rect2(-1.5, -5.0, 3.0, 7.5), Color(0.1, 0.08, 0.05, 1.0))
	draw_rect(Rect2(-1.5, 4.2, 3.0, 2.8), Color(0.1, 0.08, 0.05, 1.0))

func _physics_process(delta: float) -> void:
	if is_triggered:
		return
	bob_timer += delta * 4.2
	position.y = base_y + sin(bob_timer) * 3.0

func _on_body_entered(body: Node2D) -> void:
	if is_triggered:
		return
	if body is Player:
		trigger(body)

func trigger(player: Player) -> void:
	if is_triggered:
		return
	is_triggered = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	if player:
		player.apply_trap_debuff(debuff_duration, speed_penalty)

	trap_triggered.emit(self)

	if is_inside_tree():
		var tw = create_tween()
		if tw:
			tw.set_parallel(true)
			tw.tween_property(self, "scale", Vector2(1.7, 1.7), 0.16)
			tw.tween_property(self, "modulate:a", 0.0, 0.16)
			tw.chain().tween_callback(queue_free)
			return
	queue_free()
