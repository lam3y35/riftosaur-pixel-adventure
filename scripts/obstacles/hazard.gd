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
var _near_miss_awarded: bool = false
var _player_ref: WeakRef = null
var _anim_timer: float = 0.0
@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")

func _ready() -> void:
	base_speed = speed
	z_index = 5
	add_to_group("hazards")
	if sprite and sprite.scale == Vector2.ONE:
		if category == Category.CRAWLER or hazard_name.contains("Cactus") or category == Category.ENVIRONMENTAL:
			sprite.scale = Vector2(1.18, 1.18)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	_apply_juice()

func _apply_juice() -> void:
	if sprite == null or sprite.texture == null:
		return
	var size: Vector2 = sprite.texture.get_size() * sprite.scale
	if sprite.hframes > 1:
		size.x /= float(sprite.hframes)
	var bottom_y: float = sprite.position.y + sprite.offset.y * sprite.scale.y + size.y * 0.5
	match category:
		Category.AIRBORNE, Category.PROJECTILE:
			AssetJuice.add_glow(self, Color(1.0, 0.25, 0.2), maxf(size.x, size.y) * 0.55, 0.18, sprite.position + sprite.offset)
		Category.CRAWLER:
			AssetJuice.add_glow(self, Color(1.0, 0.45, 0.15), size.x * 0.6, 0.2, sprite.position + sprite.offset)
			AssetJuice.add_shadow(self, size.x * 0.9, bottom_y)
		Category.ENVIRONMENTAL:
			AssetJuice.add_glow(self, Color(1.0, 0.4, 0.1), size.x * 0.4, 0.2, sprite.position + sprite.offset)
		_:
			if size.y < 80.0:
				AssetJuice.add_shadow(self, size.x * 0.95, bottom_y)

func _process(delta: float) -> void:
	if is_destroyed or sprite == null or sprite.hframes <= 1:
		return
	_anim_timer += delta * 6.5 * maxf(time_scale, 0.35)
	sprite.frame = int(_anim_timer) % sprite.hframes

func _physics_process(delta: float) -> void:
	if is_destroyed or speed == 0.0:
		return
	# Activate horizontal patrol only once near the player so enemies don't drift out of chunks early
	var player = _player_ref.get_ref() if _player_ref else null
	if player == null and is_inside_tree():
		var players = get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			player = players[0]
			_player_ref = weakref(player)
	if player != null and (global_position.x - player.global_position.x) > 540.0:
		return
	# Move left relative to world
	position.x -= speed * time_scale * delta

func _on_body_entered(body: Node2D) -> void:
	if is_destroyed:
		return
	if body is Player:
		if category == Category.CRAWLER:
			var is_diving: bool = body.state_machine.current_state == PlayerStateMachine.State.DIVE or body.is_ground_slamming
			var is_falling_above: bool = body.velocity.y > 0.0 and body.global_position.y < global_position.y - 1.0
			if is_diving or is_falling_above:
				destroy_hazard()
				body.velocity.y = -240.0
				body.is_ground_slamming = false
				if body.state_machine.current_state == PlayerStateMachine.State.DIVE:
					body.state_machine.change_state(PlayerStateMachine.State.JUMP_RISE)
				body.add_gems(1, 50)
				body.hazard_broken.emit(self, "stomp")
				return
		body.hit_hazard("Hit by %s" % hazard_name, false, self)

func destroy_hazard() -> void:
	if is_destroyed:
		return
	is_destroyed = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	destroyed.emit(self)
	AssetJuice.burst(self, global_position + Vector2(0, -8), Color(1.0, 0.7, 0.3), 18, 150.0, 0.5)
	
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
