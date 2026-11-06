class_name Collectible
extends Area2D

signal collected(item: Collectible)

@export var gem_value: int = 1
@export var score_bonus: int = 15

var is_collected: bool = false
var base_y: float = 0.0
var bob_timer: float = 0.0
var target_player: Player = null

func _ready() -> void:
	base_y = position.y
	bob_timer = randf() * TAU
	add_to_group("collectibles")
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if is_collected:
		return

	bob_timer += delta * 4.0
	position.y = base_y + sin(bob_timer) * 3.0

	# Magnet relic attraction
	if target_player == null:
		var players = get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			target_player = players[0] as Player

	if is_instance_valid(target_player) and target_player.is_magnet_active:
		var dist = global_position.distance_to(target_player.global_position)
		if dist <= 240.0:
			var pull_speed = 350.0 + (240.0 - dist) * 1.5
			var dir = (target_player.global_position - global_position).normalized()
			global_position += dir * pull_speed * delta

func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return
	if body is Player:
		collect(body)

func collect(player: Player) -> void:
	if is_collected:
		return
	is_collected = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	if player and player.has_method("add_gems"):
		player.add_gems(gem_value, score_bonus)

	collected.emit(self)

	# Visual collection pop
	if is_inside_tree():
		var tw = create_tween()
		if tw:
			tw.set_parallel(true)
			tw.tween_property(self, "scale", Vector2(1.5, 1.5), 0.15)
			tw.tween_property(self, "position:y", position.y - 18.0, 0.15)
			tw.tween_property(self, "modulate:a", 0.0, 0.15)
			tw.chain().tween_callback(queue_free)
			return
	queue_free()
