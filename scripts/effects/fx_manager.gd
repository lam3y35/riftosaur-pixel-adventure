class_name FXManager
extends Node2D

## Zero-allocation-churn procedural pixel VFX renderer for Riftosaur.
## Draws bursts, biome ambient particles, speed lines, shockwaves, slash arcs,
## afterimages, skill auras, and crisp world-space floating popups.

var particles: Array[Dictionary] = []
var rings: Array[Dictionary] = []
var slashes: Array[Dictionary] = []
var popups: Array[Dictionary] = []
var afterimages: Array[Dictionary] = []
var speed_lines: Array[Dictionary] = []
var ambients: Array[Dictionary] = []

var _ambient_spawn_accum: float = 0.0
var _trail_accum: float = 0.0
var _speed_line_accum: float = 0.0
var _aura_phase: float = 0.0

var active_shield: bool = false
var active_magnet: bool = false
var active_time_shard: bool = false
var active_fever: bool = false
var player_world_pos: Vector2 = Vector2.ZERO
var reduce_motion: bool = false
var high_contrast: bool = false

func _ready() -> void:
	z_index = 20

func clear_all() -> void:
	particles.clear()
	rings.clear()
	slashes.clear()
	popups.clear()
	afterimages.clear()
	speed_lines.clear()
	ambients.clear()
	active_shield = false
	active_magnet = false
	active_time_shard = false
	active_fever = false
	queue_redraw()

func update_fx(delta: float, cam_x: float, cam_y: float, p_pos: Vector2, p_speed: float, world_id: String, is_running: bool) -> void:
	player_world_pos = p_pos
	_aura_phase += delta * 5.0

	# 1. Update bursts
	for i in range(particles.size() - 1, -1, -1):
		var pt = particles[i]
		pt["age"] += delta
		if pt["age"] >= pt["life"]:
			particles.remove_at(i)
			continue
		pt["vel"].y += pt["gravity"] * delta
		pt["pos"] += pt["vel"] * delta

	# 2. Update shockwaves / rift portals
	for i in range(rings.size() - 1, -1, -1):
		var rg = rings[i]
		rg["age"] += delta
		if rg["age"] >= rg["life"]:
			rings.remove_at(i)

	# 3. Update slashes
	for i in range(slashes.size() - 1, -1, -1):
		var sl = slashes[i]
		sl["age"] += delta
		if sl["age"] >= sl["life"]:
			slashes.remove_at(i)

	# 4. Update floating popups
	for i in range(popups.size() - 1, -1, -1):
		var pp = popups[i]
		pp["age"] += delta
		if pp["age"] >= pp["life"]:
			popups.remove_at(i)
			continue
		pp["pos"].y -= 36.0 * delta
		pp["pos"].x += 22.0 * delta

	# 5. Update afterimages
	for i in range(afterimages.size() - 1, -1, -1):
		var af = afterimages[i]
		af["age"] += delta
		if af["age"] >= af["life"]:
			afterimages.remove_at(i)

	# 6. Update speed lines
	for i in range(speed_lines.size() - 1, -1, -1):
		var sp = speed_lines[i]
		sp["age"] += delta
		if sp["age"] >= sp["life"]:
			speed_lines.remove_at(i)
			continue
		sp["pos"].x -= sp["vx"] * delta

	# 7. Update ambient biome particles
	for i in range(ambients.size() - 1, -1, -1):
		var am = ambients[i]
		am["age"] += delta
		if am["age"] >= am["life"]:
			ambients.remove_at(i)
			continue
		am["pos"] += am["vel"] * delta

	# Continuous spawns when active
	if is_running and not reduce_motion:
		_ambient_spawn_accum += delta
		if _ambient_spawn_accum >= 0.08 and ambients.size() < 32:
			_ambient_spawn_accum = 0.0
			_spawn_biome_ambient(cam_x, cam_y, world_id)

		if (p_speed >= 340.0 or active_fever) and speed_lines.size() < 18:
			_speed_line_accum += delta
			var interval = 0.035 if active_fever else 0.07
			if _speed_line_accum >= interval:
				_speed_line_accum = 0.0
				_spawn_speed_line(cam_x, cam_y, p_speed)

	queue_redraw()

func spawn_burst(pos: Vector2, color: Color, count: int = 10, speed: float = 95.0, spread_rad: float = TAU, size_px: float = 2.5, gravity: float = 220.0, life: float = 0.38) -> void:
	var n = mini(count, 24)
	if reduce_motion:
		n = mini(n, 4)
	for _i in range(n):
		if particles.size() >= 180:
			particles.remove_at(0)
		var ang = randf_range(-spread_rad * 0.5, spread_rad * 0.5) - PI * 0.5
		var spd = randf_range(speed * 0.45, speed * 1.15)
		particles.append({
			"pos": pos + Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0)),
			"vel": Vector2(cos(ang), sin(ang)) * spd,
			"color": color,
			"size": randf_range(maxf(1.5, size_px - 0.8), size_px + 0.8),
			"gravity": gravity,
			"age": 0.0,
			"life": randf_range(life * 0.7, life * 1.2)
		})

func spawn_floating_text(pos: Vector2, text: String, color: Color = Color(1.0, 0.92, 0.35), scale_mult: float = 1.0) -> void:
	if popups.size() >= 16:
		popups.remove_at(0)
	popups.append({
		"pos": pos + Vector2(0, -14),
		"text": text,
		"color": color,
		"scale": scale_mult,
		"age": 0.0,
		"life": 0.72
	})

func spawn_shockwave(pos: Vector2, max_radius: float = 140.0, color: Color = Color(0.95, 0.78, 0.25), duration: float = 0.32, width: float = 3.0) -> void:
	if rings.size() >= 12:
		rings.remove_at(0)
	rings.append({
		"pos": pos,
		"max_radius": max_radius,
		"color": color,
		"width": width,
		"age": 0.0,
		"life": duration
	})

func spawn_slash_arc(pos: Vector2, color: Color = Color(0.55, 0.96, 1.0)) -> void:
	if slashes.size() >= 8:
		slashes.remove_at(0)
	slashes.append({
		"pos": pos + Vector2(18, -2),
		"color": color,
		"age": 0.0,
		"life": 0.20
	})

func spawn_afterimage(tex: Texture2D, region_rect: Rect2, world_pos: Vector2, tint: Color = Color(0.35, 0.92, 1.0, 0.55)) -> void:
	if tex == null or reduce_motion:
		return
	if afterimages.size() >= 14:
		afterimages.remove_at(0)
	afterimages.append({
		"tex": tex,
		"region": region_rect,
		"pos": world_pos,
		"tint": tint,
		"age": 0.0,
		"life": 0.20
	})

func _spawn_speed_line(cam_x: float, cam_y: float, p_speed: float) -> void:
	var vx = p_speed * 1.7 + randf_range(120.0, 260.0)
	var sy = cam_y + randf_range(-124.0, 118.0)
	var sx = cam_x + 255.0 + randf_range(0.0, 35.0)
	var col = Color(1.0, 0.88, 0.38, 0.55) if active_fever else Color(0.75, 0.94, 1.0, 0.35)
	speed_lines.append({
		"pos": Vector2(sx, sy),
		"len": randf_range(26.0, 58.0),
		"vx": vx,
		"color": col,
		"age": 0.0,
		"life": 0.28
	})

func _spawn_biome_ambient(cam_x: float, cam_y: float, world_id: String) -> void:
	var pos = Vector2(cam_x + randf_range(-180.0, 260.0), cam_y + randf_range(-125.0, 95.0))
	var vel = Vector2(-40.0, -18.0)
	var col = Color(1.0, 0.96, 0.72, 0.65)
	var sz = 2.0
	match world_id:
		"jungle":
			col = Color(0.45, 1.0, 0.75, 0.75)
			vel = Vector2(randf_range(-35.0, -10.0), randf_range(-24.0, 10.0))
		"frozen":
			pos.y = cam_y - 135.0
			col = Color(0.88, 0.96, 1.0, 0.75)
			vel = Vector2(randf_range(-70.0, -35.0), randf_range(45.0, 85.0))
			sz = 2.5
		"volcanic":
			pos.y = cam_y + randf_range(40.0, 125.0)
			col = Color(1.0, 0.48, 0.14, 0.85)
			vel = Vector2(randf_range(-60.0, -15.0), randf_range(-85.0, -40.0))
			sz = 2.5
		_:
			col = Color(1.0, 0.92, 0.58, 0.55)
			vel = Vector2(randf_range(-45.0, -15.0), randf_range(-14.0, 8.0))

	ambients.append({
		"pos": pos,
		"vel": vel,
		"color": col,
		"size": sz,
		"age": 0.0,
		"life": 1.6
	})

func _draw() -> void:
	# 1. Afterimages (behind bursts)
	for af in afterimages:
		var t = clampf(1.0 - (af["age"] / af["life"]), 0.0, 1.0)
		var c: Color = af["tint"]
		c.a *= t
		var reg: Rect2 = af["region"]
		var dest = Rect2(af["pos"] - reg.size * 0.5, reg.size)
		draw_texture_rect_region(af["tex"], dest, reg, c)

	# 2. Speed lines
	for sp in speed_lines:
		var t = clampf(1.0 - (sp["age"] / sp["life"]), 0.0, 1.0)
		var c: Color = sp["color"]
		c.a *= t
		var p0: Vector2 = sp["pos"]
		draw_line(p0, p0 + Vector2(sp["len"], 0), c, 1.5)

	# 3. Ambient particles
	for am in ambients:
		var ratio = am["age"] / am["life"]
		var fade = sin(clampf(ratio, 0.0, 1.0) * PI)
		var c: Color = am["color"]
		c.a *= fade
		var s: float = am["size"]
		draw_rect(Rect2(am["pos"] - Vector2(s * 0.5, s * 0.5), Vector2(s, s)), c)

	# 4. Active Skill Auras around Player
	if active_shield:
		var pulse = 18.0 + sin(_aura_phase) * 2.0
		draw_arc(player_world_pos, pulse, 0.0, TAU, 16, Color(0.42, 0.92, 1.0, 0.78), 2.0)
		draw_arc(player_world_pos, pulse + 3.0, _aura_phase, _aura_phase + PI, 12, Color(0.85, 0.98, 1.0, 0.5), 1.5)

	if active_magnet:
		var m_r = 12.0 + fmod(_aura_phase * 14.0, 26.0)
		var m_a = clampf(1.0 - (m_r - 12.0) / 26.0, 0.0, 1.0) * 0.65
		draw_arc(player_world_pos, m_r, 0.0, TAU, 20, Color(1.0, 0.38, 0.78, m_a), 1.5)

	if active_time_shard:
		draw_arc(player_world_pos, 22.0, -_aura_phase, -_aura_phase + PI * 1.4, 18, Color(0.55, 0.75, 1.0, 0.7), 1.5)

	if active_fever:
		var f_r = 16.0 + sin(_aura_phase * 2.2) * 3.0
		draw_arc(player_world_pos, f_r, 0.0, TAU, 18, Color(1.0, 0.82, 0.2, 0.75), 2.0)

	# 5. Shockwave rings
	for rg in rings:
		var p = clampf(rg["age"] / rg["life"], 0.0, 1.0)
		var radius = lerpf(8.0, rg["max_radius"], 1.0 - pow(1.0 - p, 2.0))
		var c: Color = rg["color"]
		c.a *= (1.0 - p)
		draw_arc(rg["pos"], radius, 0.0, TAU, 28, c, rg["width"])

	# 6. Bone Blade crescent slash arcs
	for sl in slashes:
		var p = clampf(sl["age"] / sl["life"], 0.0, 1.0)
		var c: Color = sl["color"]
		c.a *= (1.0 - p)
		var r = lerpf(18.0, 48.0, p)
		draw_arc(sl["pos"], r, -0.95, 0.95, 16, c, lerpf(6.0, 1.5, p))
		draw_arc(sl["pos"] + Vector2(6, 0), r * 0.85, -0.8, 0.8, 12, Color(1, 1, 1, c.a * 0.8), 2.0)

	# 7. Crisp square pixel particles
	for pt in particles:
		var t = clampf(1.0 - (pt["age"] / pt["life"]), 0.0, 1.0)
		var c: Color = pt["color"]
		c.a *= t
		var s: float = pt["size"]
		draw_rect(Rect2(pt["pos"] - Vector2(s * 0.5, s * 0.5), Vector2(s, s)), c)

	# 8. World-space Floating Score / Action Popups
	var font = ThemeDB.fallback_font
	if font:
		for pp in popups:
			var t = clampf(1.0 - (pp["age"] / pp["life"]), 0.0, 1.0)
			var c: Color = pp["color"]
			c.a *= minf(1.0, t * 1.4)
			var outline_col = Color(0.05, 0.05, 0.08, c.a)
			var fsize = int(roundf(10.0 * pp["scale"]))
			var txt: String = pp["text"]
			var p: Vector2 = pp["pos"]
			# Pixel crisp shadow outline
			draw_string(font, p + Vector2(1, 1), txt, HORIZONTAL_ALIGNMENT_CENTER, -1, fsize, outline_col)
			draw_string(font, p + Vector2(-1, 0), txt, HORIZONTAL_ALIGNMENT_CENTER, -1, fsize, outline_col)
			draw_string(font, p, txt, HORIZONTAL_ALIGNMENT_CENTER, -1, fsize, c)
