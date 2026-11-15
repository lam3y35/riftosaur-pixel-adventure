class_name AssetJuice
extends RefCounted
## Shared "eye-candy" helpers: glow halos, ground shadows, twinkles and particle bursts.
## Purely visual - never touches collision or gameplay state.

static var _glow_tex: GradientTexture2D = null
static var _add_mat: CanvasItemMaterial = null


static func _glow_texture() -> GradientTexture2D:
	if _glow_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 0.95))
		g.set_color(1, Color(1, 1, 1, 0.0))
		g.add_point(0.35, Color(1, 1, 1, 0.45))
		_glow_tex = GradientTexture2D.new()
		_glow_tex.gradient = g
		_glow_tex.fill = GradientTexture2D.FILL_RADIAL
		_glow_tex.fill_from = Vector2(0.5, 0.5)
		_glow_tex.fill_to = Vector2(1.0, 0.5)
		_glow_tex.width = 64
		_glow_tex.height = 64
	return _glow_tex


static func _additive() -> CanvasItemMaterial:
	if _add_mat == null:
		_add_mat = CanvasItemMaterial.new()
		_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _add_mat


## Pulsing additive halo behind `host` (placed under the sprite).
static func add_glow(host: Node2D, color: Color, radius: float = 20.0, pulse: float = 0.18, offset: Vector2 = Vector2.ZERO) -> Sprite2D:
	if host == null:
		return null
	var s := Sprite2D.new()
	s.name = "JuiceGlow"
	s.texture = _glow_texture()
	s.material = _additive()
	s.modulate = Color(color.r, color.g, color.b, 0.75)
	s.position = offset
	s.show_behind_parent = true
	s.z_index = -1
	var base := radius * 2.0 / 64.0
	s.scale = Vector2(base, base)
	host.add_child(s)
	if host.is_inside_tree():
		var tw := s.create_tween().set_loops()
		tw.set_trans(Tween.TRANS_SINE)
		tw.tween_property(s, "scale", Vector2(base, base) * (1.0 + pulse), 0.6 + randf() * 0.3)
		tw.tween_property(s, "scale", Vector2(base, base) * (1.0 - pulse * 0.6), 0.6 + randf() * 0.3)
	return s


## Soft dark ellipse on the ground below an obstacle so it feels grounded.
static func add_shadow(host: Node2D, width: float = 24.0, y: float = 0.0) -> Sprite2D:
	if host == null:
		return null
	var s := Sprite2D.new()
	s.name = "JuiceShadow"
	s.texture = _glow_texture()
	s.modulate = Color(0, 0, 0, 0.55)
	s.position = Vector2(0, y)
	s.scale = Vector2(width / 64.0, width * 0.22 / 64.0)
	s.show_behind_parent = true
	s.z_index = -1
	host.add_child(s)
	return s


## Twinkling 4-point star that flickers on and off.
static func add_twinkle(host: Node2D, offset: Vector2, color: Color = Color(1, 1, 1, 1), size: float = 7.0) -> void:
	if host == null or not host.is_inside_tree():
		return
	var s := Sprite2D.new()
	s.name = "JuiceTwinkle"
	s.texture = _glow_texture()
	s.material = _additive()
	s.modulate = color
	s.position = offset
	s.scale = Vector2.ZERO
	host.add_child(s)
	var tw := s.create_tween().set_loops()
	tw.tween_interval(randf() * 1.2)
	tw.tween_property(s, "scale", Vector2(size, size * 0.35) / 64.0 * 2.0, 0.12)
	tw.tween_property(s, "scale", Vector2.ZERO, 0.22)
	tw.tween_interval(0.8 + randf() * 0.9)


## One-shot particle burst, parented to the scene so it outlives `host`.
static func burst(host: Node, world_pos: Vector2, color: Color, amount: int = 14, speed: float = 120.0, life: float = 0.45) -> void:
	if host == null or not host.is_inside_tree():
		return
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = amount
	p.lifetime = life
	p.explosiveness = 1.0
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, 260)
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.0
	p.color = color
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 1))
	ramp.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = ramp
	p.material = _additive()
	p.z_index = 20
	p.global_position = world_pos
	var root := host.get_tree().current_scene
	if root == null:
		return
	root.add_child(p)
	host.get_tree().create_timer(life + 0.3).timeout.connect(p.queue_free)
