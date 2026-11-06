class_name ParallaxController
extends ParallaxBackground

@onready var sky_sprite: Sprite2D = get_node_or_null("SkyLayer/SkySprite")
@onready var mountains_sprite: Sprite2D = get_node_or_null("MountainsLayer/MountainsSprite")
@onready var hills_sprite: Sprite2D = get_node_or_null("HillsLayer/HillsSprite")

var current_theme: WorldTheme

func apply_theme_immediate(theme: WorldTheme) -> void:
	current_theme = theme
	if sky_sprite and ResourceLoader.exists(theme.sky_texture_path):
		sky_sprite.texture = load(theme.sky_texture_path)
		sky_sprite.modulate = theme.ambient_tint
	if mountains_sprite and ResourceLoader.exists(theme.distant_texture_path):
		mountains_sprite.texture = load(theme.distant_texture_path)
		mountains_sprite.modulate = theme.ambient_tint
	if hills_sprite and ResourceLoader.exists(theme.mid_texture_path):
		hills_sprite.texture = load(theme.mid_texture_path)
		hills_sprite.modulate = theme.ambient_tint

func transition_to_theme(theme: WorldTheme, duration: float = 1.5) -> void:
	current_theme = theme
	var tw = create_tween()
	if tw:
		tw.set_parallel(true)
		if sky_sprite:
			tw.tween_property(sky_sprite, "modulate:a", 0.3, duration * 0.4)
		if mountains_sprite:
			tw.tween_property(mountains_sprite, "modulate:a", 0.3, duration * 0.4)
		if hills_sprite:
			tw.tween_property(hills_sprite, "modulate:a", 0.3, duration * 0.4)

		tw.chain().tween_callback(func():
			apply_theme_immediate(theme)
		)

		if sky_sprite:
			tw.tween_property(sky_sprite, "modulate:a", 1.0, duration * 0.6)
		if mountains_sprite:
			tw.tween_property(mountains_sprite, "modulate:a", 1.0, duration * 0.6)
		if hills_sprite:
			tw.tween_property(hills_sprite, "modulate:a", 1.0, duration * 0.6)
	else:
		apply_theme_immediate(theme)
