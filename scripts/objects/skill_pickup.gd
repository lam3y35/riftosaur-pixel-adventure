class_name SkillPickup
extends Area2D

signal picked_up(pickup: SkillPickup)

@export var skill_type: SkillManager.SkillType = SkillManager.SkillType.BONE_BLADE

var base_y: float = 0.0
var bob_timer: float = 0.0
var is_picked_up: bool = false

@onready var orb_sprite: Sprite2D = get_node_or_null("OrbSprite")
@onready var icon_sprite: Sprite2D = get_node_or_null("IconSprite")

func _ready() -> void:
	base_y = position.y
	bob_timer = randf() * TAU
	add_to_group("skill_pickups")
	body_entered.connect(_on_body_entered)
	_update_visuals()

func _update_visuals() -> void:
	var info = SkillManager.SKILL_DATA.get(skill_type, {})
	var icon_path = info.get("icon", "")
	if icon_sprite and icon_path != "" and ResourceLoader.exists(icon_path):
		icon_sprite.texture = load(icon_path)

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

	if player and player.skill_manager:
		player.skill_manager.equip_skill(skill_type)

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
