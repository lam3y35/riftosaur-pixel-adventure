class_name ParallaxController
extends ParallaxBackground

@onready var sky_sprite: Sprite2D = get_node_or_null("SkyLayer/SkySprite")
@onready var mountains_sprite: Sprite2D = get_node_or_null("MountainsLayer/MountainsSprite")
@onready var hills_sprite: Sprite2D = get_node_or_null("HillsLayer/HillsSprite")

var current_theme: WorldTheme

var _transition_tween: Tween = null
var _sky_backdrop: ColorRect = null
var _subground_fill: ColorRect = null
var _subground_strata: Sprite2D = null

const SKY_BACKDROP_COLORS: Dictionary = {
	"plains": Color(0.45, 0.74, 0.96, 1.0),
	"jungle": Color(0.18, 0.36, 0.28, 1.0),
	"frozen": Color(0.28, 0.44, 0.62, 1.0),
	"volcanic": Color(0.24, 0.10, 0.08, 1.0)
}

const SUBGROUND_COLORS: Dictionary = {
	"plains": Color(0.24, 0.16, 0.10, 1.0),
	"jungle": Color(0.11, 0.22, 0.13, 1.0),
	"frozen": Color(0.18, 0.30, 0.44, 1.0),
	"volcanic": Color(0.16, 0.07, 0.06, 1.0)
}

const SUBGROUND_STRATA_TINTS: Dictionary = {
	"plains": Color(0.48, 0.34, 0.24, 0.85),
	"jungle": Color(0.26, 0.46, 0.28, 0.85),
	"frozen": Color(0.42, 0.64, 0.84, 0.85),
	"volcanic": Color(0.44, 0.18, 0.16, 0.85)
}

func _ready() -> void:
	# Full-screen sky backdrop behind all parallax layers so default_clear_color never bleeds through
	# on ultrawide monitors, high-jump ascents, or zoomed-out camera frames.
	var sky_back_layer := ParallaxLayer.new()
	sky_back_layer.name = "SkyBackdropLayer"
	sky_back_layer.motion_scale = Vector2.ZERO
	sky_back_layer.z_index = -10
	_sky_backdrop = ColorRect.new()
	_sky_backdrop.name = "SkyBackdrop"
	_sky_backdrop.position = Vector2(-1200.0, -1200.0)
	_sky_backdrop.size = Vector2(4000.0, 2600.0)
	_sky_backdrop.color = SKY_BACKDROP_COLORS["plains"]
	sky_back_layer.add_child(_sky_backdrop)
	add_child(sky_back_layer)
	move_child(sky_back_layer, 0)

	# Tile sky, mountains, and hills across 1440px (3x480) so aspect="expand" and zoom-out never show edges
	for spr in [sky_sprite, mountains_sprite, hills_sprite]:
		if spr:
			spr.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			spr.region_enabled = true
			spr.region_rect = Rect2(0, 0, 1440, 270)
			spr.position.x = -480.0
			var parent_layer := spr.get_parent() as ParallaxLayer
			if parent_layer:
				parent_layer.motion_mirroring = Vector2(1440.0, 0.0)

	# Ensure tall / wide screens never expose sky clear color beneath ground tiles
	var sub_layer := ParallaxLayer.new()
	sub_layer.name = "SubGroundFillLayer"
	sub_layer.motion_scale = Vector2.ZERO
	sub_layer.z_index = -1
	_subground_fill = ColorRect.new()
	_subground_fill.name = "SubGroundFill"
	_subground_fill.position = Vector2(-1200.0, 236.0)
	_subground_fill.size = Vector2(4000.0, 1200.0)
	_subground_fill.color = SUBGROUND_COLORS["plains"]
	sub_layer.add_child(_subground_fill)

	if ResourceLoader.exists("res://assets/sprites/subground_strata.png"):
		_subground_strata = Sprite2D.new()
		_subground_strata.name = "SubGroundStrata"
		_subground_strata.texture = load("res://assets/sprites/subground_strata.png")
		_subground_strata.centered = false
		_subground_strata.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		_subground_strata.region_enabled = true
		_subground_strata.region_rect = Rect2(0, 0, 4000, 384)
		_subground_strata.position = Vector2(-1200.0, 240.0)
		_subground_strata.modulate = SUBGROUND_STRATA_TINTS["plains"]
		sub_layer.add_child(_subground_strata)

	add_child(sub_layer)

func _kill_transition_tween() -> void:
	if _transition_tween and _transition_tween.is_valid():
		_transition_tween.kill()
	_transition_tween = null

func _apply_theme_textures(theme: WorldTheme) -> void:
	current_theme = theme
	if _sky_backdrop and theme and SKY_BACKDROP_COLORS.has(theme.world_id):
		_sky_backdrop.color = SKY_BACKDROP_COLORS[theme.world_id] * theme.ambient_tint
	if _subground_fill and theme and SUBGROUND_COLORS.has(theme.world_id):
		_subground_fill.color = SUBGROUND_COLORS[theme.world_id]
	if _subground_strata and theme and SUBGROUND_STRATA_TINTS.has(theme.world_id):
		_subground_strata.modulate = SUBGROUND_STRATA_TINTS[theme.world_id]
	if sky_sprite and ResourceLoader.exists(theme.sky_texture_path):
		sky_sprite.texture = load(theme.sky_texture_path)
		sky_sprite.modulate = theme.ambient_tint
	if mountains_sprite and ResourceLoader.exists(theme.distant_texture_path):
		mountains_sprite.texture = load(theme.distant_texture_path)
		mountains_sprite.modulate = theme.ambient_tint
	if hills_sprite and ResourceLoader.exists(theme.mid_texture_path):
		hills_sprite.texture = load(theme.mid_texture_path)
		hills_sprite.modulate = theme.ambient_tint

func apply_theme_immediate(theme: WorldTheme) -> void:
	_kill_transition_tween()
	_apply_theme_textures(theme)

func transition_to_theme(theme: WorldTheme, duration: float = 1.5) -> void:
	_kill_transition_tween()
	current_theme = theme
	var tw = create_tween()
	_transition_tween = tw
	if tw:
		var target_tint: Color = theme.ambient_tint if theme else Color(1, 1, 1, 1)
		var sky_veil := Color(0.18, 0.15, 0.30, 1.0)
		tw.set_parallel(true)
		# Keep sky_sprite opaque (a=1.0) so default_clear_color never bleeds through dark skies
		if sky_sprite:
			tw.tween_property(sky_sprite, "modulate", sky_veil, duration * 0.4)
		if mountains_sprite:
			tw.tween_property(mountains_sprite, "modulate:a", 0.25, duration * 0.4)
		if hills_sprite:
			tw.tween_property(hills_sprite, "modulate:a", 0.25, duration * 0.4)

		tw.chain().tween_callback(func():
			# Swap textures mid-fade without killing _transition_tween itself
			_apply_theme_textures(theme)
			if sky_sprite: sky_sprite.modulate = sky_veil
			if mountains_sprite: mountains_sprite.modulate.a = 0.25
			if hills_sprite: hills_sprite.modulate.a = 0.25
		)

		tw.chain()
		tw.set_parallel(true)
		if sky_sprite:
			tw.tween_property(sky_sprite, "modulate", target_tint, duration * 0.6)
		if mountains_sprite:
			tw.tween_property(mountains_sprite, "modulate:a", target_tint.a, duration * 0.6)
		if hills_sprite:
			tw.tween_property(hills_sprite, "modulate:a", target_tint.a, duration * 0.6)
	else:
		apply_theme_immediate(theme)
