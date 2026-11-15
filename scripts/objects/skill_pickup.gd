class_name SkillPickup
extends Area2D

signal picked_up(pickup: SkillPickup)

@export var skill_type: SkillManager.SkillType = SkillManager.SkillType.BONE_BLADE:
	set(val):
		skill_type = val
		if is_inside_tree():
			_update_visuals()

var base_y: float = 0.0
var bob_timer: float = 0.0
var is_picked_up: bool = false

@onready var orb_sprite: Sprite2D = get_node_or_null("OrbSprite")
@onready var icon_sprite: Sprite2D = get_node_or_null("IconSprite")

var _accent_color: Color = Color(0.45, 0.95, 1.0)
var _tag_panel: PanelContainer = null
var _tag_label: Label = null
var _hint_label: Label = null

func _ready() -> void:
	base_y = position.y
	bob_timer = randf() * TAU
	add_to_group("skill_pickups")
	body_entered.connect(_on_body_entered)
	_ensure_tag_badge()
	_update_visuals()

func _ensure_tag_badge() -> void:
	if _tag_panel != null:
		return
	_tag_panel = PanelContainer.new()
	_tag_panel.name = "SkillTagBadge"
	_tag_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tag_panel.z_index = 10
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.08, 0.14, 0.88)
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.border_color = _accent_color
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 4
	sb.content_margin_right = 4
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	_tag_panel.add_theme_stylebox_override("panel", sb)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 0)
	_tag_panel.add_child(vb)

	_tag_label = Label.new()
	_tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tag_label.add_theme_font_size_override("font_size", 8)
	_tag_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_tag_label.add_theme_constant_override("outline_size", 2)
	vb.add_child(_tag_label)

	_hint_label = Label.new()
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_font_size_override("font_size", 6)
	_hint_label.add_theme_color_override("font_color", Color(0.88, 0.92, 0.98, 0.95))
	_hint_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_hint_label.add_theme_constant_override("outline_size", 2)
	vb.add_child(_hint_label)

	add_child(_tag_panel)

func _update_visuals() -> void:
	var info = SkillManager.SKILL_DATA.get(skill_type, {})
	var icon_path = info.get("icon", "")
	_accent_color = info.get("color", Color(0.45, 0.95, 1.0))
	if icon_sprite and icon_path != "" and ResourceLoader.exists(icon_path):
		icon_sprite.texture = load(icon_path)
		icon_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if orb_sprite:
		orb_sprite.modulate = _accent_color.lerp(Color.WHITE, 0.35)
		orb_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if _tag_panel:
		var sb := _tag_panel.get_theme_stylebox("panel") as StyleBoxFlat
		if sb:
			sb.border_color = _accent_color
	if _tag_label:
		_tag_label.text = str(info.get("short_tag", info.get("name", "SKILL")))
		_tag_label.add_theme_color_override("font_color", _accent_color.lerp(Color.WHITE, 0.25))
	if _hint_label:
		var hint := str(info.get("when_hint", ""))
		_hint_label.text = hint
		_hint_label.visible = not hint.is_empty()
	if _tag_panel:
		_tag_panel.reset_size()
		_tag_panel.position = Vector2(-_tag_panel.size.x * 0.5, -34.0)
	queue_redraw()

func _draw() -> void:
	if is_picked_up:
		return
	var pulse: float = 0.5 + 0.5 * sin(bob_timer * 1.6)
	# Dark high-contrast backing circle so icon pops against any sky/biome
	draw_circle(Vector2.ZERO, 14.5, Color(0.05, 0.08, 0.14, 0.72))
	# Crisp pulsing outer halo ring in skill's signature color
	draw_arc(Vector2.ZERO, 15.5 + pulse * 2.5, 0.0, TAU, 28, Color(_accent_color.r, _accent_color.g, _accent_color.b, 0.55 + 0.3 * pulse), 1.8)

func _physics_process(delta: float) -> void:
	if is_picked_up:
		return
	bob_timer += delta * 3.5
	position.y = base_y + sin(bob_timer) * 4.0
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if is_picked_up:
		return
	if body is Player:
		collect(body)

func collect(player: Player) -> void:
	if is_picked_up:
		return
	is_picked_up = true
	if _tag_panel:
		_tag_panel.visible = false
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
