class_name TrapPickup
extends Area2D

signal trap_triggered(pickup: TrapPickup)

enum TrapType {
	SPEED_SURGE = 0,
	HEAVY_GRAVITY = 1,
	VISION_GLITCH = 2,
	SKILL_JAM = 3
}

@export_enum("Speed Surge", "Heavy Gravity", "Vision Glitch", "Skill Jam") var trap_type: int = TrapType.SPEED_SURGE
@export var debuff_duration: float = 3.5
@export var speed_penalty: float = 115.0

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

func set_trap_type(t: int) -> void:
	trap_type = clampi(t, 0, 3)
	queue_redraw()

func get_trap_label() -> String:
	match trap_type:
		TrapType.HEAVY_GRAVITY:
			return "HEAVY GRAVITY!"
		TrapType.VISION_GLITCH:
			return "GLITCH STATIC!"
		TrapType.SKILL_JAM:
			return "SKILLS JAMMED!"
		_:
			return "SPEED SURGE!"

func get_trap_color() -> Color:
	match trap_type:
		TrapType.HEAVY_GRAVITY:
			return Color(0.68, 0.34, 1.0, 1.0)
		TrapType.VISION_GLITCH:
			return Color(0.18, 0.92, 0.96, 1.0)
		TrapType.SKILL_JAM:
			return Color(1.0, 0.25, 0.32, 1.0)
		_:
			return Color(1.0, 0.84, 0.05, 1.0)

func _draw() -> void:
	var dark := Color(0.08, 0.07, 0.09, 0.98)
	var col := get_trap_color()
	match trap_type:
		TrapType.HEAVY_GRAVITY:
			# Inverted purple triangle with downward weight arrow
			var border_pts := PackedVector2Array([Vector2(-13.0, -10.5), Vector2(13.0, -10.5), Vector2(0.0, 13.0)])
			var pts := PackedVector2Array([Vector2(-11.0, -9.0), Vector2(11.0, -9.0), Vector2(0.0, 11.0)])
			draw_colored_polygon(border_pts, dark)
			draw_colored_polygon(pts, col)
			draw_rect(Rect2(-1.6, -6.5, 3.2, 8.0), dark)
			draw_colored_polygon(PackedVector2Array([Vector2(-5.0, 0.5), Vector2(5.0, 0.5), Vector2(0.0, 6.5)]), dark)
		TrapType.VISION_GLITCH:
			# Cyan/magenta glitch diamond
			var border_pts := PackedVector2Array([Vector2(0.0, -13.0), Vector2(13.0, 0.0), Vector2(0.0, 13.0), Vector2(-13.0, 0.0)])
			var pts := PackedVector2Array([Vector2(0.0, -11.0), Vector2(11.0, 0.0), Vector2(0.0, 11.0), Vector2(-11.0, 0.0)])
			draw_colored_polygon(border_pts, dark)
			draw_colored_polygon(pts, col)
			draw_rect(Rect2(-5.5, -2.5, 11.0, 2.0), Color(1.0, 0.25, 0.85, 0.95))
			draw_rect(Rect2(-4.0, 1.5, 8.0, 2.0), dark)
		TrapType.SKILL_JAM:
			# Red diamond-octagon with X
			var border_pts := PackedVector2Array([Vector2(-6, -12), Vector2(6, -12), Vector2(12, -6), Vector2(12, 6), Vector2(6, 12), Vector2(-6, 12), Vector2(-12, 6), Vector2(-12, -6)])
			var pts := PackedVector2Array([Vector2(-5, -10), Vector2(5, -10), Vector2(10, -5), Vector2(10, 5), Vector2(5, 10), Vector2(-5, 10), Vector2(-10, 5), Vector2(-10, -5)])
			draw_colored_polygon(border_pts, dark)
			draw_colored_polygon(pts, col)
			draw_line(Vector2(-5.0, -5.0), Vector2(5.0, 5.0), dark, 2.4)
			draw_line(Vector2(5.0, -5.0), Vector2(-5.0, 5.0), dark, 2.4)
		_:
			# Classic yellow warning triangle (!)
			var pts := PackedVector2Array([
				Vector2(0.0, -11.0),
				Vector2(11.0, 9.0),
				Vector2(-11.0, 9.0)
			])
			var border_pts := PackedVector2Array([
				Vector2(0.0, -13.0),
				Vector2(13.0, 10.5),
				Vector2(-13.0, 10.5)
			])
			draw_colored_polygon(border_pts, dark)
			draw_colored_polygon(pts, col)
			draw_rect(Rect2(-1.5, -5.0, 3.0, 7.5), dark)
			draw_rect(Rect2(-1.5, 4.2, 3.0, 2.8), dark)

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
		player.apply_trap_debuff(debuff_duration, speed_penalty, trap_type)

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
