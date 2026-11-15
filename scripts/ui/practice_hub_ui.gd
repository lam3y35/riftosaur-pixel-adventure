class_name PracticeHubUI
extends Control

const SkillManagerScript = preload("res://scripts/systems/skill_manager.gd")

signal start_live_tutorial_requested()
signal skip_to_practice_requested()
signal exit_to_menu_requested()
signal test_skill_requested(skill_type: int)
signal map_skills_updated(enabled_skills: Array[int])
signal section_practice_requested(chunk_index: int, section_name: String)
signal random_practice_requested()
signal play_custom_map_requested(map_data: Dictionary)
signal modal_opened()
signal modal_closed()

const PRACTICE_SECTIONS: Array[Dictionary] = [
	{"chunk_index": 5, "id": "crate_step", "name": "Crate + Cactus", "desc": "Light tap hits cactus; hold Jump to clear both or land on crate first."},
	{"chunk_index": 4, "id": "jump_and_slide", "name": "Jump & Slide Combo", "desc": "Tap-jump the low cactus then immediately slide or dive under the arch."},
	{"chunk_index": 2, "id": "overhang", "name": "Stone Overhang", "desc": "Duck/Slide early to pass safely under low stone arches."},
	{"chunk_index": 3, "id": "double_low", "name": "Double Cactus Rhythm", "desc": "Hold Jump slightly longer for a wider arc across two cacti."},
	{"chunk_index": 6, "id": "triple_low", "name": "Triple Cactus Hurdles", "desc": "Full held Jump or Air Dash / Stone Shield clears the triple row."},
	{"chunk_index": 7, "id": "double_crate", "name": "Double Crate Stairway", "desc": "Climb step-by-step with short taps, or vault over with a full hold."},
	{"chunk_index": 10, "id": "bounce_chain", "name": "Bounce Pad Chain", "desc": "Hit the spring stump and ride the launch pad chain into the sky."},
	{"chunk_index": 9, "id": "multi_tier", "name": "Multi-Tier Platforms", "desc": "Jump up through one-way platforms, or press Down to drop through."},
	{"chunk_index": 11, "id": "wind_vent", "name": "Wind Vent Ascent", "desc": "Ride the updraft vent to reach the high terrace bypass."},
	{"chunk_index": 12, "id": "pterodactyl", "name": "Airborne Pterodactyl", "desc": "Stay low or slide under high flyers, or snipe with Boomerang."},
	{"chunk_index": 13, "id": "crawler_barrier", "name": "Crawler & Barrier", "desc": "Slash breakable barriers with Bone Blade or leap clean over."},
	{"chunk_index": 1, "id": "single_low", "name": "Basic Cactus Hop", "desc": "Master short tap vs held jump timing on a single cactus."}
]

const BUILDER_PALETTE: Array[Dictionary] = [
	{"id": "cactus", "label": "Cactus", "color": Color(0.25, 0.82, 0.35), "default_y": 230.0, "ground_locked": true},
	{"id": "overhang", "label": "Arch", "color": Color(0.65, 0.58, 0.48), "default_y": 230.0, "ground_locked": true},
	{"id": "crate", "label": "Crate", "color": Color(0.82, 0.55, 0.25), "default_y": 230.0, "ground_locked": true},
	{"id": "barrier", "label": "Barrier", "color": Color(0.72, 0.38, 0.22), "default_y": 216.0, "ground_locked": true},
	{"id": "crawler", "label": "Crawler", "color": Color(0.95, 0.35, 0.35), "default_y": 222.0, "ground_locked": true},
	{"id": "flyer", "label": "Flyer", "color": Color(0.92, 0.45, 0.78), "default_y": 156.0, "ground_locked": false},
	{"id": "lava", "label": "Lava", "color": Color(1.0, 0.38, 0.12), "default_y": 230.0, "ground_locked": true},
	{"id": "trap", "label": "Trap", "color": Color(1.0, 0.85, 0.18), "default_y": 212.0, "ground_locked": false},
	{"id": "platform", "label": "Platform", "color": Color(0.45, 0.78, 0.95), "default_y": 172.0, "ground_locked": false},
	{"id": "bounce", "label": "Bounce", "color": Color(0.95, 0.85, 0.25), "default_y": 230.0, "ground_locked": true},
	{"id": "wind", "label": "Wind", "color": Color(0.55, 0.95, 0.95), "default_y": 230.0, "ground_locked": true},
	{"id": "gem", "label": "Gem", "color": Color(1.0, 0.78, 0.15), "default_y": 176.0, "ground_locked": false},
	{"id": "skill", "label": "Skill", "color": Color(0.75, 0.45, 1.0), "default_y": 180.0, "ground_locked": false},
	{"id": "eraser", "label": "Erase", "color": Color(0.9, 0.2, 0.2), "default_y": 216.0, "ground_locked": false}
]

const ENEMIES_GUIDE: Array[Dictionary] = [
	{"id": "cactus", "name": "Cactus & Spikes", "where": "GROUND", "action": "TAP JUMP", "desc": "Spawns on ground track. Short tap clears single cactus; hold slightly longer for double/triple.", "color": Color(0.28, 0.88, 0.38), "anim": "jump_low"},
	{"id": "crate", "name": "Tall Crate / Stack", "where": "GROUND (TALL)", "action": "HOLD JUMP / CLIMB", "desc": "Higher solid block. Hold Jump longer for full height or hop onto its top surface.", "color": Color(0.88, 0.56, 0.22), "anim": "jump_high"},
	{"id": "overhang", "name": "Stone Overhang Arch", "where": "ABOVE HEAD", "action": "HOLD SLIDE / DIVE", "desc": "Hangs overhead with open gap beneath. Slide early or fast-dive in mid-air to duck under.", "color": Color(0.74, 0.66, 0.54), "anim": "slide"},
	{"id": "crawler", "name": "Armored Crawler", "where": "GROUND PATROL", "action": "STOMP TOP OR JUMP", "desc": "Scuttles along the floor. Jump cleanly over OR land on its top shell for a bounce kill!", "color": Color(0.96, 0.34, 0.34), "anim": "stomp"},
	{"id": "flyer", "name": "Sky Pterodactyl", "where": "HIGH / MID AIR", "action": "SLIDE OR STOMP", "desc": "Flies above ground lane. Duck/slide under low swoops, stay grounded under high flyers, or Boomerang!", "color": Color(0.92, 0.45, 0.78), "anim": "duck_under"},
	{"id": "barrier", "name": "Wooden Barrier", "where": "GROUND WALL", "action": "BONE BLADE / JUMP", "desc": "Sturdy barricade blocking the lane. Shatter it with Bone Blade/Dash or leap clean over.", "color": Color(0.78, 0.42, 0.22), "anim": "slash"},
	{"id": "lava", "name": "Volcanic Lava Pit", "where": "GROUND GAP (LAVA)", "action": "WIDE JUMP / BOUNCE", "desc": "Exclusive to Volcanic biome! Hold Jump for full arc or launch from a nearby bounce pad.", "color": Color(1.0, 0.38, 0.12), "anim": "lava_gap"},
	{"id": "traps", "name": "4 Hazard Traps", "where": "GROUND / LOW AIR", "action": "AVOID (4 EFFECTS)", "desc": "Yellow ▲ Speed Surge • Orange ▼ Heavy Gravity • Cyan ◆ Vision Glitch • Red ■ Skill Jam!", "color": Color(1.0, 0.85, 0.20), "anim": "avoid_trap"},
	{"id": "platforms", "name": "Platforms, Bounce & Vents", "where": "SKY & GROUND", "action": "RIDE / HOP HIGHER", "desc": "One-way shelves, spring pads & air vents carry you onto safe sky routes above danger.", "color": Color(0.45, 0.88, 0.98), "anim": "bounce_up"}
]

var save_service: SaveService = null

# Overlays & Panels
var entry_panel: PanelContainer
var tutorial_banner: PanelContainer
var tutorial_step_title: Label
var tutorial_step_body: Label
var tutorial_step_status: Label
var tutorial_icon_rect: ColorRect
var tutorial_icon_label: Label
var tutorial_skip_btn: Button

var hint_banner: PanelContainer
var hint_label: Label
var _hint_timer: float = 0.0

var practice_bar: PanelContainer
var practice_status_label: Label

var skills_lab_dialog: PanelContainer
var skills_list_vbox: VBoxContainer
var skills_cap_label: Label
var _skill_checkboxes: Dictionary = {}

var section_dialog: PanelContainer
var section_list_vbox: VBoxContainer

var enemies_dialog: PanelContainer
var enemies_list_vbox: VBoxContainer

var builder_dialog: PanelContainer
var builder_name_edit: LineEdit
var builder_world_idx: int = 0
var builder_world_btn: Button
var builder_speed_idx: int = 1
var builder_speed_btn: Button
var builder_immortal_btn: Button
var builder_immortal: bool = false
var builder_length_idx: int = 1
var builder_len_btn: Button
var builder_linked_next_id: String = ""
var builder_link_btn: Button
var builder_selected_tool: String = "cactus"
var builder_trap_type: int = 0
var builder_palette_btns: Dictionary = {}
var builder_canvas: Control
var builder_items: Array[Dictionary] = []
var builder_saved_maps_hbox: HBoxContainer
var builder_info_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_sync_viewport_rect()
	if get_viewport() and not get_viewport().size_changed.is_connected(_sync_viewport_rect):
		get_viewport().size_changed.connect(_sync_viewport_rect)
	hide_all()

func _sync_viewport_rect() -> void:
	var vp := get_viewport()
	if vp == null:
		return
	var vis: Rect2 = vp.get_visible_rect()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if practice_bar:
		var bar_right: float = clampf(vis.size.x - 138.0, 230.0, 385.0)
		practice_bar.offset_left = 6.0
		practice_bar.offset_top = 3.0
		practice_bar.offset_right = bar_right
		practice_bar.offset_bottom = 28.0
	_clamp_panel_to_viewport(entry_panel, Vector2(380.0, 196.0), vis.size)
	_clamp_panel_to_viewport(skills_lab_dialog, Vector2(444.0, 240.0), vis.size)
	_clamp_panel_to_viewport(section_dialog, Vector2(420.0, 236.0), vis.size)
	_clamp_panel_to_viewport(enemies_dialog, Vector2(448.0, 244.0), vis.size)
	_clamp_panel_to_viewport(builder_dialog, Vector2(464.0, 250.0), vis.size)

func _clamp_panel_to_viewport(p: Control, target_size: Vector2, vp_size: Vector2) -> void:
	if p == null:
		return
	var w: float = minf(target_size.x, maxf(280.0, vp_size.x - 16.0))
	var h: float = minf(target_size.y, maxf(160.0, vp_size.y - 16.0))
	p.anchor_left = 0.5
	p.anchor_right = 0.5
	p.anchor_top = 0.5
	p.anchor_bottom = 0.5
	p.offset_left = -w * 0.5
	p.offset_right = w * 0.5
	p.offset_top = -h * 0.5
	p.offset_bottom = h * 0.5
	p.size = Vector2(w, h)
	p.position = (vp_size - Vector2(w, h)) * 0.5

func bind_save_service(sv: SaveService) -> void:
	save_service = sv

func _process(delta: float) -> void:
	if hint_banner and hint_banner.visible and _hint_timer > 0.0:
		_hint_timer -= delta
		if _hint_timer <= 0.0:
			hint_banner.visible = false

func hide_all() -> void:
	_hint_timer = 0.0
	if entry_panel: entry_panel.visible = false
	if tutorial_banner: tutorial_banner.visible = false
	if hint_banner: hint_banner.visible = false
	if practice_bar: practice_bar.visible = false
	if skills_lab_dialog: skills_lab_dialog.visible = false
	if section_dialog: section_dialog.visible = false
	if enemies_dialog: enemies_dialog.visible = false
	if builder_dialog: builder_dialog.visible = false

func show_entry_choice() -> void:
	hide_all()
	_sync_viewport_rect()
	if entry_panel:
		entry_panel.visible = true

func hide_entry_choice() -> void:
	if entry_panel:
		entry_panel.visible = false

func show_practice_bar(mode_text: String = "FREE PRACTICE • NO DEATH") -> void:
	_sync_viewport_rect()
	if practice_bar:
		practice_bar.visible = true
	if practice_status_label:
		practice_status_label.text = mode_text

func hide_practice_bar() -> void:
	if practice_bar:
		practice_bar.visible = false

func show_tutorial_step(title_txt: String, body_txt: String, badge_txt: String, badge_color: Color, status_txt: String = "Try it now!") -> void:
	_sync_viewport_rect()
	if hint_banner:
		hint_banner.visible = false
	if tutorial_banner:
		tutorial_banner.visible = true
	if tutorial_step_title:
		tutorial_step_title.text = title_txt
	if tutorial_step_body:
		tutorial_step_body.text = body_txt
	if tutorial_step_status:
		tutorial_step_status.text = status_txt
		tutorial_step_status.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	if tutorial_icon_rect:
		tutorial_icon_rect.color = badge_color
	if tutorial_icon_label:
		tutorial_icon_label.text = badge_txt

func update_tutorial_status(status_txt: String, completed: bool = false) -> void:
	if tutorial_step_status:
		tutorial_step_status.text = status_txt
		tutorial_step_status.add_theme_color_override("font_color", Color(0.45, 1.0, 0.55) if completed else Color(1.0, 0.88, 0.35))

func hide_tutorial_banner() -> void:
	if tutorial_banner:
		tutorial_banner.visible = false

func show_adaptive_hint(text_msg: String, duration: float = 5.5) -> void:
	if tutorial_banner and tutorial_banner.visible:
		return
	_sync_viewport_rect()
	if hint_banner and hint_label:
		hint_label.text = "💡 TIP: " + text_msg
		hint_banner.visible = true
		_hint_timer = duration

func hide_adaptive_hint() -> void:
	if hint_banner:
		hint_banner.visible = false
	_hint_timer = 0.0

func open_skills_lab() -> void:
	_sync_viewport_rect()
	_refresh_skills_lab()
	if skills_lab_dialog:
		skills_lab_dialog.visible = true
	modal_opened.emit()

func close_skills_lab() -> void:
	if skills_lab_dialog:
		skills_lab_dialog.visible = false
	modal_closed.emit()

func open_section_practice() -> void:
	_sync_viewport_rect()
	if section_dialog:
		section_dialog.visible = true
	modal_opened.emit()

func close_section_practice() -> void:
	if section_dialog:
		section_dialog.visible = false
	modal_closed.emit()

func open_map_builder() -> void:
	_sync_viewport_rect()
	_refresh_saved_maps_bar()
	_refresh_link_btn_text()
	_update_builder_info()
	if builder_canvas:
		builder_canvas.queue_redraw()
	if builder_dialog:
		builder_dialog.visible = true
	modal_opened.emit()

func close_map_builder() -> void:
	if builder_dialog:
		builder_dialog.visible = false
	modal_closed.emit()

func open_enemies_guide() -> void:
	_sync_viewport_rect()
	if enemies_dialog:
		enemies_dialog.visible = true
	modal_opened.emit()

func close_enemies_guide() -> void:
	if enemies_dialog:
		enemies_dialog.visible = false
	modal_closed.emit()

func close_active_modal() -> bool:
	if builder_dialog and builder_dialog.visible:
		close_map_builder()
		return true
	if enemies_dialog and enemies_dialog.visible:
		close_enemies_guide()
		return true
	if section_dialog and section_dialog.visible:
		close_section_practice()
		return true
	if skills_lab_dialog and skills_lab_dialog.visible:
		close_skills_lab()
		return true
	if entry_panel and entry_panel.visible:
		hide_all()
		exit_to_menu_requested.emit()
		return true
	return false

func has_modal_open() -> bool:
	return (
		(entry_panel != null and entry_panel.visible)
		or (skills_lab_dialog != null and skills_lab_dialog.visible)
		or (section_dialog != null and section_dialog.visible)
		or (enemies_dialog != null and enemies_dialog.visible)
		or (builder_dialog != null and builder_dialog.visible)
	)

func _make_panel_style(bg: Color, border: Color) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb

func _style_btn(btn: Button, bg: Color, border: Color, font_size: int = 9) -> void:
	btn.focus_mode = Control.FOCUS_NONE
	var n = _make_panel_style(bg, border)
	n.content_margin_left = 7
	n.content_margin_right = 7
	n.content_margin_top = 3
	n.content_margin_bottom = 3
	btn.add_theme_stylebox_override("normal", n)
	var h = n.duplicate()
	h.bg_color = bg.lightened(0.14)
	btn.add_theme_stylebox_override("hover", h)
	var p = n.duplicate()
	p.bg_color = bg.darkened(0.15)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", Color(0.97, 0.96, 0.92))

func _build_ui() -> void:
	_build_entry_panel()
	_build_tutorial_banner()
	_build_hint_banner()
	_build_practice_bar()
	_build_skills_lab_dialog()
	_build_section_dialog()
	_build_enemies_dialog()
	_build_builder_dialog()

func _build_entry_panel() -> void:
	entry_panel = PanelContainer.new()
	entry_panel.name = "PracticeEntryPanel"
	entry_panel.anchor_left = 0.5
	entry_panel.anchor_right = 0.5
	entry_panel.anchor_top = 0.5
	entry_panel.anchor_bottom = 0.5
	entry_panel.offset_left = -178
	entry_panel.offset_right = 178
	entry_panel.offset_top = -94
	entry_panel.offset_bottom = 94
	entry_panel.clip_contents = true
	entry_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.08, 0.11, 0.16, 0.97), Color(0.35, 0.78, 0.95)))
	add_child(entry_panel)

	var vb = VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.custom_minimum_size = Vector2(336, 0)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 6)
	entry_panel.add_child(vb)

	var title = Label.new()
	title.text = "TUTORIAL & PRACTICE"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vb.add_child(title)

	var sub = Label.new()
	sub.text = "Live 7-Step Tutorial • Continuous Shield • Max 4 Skills Lab • Enemies Guide • Maps"
	sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub.custom_minimum_size = Vector2(320, 0)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_font_size_override("font_size", 8)
	sub.add_theme_color_override("font_color", Color(0.8, 0.88, 0.96))
	vb.add_child(sub)

	var main_btns = HBoxContainer.new()
	main_btns.alignment = BoxContainer.ALIGNMENT_CENTER
	main_btns.add_theme_constant_override("separation", 8)
	vb.add_child(main_btns)

	var tut_btn = Button.new()
	tut_btn.name = "StartLiveTutorialBtn"
	tut_btn.text = "▶ START LIVE TUTORIAL"
	_style_btn(tut_btn, Color(0.16, 0.52, 0.28), Color(0.4, 0.95, 0.55), 10)
	tut_btn.pressed.connect(func():
		hide_entry_choice()
		start_live_tutorial_requested.emit()
	)
	main_btns.add_child(tut_btn)

	var skip_btn = Button.new()
	skip_btn.name = "SkipToPracticeBtn"
	skip_btn.text = "⏭ SKIP TO PRACTICE"
	_style_btn(skip_btn, Color(0.18, 0.36, 0.58), Color(0.45, 0.78, 1.0), 10)
	skip_btn.pressed.connect(func():
		hide_entry_choice()
		skip_to_practice_requested.emit()
	)
	main_btns.add_child(skip_btn)

	var tools_row = HBoxContainer.new()
	tools_row.alignment = BoxContainer.ALIGNMENT_CENTER
	tools_row.add_theme_constant_override("separation", 5)
	vb.add_child(tools_row)

	var skills_btn = Button.new()
	skills_btn.name = "EntrySkillsLabBtn"
	skills_btn.text = "⚡ SKILLS"
	_style_btn(skills_btn, Color(0.32, 0.22, 0.52), Color(0.75, 0.52, 1.0), 8)
	skills_btn.pressed.connect(open_skills_lab)
	tools_row.add_child(skills_btn)

	var sec_btn = Button.new()
	sec_btn.name = "EntrySectionsBtn"
	sec_btn.text = "🎯 SECTIONS"
	_style_btn(sec_btn, Color(0.38, 0.28, 0.16), Color(0.95, 0.68, 0.32), 8)
	sec_btn.pressed.connect(open_section_practice)
	tools_row.add_child(sec_btn)

	var enm_btn = Button.new()
	enm_btn.name = "EntryEnemiesBtn"
	enm_btn.text = "👾 ENEMIES"
	_style_btn(enm_btn, Color(0.46, 0.18, 0.28), Color(1.0, 0.48, 0.65), 8)
	enm_btn.pressed.connect(open_enemies_guide)
	tools_row.add_child(enm_btn)

	var bld_btn = Button.new()
	bld_btn.name = "EntryBuilderBtn"
	bld_btn.text = "🛠 BUILDER"
	_style_btn(bld_btn, Color(0.22, 0.36, 0.34), Color(0.45, 0.9, 0.82), 8)
	bld_btn.pressed.connect(open_map_builder)
	tools_row.add_child(bld_btn)

	var exit_btn = Button.new()
	exit_btn.name = "EntryExitMenuBtn"
	exit_btn.text = "🏠 MAIN MENU"
	_style_btn(exit_btn, Color(0.25, 0.25, 0.30), Color(0.6, 0.6, 0.7), 9)
	exit_btn.pressed.connect(func():
		hide_all()
		exit_to_menu_requested.emit()
	)
	vb.add_child(exit_btn)

func _build_tutorial_banner() -> void:
	tutorial_banner = PanelContainer.new()
	tutorial_banner.name = "LiveTutorialBanner"
	tutorial_banner.anchor_left = 0.5
	tutorial_banner.anchor_right = 0.5
	tutorial_banner.anchor_top = 0.0
	tutorial_banner.offset_left = -184
	tutorial_banner.offset_right = 184
	tutorial_banner.offset_top = 60
	tutorial_banner.offset_bottom = 128
	tutorial_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_banner.add_theme_stylebox_override("panel", _make_panel_style(Color(0.06, 0.10, 0.18, 0.92), Color(0.38, 0.85, 1.0)))
	add_child(tutorial_banner)

	var hb = HBoxContainer.new()
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_theme_constant_override("separation", 8)
	tutorial_banner.add_child(hb)

	tutorial_icon_rect = ColorRect.new()
	tutorial_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_icon_rect.custom_minimum_size = Vector2(48, 44)
	tutorial_icon_rect.color = Color(0.2, 0.55, 0.85)
	hb.add_child(tutorial_icon_rect)

	tutorial_icon_label = Label.new()
	tutorial_icon_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tutorial_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tutorial_icon_label.add_theme_font_size_override("font_size", 9)
	tutorial_icon_rect.add_child(tutorial_icon_label)

	var vb = VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 2)
	hb.add_child(vb)

	var top_row = HBoxContainer.new()
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(top_row)

	tutorial_step_title = Label.new()
	tutorial_step_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tutorial_step_title.clip_text = true
	tutorial_step_title.add_theme_font_size_override("font_size", 10)
	tutorial_step_title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.32))
	top_row.add_child(tutorial_step_title)

	tutorial_skip_btn = Button.new()
	tutorial_skip_btn.text = "SKIP ⏭"
	_style_btn(tutorial_skip_btn, Color(0.25, 0.28, 0.36), Color(0.6, 0.7, 0.85), 8)
	tutorial_skip_btn.pressed.connect(func():
		hide_tutorial_banner()
		skip_to_practice_requested.emit()
	)
	top_row.add_child(tutorial_skip_btn)

	tutorial_step_body = Label.new()
	tutorial_step_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tutorial_step_body.custom_minimum_size = Vector2(220, 0)
	tutorial_step_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_step_body.add_theme_font_size_override("font_size", 8)
	tutorial_step_body.add_theme_color_override("font_color", Color(0.95, 0.96, 0.98))
	vb.add_child(tutorial_step_body)

	tutorial_step_status = Label.new()
	tutorial_step_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tutorial_step_status.clip_text = true
	tutorial_step_status.add_theme_font_size_override("font_size", 8)
	tutorial_step_status.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	vb.add_child(tutorial_step_status)

func _build_hint_banner() -> void:
	hint_banner = PanelContainer.new()
	hint_banner.name = "AdaptiveHintBanner"
	hint_banner.anchor_left = 0.5
	hint_banner.anchor_right = 0.5
	hint_banner.anchor_top = 0.0
	hint_banner.offset_left = -180
	hint_banner.offset_right = 180
	hint_banner.offset_top = 60
	hint_banner.offset_bottom = 102
	hint_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_banner.add_theme_stylebox_override("panel", _make_panel_style(Color(0.18, 0.12, 0.05, 0.94), Color(1.0, 0.72, 0.2)))
	add_child(hint_banner)

	var hb = HBoxContainer.new()
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_banner.add_child(hb)

	hint_label = Label.new()
	hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_label.custom_minimum_size = Vector2(260, 0)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.add_theme_font_size_override("font_size", 8)
	hint_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.72))
	hb.add_child(hint_label)

	var close_b = Button.new()
	close_b.text = "✕"
	_style_btn(close_b, Color(0.32, 0.2, 0.1), Color(0.9, 0.6, 0.25), 8)
	close_b.pressed.connect(hide_adaptive_hint)
	hb.add_child(close_b)

func _build_practice_bar() -> void:
	practice_bar = PanelContainer.new()
	practice_bar.name = "PracticeQuickBar"
	practice_bar.anchor_left = 0.0
	practice_bar.anchor_top = 0.0
	practice_bar.offset_left = 6
	practice_bar.offset_top = 3
	practice_bar.offset_right = 336
	practice_bar.offset_bottom = 28
	practice_bar.clip_contents = true
	var bar_sb = _make_panel_style(Color(0.08, 0.14, 0.22, 0.9), Color(0.35, 0.75, 0.95))
	bar_sb.content_margin_left = 6
	bar_sb.content_margin_right = 6
	bar_sb.content_margin_top = 2
	bar_sb.content_margin_bottom = 2
	practice_bar.add_theme_stylebox_override("panel", bar_sb)
	add_child(practice_bar)

	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 3)
	practice_bar.add_child(hb)

	practice_status_label = Label.new()
	practice_status_label.text = "🛡 PRACTICE"
	practice_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	practice_status_label.clip_text = true
	practice_status_label.add_theme_font_size_override("font_size", 7)
	practice_status_label.add_theme_color_override("font_color", Color(0.55, 0.92, 1.0))
	hb.add_child(practice_status_label)

	var b_skills = Button.new()
	b_skills.text = "⚡Skills"
	_style_btn(b_skills, Color(0.28, 0.2, 0.45), Color(0.7, 0.5, 0.95), 7)
	b_skills.pressed.connect(open_skills_lab)
	hb.add_child(b_skills)

	var b_sec = Button.new()
	b_sec.text = "🎯Sections"
	_style_btn(b_sec, Color(0.35, 0.25, 0.15), Color(0.9, 0.65, 0.3), 7)
	b_sec.pressed.connect(open_section_practice)
	hb.add_child(b_sec)

	var b_enm = Button.new()
	b_enm.text = "👾Enemies"
	_style_btn(b_enm, Color(0.45, 0.18, 0.28), Color(0.98, 0.48, 0.65), 7)
	b_enm.pressed.connect(open_enemies_guide)
	hb.add_child(b_enm)

	var b_bld = Button.new()
	b_bld.text = "🛠Builder"
	_style_btn(b_bld, Color(0.18, 0.34, 0.32), Color(0.4, 0.85, 0.78), 7)
	b_bld.pressed.connect(open_map_builder)
	hb.add_child(b_bld)

func _build_skills_lab_dialog() -> void:
	skills_lab_dialog = PanelContainer.new()
	skills_lab_dialog.name = "SkillsLabDialog"
	skills_lab_dialog.anchor_left = 0.5
	skills_lab_dialog.anchor_right = 0.5
	skills_lab_dialog.anchor_top = 0.5
	skills_lab_dialog.anchor_bottom = 0.5
	skills_lab_dialog.offset_left = -222
	skills_lab_dialog.offset_right = 222
	skills_lab_dialog.offset_top = -120
	skills_lab_dialog.offset_bottom = 120
	skills_lab_dialog.clip_contents = true
	skills_lab_dialog.add_theme_stylebox_override("panel", _make_panel_style(Color(0.08, 0.09, 0.15, 0.98), Color(0.72, 0.48, 1.0)))
	add_child(skills_lab_dialog)

	var vb = VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 5)
	skills_lab_dialog.add_child(vb)

	var header = HBoxContainer.new()
	vb.add_child(header)

	var ttl = Label.new()
	ttl.text = "⚡ SKILLS LAB • PICK MAX %d FOR RUNS" % SaveService.MAX_ENABLED_MAP_SKILLS
	ttl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ttl.clip_text = true
	ttl.add_theme_font_size_override("font_size", 10)
	ttl.add_theme_color_override("font_color", Color(0.88, 0.72, 1.0))
	header.add_child(ttl)

	var all_b = Button.new()
	all_b.text = "4-STARTER"
	_style_btn(all_b, Color(0.2, 0.42, 0.28), Color(0.45, 0.88, 0.55), 8)
	all_b.pressed.connect(func(): _set_all_map_skills(true))
	header.add_child(all_b)

	var clr_b = Button.new()
	clr_b.text = "CLEAR"
	_style_btn(clr_b, Color(0.42, 0.2, 0.2), Color(0.88, 0.45, 0.45), 8)
	clr_b.pressed.connect(func(): _set_all_map_skills(false))
	header.add_child(clr_b)

	var cls_b = Button.new()
	cls_b.text = "CLOSE"
	_style_btn(cls_b, Color(0.26, 0.28, 0.34), Color(0.65, 0.68, 0.75), 8)
	cls_b.pressed.connect(close_skills_lab)
	header.add_child(cls_b)

	skills_cap_label = Label.new()
	skills_cap_label.text = "Selected: 0 / %d max • Rare tiers spawn every greater meter interval. TEST gives infinite arena uses!" % SaveService.MAX_ENABLED_MAP_SKILLS
	skills_cap_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skills_cap_label.custom_minimum_size = Vector2(380, 0)
	skills_cap_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	skills_cap_label.add_theme_font_size_override("font_size", 7)
	skills_cap_label.add_theme_color_override("font_color", Color(0.75, 0.88, 0.96))
	vb.add_child(skills_cap_label)

	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	vb.add_child(scroll)

	skills_list_vbox = VBoxContainer.new()
	skills_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skills_list_vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(skills_list_vbox)

func _refresh_skills_lab() -> void:
	if not skills_list_vbox:
		return
	for c in skills_list_vbox.get_children():
		c.queue_free()
	_skill_checkboxes.clear()

	var enabled: Array[int] = save_service.get_enabled_map_skills() if save_service else [1, 2, 3, 5]
	var max_sel: int = SaveService.MAX_ENABLED_MAP_SKILLS
	var at_cap: bool = enabled.size() >= max_sel
	if skills_cap_label:
		skills_cap_label.text = "Selected: %d / %d max • %s" % [
			enabled.size(),
			max_sel,
			("Max 4 reached (uncheck 1 to swap) • TEST = infinite skill arena!" if at_cap else "Higher tiers drop at rarer meter intervals • TEST = infinite skill arena!")
		]
		skills_cap_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35) if at_cap else Color(0.75, 0.88, 0.96))

	var total_weight: int = 0
	for sk_type in SkillManagerScript.get_all_skill_types():
		if enabled.has(int(sk_type)):
			total_weight += int(SkillManagerScript.SKILL_DATA[sk_type].get("spawn_weight", 10))

	for sk_type in SkillManagerScript.get_all_skill_types():
		var sk_id: int = int(sk_type)
		var info: Dictionary = SkillManagerScript.SKILL_DATA[sk_type]
		var tier: int = int(info.get("tier", 1))
		var tier_col: Color = SkillManagerScript.get_tier_color(tier)
		var weight: int = int(info.get("spawn_weight", 10))
		var pct: float = (float(weight) / float(maxi(total_weight, 1))) * 100.0 if enabled.has(sk_id) else 0.0

		var row_panel = PanelContainer.new()
		row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row_panel.clip_contents = true
		row_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.12, 0.14, 0.22), tier_col * 0.7))
		skills_list_vbox.add_child(row_panel)

		var hb = HBoxContainer.new()
		hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_theme_constant_override("separation", 6)
		row_panel.add_child(hb)

		var chk = CheckBox.new()
		chk.focus_mode = Control.FOCUS_NONE
		chk.button_pressed = enabled.has(sk_id)
		chk.disabled = at_cap and not enabled.has(sk_id)
		chk.text = ""
		chk.toggled.connect(func(pressed: bool): _on_skill_toggled(sk_id, pressed))
		hb.add_child(chk)
		_skill_checkboxes[sk_id] = chk

		var text_vb = VBoxContainer.new()
		text_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(text_vb)

		var dur_val: float = float(info.get("duration", 0.0))
		var dur_str := "Passive" if dur_val < 0.0 else ("Instant" if dur_val == 0.0 else "%.1fs" % dur_val)
		var rate_str := (" | Drop: %.0f%%" % pct) if enabled.has(sk_id) else (" | Max 4 Picked" if at_cap else " | Unselected")

		var name_lbl = Label.new()
		name_lbl.text = "%s [%s] • Dur: %s%s" % [info.get("name", "Skill"), info.get("tier_name", "Common"), dur_str, rate_str]
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.clip_text = true
		name_lbl.add_theme_font_size_override("font_size", 8)
		name_lbl.add_theme_color_override("font_color", tier_col)
		text_vb.add_child(name_lbl)

		var desc_lbl = Label.new()
		desc_lbl.text = str(info.get("desc", ""))
		desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_size_override("font_size", 7)
		desc_lbl.add_theme_color_override("font_color", Color(0.84, 0.88, 0.94))
		text_vb.add_child(desc_lbl)

		var test_btn = Button.new()
		test_btn.text = "TEST ∞"
		_style_btn(test_btn, Color(0.18, 0.45, 0.65), Color(0.45, 0.85, 1.0), 8)
		test_btn.pressed.connect(func():
			close_skills_lab()
			hide_entry_choice()
			test_skill_requested.emit(sk_id)
		)
		hb.add_child(test_btn)

func _on_skill_toggled(skill_id: int, enabled_flag: bool) -> void:
	if not save_service:
		return
	var current: Array[int] = save_service.get_enabled_map_skills()
	if enabled_flag:
		if not current.has(skill_id):
			if current.size() >= SaveService.MAX_ENABLED_MAP_SKILLS:
				_refresh_skills_lab()
				return
			current.append(skill_id)
	elif current.has(skill_id):
		current.erase(skill_id)
	save_service.set_enabled_map_skills(current)
	map_skills_updated.emit(save_service.get_enabled_map_skills())
	_refresh_skills_lab()

func _set_all_map_skills(enable_starter: bool) -> void:
	if not save_service:
		return
	var next: Array[int] = []
	if enable_starter:
		next = [1, 2, 3, 5]
	save_service.set_enabled_map_skills(next)
	var saved_next: Array[int] = save_service.get_enabled_map_skills()
	map_skills_updated.emit(saved_next)
	_refresh_skills_lab()

func _build_section_dialog() -> void:
	section_dialog = PanelContainer.new()
	section_dialog.name = "SectionPracticeDialog"
	section_dialog.anchor_left = 0.5
	section_dialog.anchor_right = 0.5
	section_dialog.anchor_top = 0.5
	section_dialog.anchor_bottom = 0.5
	section_dialog.offset_left = -210
	section_dialog.offset_right = 210
	section_dialog.offset_top = -118
	section_dialog.offset_bottom = 118
	section_dialog.clip_contents = true
	section_dialog.add_theme_stylebox_override("panel", _make_panel_style(Color(0.10, 0.09, 0.14, 0.98), Color(0.95, 0.68, 0.30)))
	add_child(section_dialog)

	var vb = VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 5)
	section_dialog.add_child(vb)

	var header = HBoxContainer.new()
	vb.add_child(header)

	var ttl = Label.new()
	ttl.text = "🎯 SECTION PRACTICE"
	ttl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ttl.clip_text = true
	ttl.add_theme_font_size_override("font_size", 10)
	ttl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.4))
	header.add_child(ttl)

	var rnd_b = Button.new()
	rnd_b.text = "RANDOM"
	_style_btn(rnd_b, Color(0.2, 0.42, 0.55), Color(0.45, 0.82, 1.0), 8)
	rnd_b.pressed.connect(func():
		close_section_practice()
		hide_entry_choice()
		random_practice_requested.emit()
	)
	header.add_child(rnd_b)

	var cls_b = Button.new()
	cls_b.text = "CLOSE"
	_style_btn(cls_b, Color(0.26, 0.28, 0.34), Color(0.65, 0.68, 0.75), 8)
	cls_b.pressed.connect(close_section_practice)
	header.add_child(cls_b)

	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	vb.add_child(scroll)

	section_list_vbox = VBoxContainer.new()
	section_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section_list_vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(section_list_vbox)

	for sec in PRACTICE_SECTIONS:
		var row = PanelContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.clip_contents = true
		row.add_theme_stylebox_override("panel", _make_panel_style(Color(0.14, 0.13, 0.20), Color(0.55, 0.42, 0.25)))
		section_list_vbox.add_child(row)

		var hb = HBoxContainer.new()
		hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_theme_constant_override("separation", 6)
		row.add_child(hb)

		var tv = VBoxContainer.new()
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(tv)

		var n_lbl = Label.new()
		n_lbl.text = sec["name"]
		n_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n_lbl.clip_text = true
		n_lbl.add_theme_font_size_override("font_size", 9)
		n_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.52))
		tv.add_child(n_lbl)

		var d_lbl = Label.new()
		d_lbl.text = sec["desc"]
		d_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		d_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d_lbl.add_theme_font_size_override("font_size", 7)
		d_lbl.add_theme_color_override("font_color", Color(0.84, 0.86, 0.92))
		tv.add_child(d_lbl)

		var go_b = Button.new()
		go_b.text = "PRACTICE ▶"
		_style_btn(go_b, Color(0.45, 0.32, 0.14), Color(1.0, 0.72, 0.28), 8)
		var c_idx: int = int(sec["chunk_index"])
		var s_name: String = str(sec["name"])
		go_b.pressed.connect(func():
			close_section_practice()
			hide_entry_choice()
			section_practice_requested.emit(c_idx, s_name)
		)
		hb.add_child(go_b)

func _build_enemies_dialog() -> void:
	enemies_dialog = PanelContainer.new()
	enemies_dialog.name = "EnemiesGuideDialog"
	enemies_dialog.anchor_left = 0.5
	enemies_dialog.anchor_right = 0.5
	enemies_dialog.anchor_top = 0.5
	enemies_dialog.anchor_bottom = 0.5
	enemies_dialog.offset_left = -224
	enemies_dialog.offset_right = 224
	enemies_dialog.offset_top = -122
	enemies_dialog.offset_bottom = 122
	enemies_dialog.clip_contents = true
	enemies_dialog.add_theme_stylebox_override("panel", _make_panel_style(Color(0.11, 0.08, 0.14, 0.98), Color(1.0, 0.48, 0.65)))
	add_child(enemies_dialog)

	var vb = VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 5)
	enemies_dialog.add_child(vb)

	var header = HBoxContainer.new()
	vb.add_child(header)

	var ttl = Label.new()
	ttl.text = "👾 ENEMIES, OBSTACLES & TRAPS GUIDE"
	ttl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ttl.clip_text = true
	ttl.add_theme_font_size_override("font_size", 10)
	ttl.add_theme_color_override("font_color", Color(1.0, 0.72, 0.85))
	header.add_child(ttl)

	var cls_b = Button.new()
	cls_b.text = "CLOSE"
	_style_btn(cls_b, Color(0.26, 0.28, 0.34), Color(0.65, 0.68, 0.75), 8)
	cls_b.pressed.connect(close_enemies_guide)
	header.add_child(cls_b)

	var sub = Label.new()
	sub.text = "Each card shows exact spawn lane (Ground / Overhead / Sky) & animated 1s counter move!"
	sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub.custom_minimum_size = Vector2(360, 0)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_font_size_override("font_size", 7)
	sub.add_theme_color_override("font_color", Color(0.82, 0.88, 0.96))
	vb.add_child(sub)

	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	vb.add_child(scroll)

	enemies_list_vbox = VBoxContainer.new()
	enemies_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemies_list_vbox.add_theme_constant_override("separation", 5)
	scroll.add_child(enemies_list_vbox)

	for item in ENEMIES_GUIDE:
		var col: Color = item.get("color", Color.WHITE)
		var card = PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.clip_contents = true
		card.add_theme_stylebox_override("panel", _make_panel_style(Color(0.13, 0.11, 0.19), col * 0.75))
		enemies_list_vbox.add_child(card)

		var hb = HBoxContainer.new()
		hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_theme_constant_override("separation", 8)
		card.add_child(hb)

		var preview = _EnemyPreviewCanvas.new(str(item.get("anim", "jump_low")), col)
		preview.custom_minimum_size = Vector2(78, 46)
		hb.add_child(preview)

		var tv = VBoxContainer.new()
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_theme_constant_override("separation", 2)
		hb.add_child(tv)

		var top_line = HBoxContainer.new()
		top_line.add_theme_constant_override("separation", 6)
		tv.add_child(top_line)

		var name_l = Label.new()
		name_l.text = str(item.get("name", ""))
		name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_l.clip_text = true
		name_l.add_theme_font_size_override("font_size", 9)
		name_l.add_theme_color_override("font_color", col.lightened(0.25))
		top_line.add_child(name_l)

		var act_l = Label.new()
		act_l.text = "[%s] → %s" % [str(item.get("where", "")), str(item.get("action", ""))]
		act_l.add_theme_font_size_override("font_size", 7)
		act_l.add_theme_color_override("font_color", Color(0.55, 0.96, 0.72))
		top_line.add_child(act_l)

		var desc_l = Label.new()
		desc_l.text = str(item.get("desc", ""))
		desc_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_l.add_theme_font_size_override("font_size", 7)
		desc_l.add_theme_color_override("font_color", Color(0.86, 0.88, 0.94))
		tv.add_child(desc_l)

func _build_builder_dialog() -> void:
	builder_dialog = PanelContainer.new()
	builder_dialog.name = "MapBuilderDialog"
	builder_dialog.anchor_left = 0.5
	builder_dialog.anchor_right = 0.5
	builder_dialog.anchor_top = 0.5
	builder_dialog.anchor_bottom = 0.5
	builder_dialog.offset_left = -232
	builder_dialog.offset_right = 232
	builder_dialog.offset_top = -125
	builder_dialog.offset_bottom = 125
	builder_dialog.clip_contents = true
	builder_dialog.add_theme_stylebox_override("panel", _make_panel_style(Color(0.07, 0.11, 0.13, 0.98), Color(0.42, 0.9, 0.82)))
	add_child(builder_dialog)

	var vb = VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 3)
	builder_dialog.add_child(vb)

	# Row 1: Header + Name + World + Speed + Length + Immortal + Link + Close
	var top_hb = HBoxContainer.new()
	top_hb.add_theme_constant_override("separation", 3)
	vb.add_child(top_hb)

	builder_name_edit = LineEdit.new()
	builder_name_edit.text = "My Custom Map"
	builder_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	builder_name_edit.custom_minimum_size = Vector2(72, 20)
	builder_name_edit.add_theme_font_size_override("font_size", 8)
	top_hb.add_child(builder_name_edit)

	builder_world_btn = Button.new()
	builder_world_btn.text = "Plains"
	_style_btn(builder_world_btn, Color(0.18, 0.35, 0.25), Color(0.45, 0.85, 0.55), 7)
	builder_world_btn.pressed.connect(_cycle_builder_world)
	top_hb.add_child(builder_world_btn)

	builder_speed_btn = Button.new()
	builder_speed_btn.text = "Normal"
	_style_btn(builder_speed_btn, Color(0.2, 0.3, 0.45), Color(0.5, 0.75, 0.95), 7)
	builder_speed_btn.pressed.connect(_cycle_builder_speed)
	top_hb.add_child(builder_speed_btn)

	builder_len_btn = Button.new()
	builder_len_btn.text = "Len: 3.8k"
	_style_btn(builder_len_btn, Color(0.22, 0.28, 0.38), Color(0.55, 0.80, 0.95), 7)
	builder_len_btn.pressed.connect(_cycle_builder_length)
	top_hb.add_child(builder_len_btn)

	builder_immortal_btn = Button.new()
	builder_immortal_btn.text = "Mortality: ON"
	_style_btn(builder_immortal_btn, Color(0.35, 0.22, 0.22), Color(0.9, 0.45, 0.45), 7)
	builder_immortal_btn.pressed.connect(_toggle_builder_immortal)
	top_hb.add_child(builder_immortal_btn)

	builder_link_btn = Button.new()
	builder_link_btn.text = "🔗 Next: End"
	_style_btn(builder_link_btn, Color(0.26, 0.20, 0.42), Color(0.72, 0.55, 0.98), 7)
	builder_link_btn.pressed.connect(_cycle_builder_link)
	top_hb.add_child(builder_link_btn)

	var cls_b = Button.new()
	cls_b.text = "✕"
	_style_btn(cls_b, Color(0.26, 0.28, 0.34), Color(0.65, 0.68, 0.75), 8)
	cls_b.pressed.connect(close_map_builder)
	top_hb.add_child(cls_b)

	# Row 2: Palette
	var pal_scroll = ScrollContainer.new()
	pal_scroll.custom_minimum_size = Vector2(0, 24)
	pal_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(pal_scroll)

	var pal_hb = HBoxContainer.new()
	pal_hb.add_theme_constant_override("separation", 3)
	pal_scroll.add_child(pal_hb)

	for item in BUILDER_PALETTE:
		var pb = Button.new()
		pb.text = item["label"]
		var col: Color = item["color"]
		_style_btn(pb, col * 0.45, col, 7)
		var tool_id: String = item["id"]
		pb.pressed.connect(func(): _select_builder_tool(tool_id))
		pal_hb.add_child(pb)
		builder_palette_btns[tool_id] = pb

	# Row 3: Interactive Spacious Track Canvas inside ScrollContainer
	var canvas_scroll = ScrollContainer.new()
	canvas_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(canvas_scroll)

	builder_canvas = _BuilderTrackCanvas.new(self)
	builder_canvas.custom_minimum_size = Vector2(1330, 128)
	canvas_scroll.add_child(builder_canvas)

	# Row 4: Saved Maps + Actions
	var saved_scroll = ScrollContainer.new()
	saved_scroll.custom_minimum_size = Vector2(0, 22)
	saved_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(saved_scroll)

	builder_saved_maps_hbox = HBoxContainer.new()
	builder_saved_maps_hbox.add_theme_constant_override("separation", 4)
	saved_scroll.add_child(builder_saved_maps_hbox)

	var act_hb = HBoxContainer.new()
	act_hb.add_theme_constant_override("separation", 5)
	vb.add_child(act_hb)

	builder_info_label = Label.new()
	builder_info_label.text = "Tap track to place • Green=OK Amber=Tight Red=Too Close"
	builder_info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	builder_info_label.clip_text = true
	builder_info_label.add_theme_font_size_override("font_size", 7)
	builder_info_label.add_theme_color_override("font_color", Color(0.8, 0.9, 0.92))
	act_hb.add_child(builder_info_label)

	var clr_btn = Button.new()
	clr_btn.text = "CLEAR"
	_style_btn(clr_btn, Color(0.4, 0.2, 0.2), Color(0.9, 0.4, 0.4), 8)
	clr_btn.pressed.connect(func():
		builder_items.clear()
		_update_builder_info()
		builder_canvas.queue_redraw()
	)
	act_hb.add_child(clr_btn)

	var save_btn = Button.new()
	save_btn.text = "💾 SAVE"
	_style_btn(save_btn, Color(0.2, 0.38, 0.55), Color(0.45, 0.82, 1.0), 8)
	save_btn.pressed.connect(_save_current_builder_map)
	act_hb.add_child(save_btn)

	var play_btn = Button.new()
	play_btn.text = "▶ PLAY"
	_style_btn(play_btn, Color(0.18, 0.55, 0.30), Color(0.45, 0.95, 0.55), 8)
	play_btn.pressed.connect(func():
		var map_dict = _build_map_dict()
		if save_service:
			save_service.save_custom_map(map_dict)
		close_map_builder()
		hide_entry_choice()
		play_custom_map_requested.emit(map_dict)
	)
	act_hb.add_child(play_btn)

func _get_builder_world_length() -> float:
	match builder_length_idx:
		0: return 2600.0
		2: return 5000.0
		_: return 3800.0

func _select_builder_tool(tool_id: String) -> void:
	if tool_id == "trap" and builder_selected_tool == "trap":
		builder_trap_type = (builder_trap_type + 1) % 4
	builder_selected_tool = tool_id
	if builder_palette_btns.has("trap") and builder_palette_btns["trap"] is Button:
		var tnames := ["Trap:Surge", "Trap:Grav", "Trap:Glitch", "Trap:Jam"]
		(builder_palette_btns["trap"] as Button).text = tnames[builder_trap_type] if tool_id == "trap" else "Trap"
	_update_builder_info()

func _cycle_builder_world() -> void:
	builder_world_idx = (builder_world_idx + 1) % 4
	var names = ["Plains", "Jungle", "Frozen", "Volcanic"]
	if builder_world_btn:
		builder_world_btn.text = names[builder_world_idx]

func _cycle_builder_speed() -> void:
	builder_speed_idx = (builder_speed_idx + 1) % 3
	var names = ["Chill", "Normal", "Fast"]
	if builder_speed_btn:
		builder_speed_btn.text = names[builder_speed_idx]
	_update_builder_info()
	if builder_canvas:
		builder_canvas.queue_redraw()

func _cycle_builder_length() -> void:
	builder_length_idx = (builder_length_idx + 1) % 3
	var labels := ["Len: 2.6k", "Len: 3.8k", "Len: 5.0k"]
	if builder_len_btn:
		builder_len_btn.text = labels[builder_length_idx]
	if builder_canvas:
		builder_canvas.custom_minimum_size = Vector2(_get_builder_world_length() * _BuilderTrackCanvas.WORLD_SCALE_X, 128)
		builder_canvas.queue_redraw()

func _toggle_builder_immortal() -> void:
	builder_immortal = not builder_immortal
	if builder_immortal_btn:
		builder_immortal_btn.text = "Shield: ON" if builder_immortal else "Mortality: ON"

func _cycle_builder_link() -> void:
	if not save_service:
		builder_linked_next_id = ""
		_refresh_link_btn_text()
		return
	var cur_id := ""
	if builder_name_edit:
		cur_id = builder_name_edit.text.strip_edges().to_lower().replace(" ", "_")
	var options: Array[String] = [""]
	for m in save_service.get_custom_maps():
		var mid := str(m.get("id", ""))
		if mid != "" and mid != cur_id:
			options.append(mid)
	var idx := options.find(builder_linked_next_id)
	builder_linked_next_id = options[(idx + 1) % options.size()]
	_refresh_link_btn_text()

func _refresh_link_btn_text() -> void:
	if builder_link_btn == null:
		return
	if builder_linked_next_id.is_empty():
		builder_link_btn.text = "🔗 Next: End"
		return
	var link_name := builder_linked_next_id
	if save_service:
		for m in save_service.get_custom_maps():
			if str(m.get("id", "")) == builder_linked_next_id:
				link_name = str(m.get("name", builder_linked_next_id))
				break
	builder_link_btn.text = "🔗 -> %s" % link_name.substr(0, 8)

static func compute_gap_status(item_a: Dictionary, item_b: Dictionary, speed_preset: int) -> Dictionary:
	var dx: float = absf(float(item_b.get("x", 0.0)) - float(item_a.get("x", 0.0)))
	var min_req: float = 128.0 if speed_preset == 0 else (168.0 if speed_preset == 2 else 148.0)
	var ta: String = str(item_a.get("type", ""))
	var tb: String = str(item_b.get("type", ""))
	if ta in ["lava", "crate", "overhang"] or tb in ["lava", "crate", "overhang"]:
		min_req += 34.0
	if dx < min_req * 0.65:
		return {"status": "BLOCKED", "color": Color(1.0, 0.25, 0.25), "min_req": min_req, "gap": dx}
	elif dx < min_req:
		return {"status": "TIGHT", "color": Color(1.0, 0.78, 0.18), "min_req": min_req, "gap": dx}
	return {"status": "OK", "color": Color(0.28, 0.92, 0.45), "min_req": min_req, "gap": dx}

func compute_builder_passability() -> Dictionary:
	var hazard_types := ["cactus", "overhang", "crate", "barrier", "crawler", "lava", "trap", "flyer"]
	var hazards: Array[Dictionary] = []
	for it in builder_items:
		if hazard_types.has(str(it.get("type", ""))):
			hazards.append(it)
	hazards.sort_custom(func(a, b): return float(a.get("x", 0.0)) < float(b.get("x", 0.0)))
	var blocked := 0
	var tight := 0
	var spans: Array[Dictionary] = []
	for i in range(hazards.size() - 1):
		var res: Dictionary = compute_gap_status(hazards[i], hazards[i + 1], builder_speed_idx)
		res["x1"] = float(hazards[i].get("x", 0.0))
		res["x2"] = float(hazards[i + 1].get("x", 0.0))
		spans.append(res)
		if res["status"] == "BLOCKED":
			blocked += 1
		elif res["status"] == "TIGHT":
			tight += 1
	return {"blocked": blocked, "tight": tight, "spans": spans, "passable": blocked == 0}

func _update_builder_info() -> void:
	if builder_info_label == null:
		return
	var check := compute_builder_passability()
	var blocked := int(check.get("blocked", 0))
	var tight := int(check.get("tight", 0))
	if blocked > 0:
		builder_info_label.text = "⚠ %d BLOCKED gap(s)! Move red pairs apart • Tool: %s" % [blocked, builder_selected_tool.capitalize()]
		builder_info_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	elif tight > 0:
		builder_info_label.text = "⚡ %d TIGHT jump(s) • %d objs • Tool: %s" % [tight, builder_items.size(), builder_selected_tool.capitalize()]
		builder_info_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	else:
		builder_info_label.text = "✓ PASSABLE • %d objs • Tool: %s" % [builder_items.size(), builder_selected_tool.capitalize()]
		builder_info_label.add_theme_color_override("font_color", Color(0.55, 0.96, 0.72))

func _build_map_dict() -> Dictionary:
	var m_name = builder_name_edit.text.strip_edges() if builder_name_edit else "My Custom Map"
	if m_name.is_empty():
		m_name = "My Custom Map"
	var m_id = m_name.to_lower().replace(" ", "_")
	return {
		"id": m_id,
		"name": m_name,
		"world_index": builder_world_idx,
		"speed_preset": builder_speed_idx,
		"immortal": builder_immortal,
		"length_px": _get_builder_world_length(),
		"linked_next_id": builder_linked_next_id if builder_linked_next_id != m_id else "",
		"items": builder_items.duplicate(true)
	}

func _save_current_builder_map() -> void:
	if not save_service:
		return
	var d = _build_map_dict()
	save_service.save_custom_map(d)
	_refresh_saved_maps_bar()
	if builder_info_label:
		builder_info_label.text = "Saved '%s' (%d objects)!" % [d["name"], builder_items.size()]
		builder_info_label.add_theme_color_override("font_color", Color(0.55, 0.96, 0.72))

func _refresh_saved_maps_bar() -> void:
	if not builder_saved_maps_hbox or not save_service:
		return
	for c in builder_saved_maps_hbox.get_children():
		c.queue_free()
	var maps = save_service.get_custom_maps()
	if maps.is_empty():
		var lbl = Label.new()
		lbl.text = "No saved maps yet (create multiple & link them with 🔗 Next!)"
		lbl.add_theme_font_size_override("font_size", 7)
		lbl.add_theme_color_override("font_color", Color(0.6, 0.65, 0.72))
		builder_saved_maps_hbox.add_child(lbl)
		return
	for m in maps:
		var m_id: String = str(m.get("id", ""))
		var mb = Button.new()
		var linked_str := ("→" + str(m.get("linked_next_id", "")).substr(0, 5)) if not str(m.get("linked_next_id", "")).is_empty() else ""
		mb.text = "%s%s" % [str(m.get("name", "Map")), (" " + linked_str if linked_str != "" else "")]
		_style_btn(mb, Color(0.16, 0.24, 0.34), Color(0.45, 0.72, 0.95), 7)
		var map_copy: Dictionary = m.duplicate(true)
		mb.pressed.connect(func(): _load_builder_map(map_copy))
		builder_saved_maps_hbox.add_child(mb)

		var del_b = Button.new()
		del_b.text = "✕"
		_style_btn(del_b, Color(0.38, 0.16, 0.18), Color(0.9, 0.38, 0.38), 6)
		del_b.pressed.connect(func():
			if save_service:
				save_service.delete_custom_map(m_id)
			if builder_linked_next_id == m_id:
				builder_linked_next_id = ""
				_refresh_link_btn_text()
			_refresh_saved_maps_bar()
		)
		builder_saved_maps_hbox.add_child(del_b)

func _load_builder_map(m: Dictionary) -> void:
	if builder_name_edit:
		builder_name_edit.text = str(m.get("name", "Custom Map"))
	builder_world_idx = clampi(int(m.get("world_index", 0)), 0, 3)
	var w_names = ["Plains", "Jungle", "Frozen", "Volcanic"]
	if builder_world_btn:
		builder_world_btn.text = w_names[builder_world_idx]
	builder_speed_idx = clampi(int(m.get("speed_preset", 1)), 0, 2)
	var s_names = ["Chill", "Normal", "Fast"]
	if builder_speed_btn:
		builder_speed_btn.text = s_names[builder_speed_idx]
	var lpx := float(m.get("length_px", 3800.0))
	builder_length_idx = 0 if lpx <= 2900.0 else (2 if lpx >= 4500.0 else 1)
	if builder_len_btn:
		builder_len_btn.text = ["Len: 2.6k", "Len: 3.8k", "Len: 5.0k"][builder_length_idx]
	builder_linked_next_id = str(m.get("linked_next_id", ""))
	_refresh_link_btn_text()
	builder_immortal = bool(m.get("immortal", false))
	if builder_immortal_btn:
		builder_immortal_btn.text = "Shield: ON" if builder_immortal else "Mortality: ON"
	builder_items.clear()
	for it in m.get("items", []):
		if typeof(it) == TYPE_DICTIONARY:
			builder_items.append(it.duplicate(true))
	_update_builder_info()
	if builder_canvas:
		builder_canvas.custom_minimum_size = Vector2(_get_builder_world_length() * _BuilderTrackCanvas.WORLD_SCALE_X, 128)
		builder_canvas.queue_redraw()

class _EnemyPreviewCanvas extends Control:
	var anim_kind: String = "jump_low"
	var accent: Color = Color.WHITE
	var _t: float = 0.0

	func _init(p_anim: String = "jump_low", p_col: Color = Color.WHITE) -> void:
		anim_kind = p_anim
		accent = p_col
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		if not is_visible_in_tree():
			return
		_t = fmod(_t + delta, 1.2)
		queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var gy := h - 10.0
		draw_rect(Rect2(0, 0, w, h), Color(0.06, 0.08, 0.13))
		draw_rect(Rect2(0, 0, w, h), accent * 0.55, false, 1.0)
		draw_rect(Rect2(0, gy, w, 10.0), Color(0.20, 0.34, 0.22))
		draw_line(Vector2(0, gy), Vector2(w, gy), Color(0.45, 0.85, 0.45), 1.5)

		var p := _t / 1.2 # Normalized 0..1 across ~1.2s loop
		var dino_x := lerpf(10.0, w - 12.0, p)
		var dino_y := gy - 12.0
		var dino_h := 12.0
		var dino_w := 10.0

		match anim_kind:
			"jump_low":
				draw_rect(Rect2(w * 0.48, gy - 12.0, 7.0, 12.0), accent)
				var arc := sin(clampf((p - 0.22) / 0.50, 0.0, 1.0) * PI)
				dino_y = gy - 12.0 - arc * 22.0
			"jump_high":
				draw_rect(Rect2(w * 0.46, gy - 18.0, 11.0, 18.0), accent)
				var arc := sin(clampf((p - 0.18) / 0.58, 0.0, 1.0) * PI)
				dino_y = gy - 12.0 - arc * 28.0
			"slide":
				draw_rect(Rect2(w * 0.36, 4.0, 22.0, gy - 16.0), accent)
				if p >= 0.22 and p <= 0.72:
					dino_h = 6.0
					dino_w = 13.0
					dino_y = gy - 6.0
			"stomp":
				var ex := w * 0.55 - p * 12.0
				draw_rect(Rect2(ex, gy - 9.0, 10.0, 9.0), accent)
				var arc := sin(clampf((p - 0.15) / 0.65, 0.0, 1.0) * PI)
				dino_y = gy - 12.0 - arc * 24.0
			"duck_under":
				var fx := w * 0.65 - p * 18.0
				draw_circle(Vector2(fx, gy - 18.0), 5.0, accent)
				draw_line(Vector2(fx - 7.0, gy - 20.0), Vector2(fx + 7.0, gy - 20.0), accent, 2.0)
				if p >= 0.25 and p <= 0.72:
					dino_h = 6.0
					dino_w = 13.0
					dino_y = gy - 6.0
			"slash":
				if p < 0.52:
					draw_rect(Rect2(w * 0.50, gy - 20.0, 8.0, 20.0), accent)
				else:
					draw_rect(Rect2(w * 0.52, gy - 5.0, 12.0, 4.0), accent.darkened(0.35))
				if p >= 0.36 and p <= 0.60:
					draw_line(Vector2(dino_x + 8.0, dino_y), Vector2(dino_x + 18.0, dino_y + 10.0), Color(0.55, 0.96, 1.0), 2.5)
			"lava_gap":
				draw_rect(Rect2(w * 0.38, gy - 1.0, 20.0, 11.0), accent)
				var arc := sin(clampf((p - 0.20) / 0.58, 0.0, 1.0) * PI)
				dino_y = gy - 12.0 - arc * 26.0
			"avoid_trap":
				draw_colored_polygon(PackedVector2Array([Vector2(w * 0.50, gy - 12.0), Vector2(w * 0.44, gy - 2.0), Vector2(w * 0.56, gy - 2.0)]), accent)
				var arc := sin(clampf((p - 0.24) / 0.48, 0.0, 1.0) * PI)
				dino_y = gy - 12.0 - arc * 20.0
			"bounce_up":
				draw_rect(Rect2(w * 0.44, gy - 5.0, 12.0, 5.0), accent)
				draw_rect(Rect2(w * 0.62, gy - 24.0, 18.0, 4.0), Color(0.55, 0.88, 1.0))
				if p >= 0.38:
					var b_p := clampf((p - 0.38) / 0.45, 0.0, 1.0)
					dino_y = gy - 12.0 - sin(b_p * PI * 0.8) * 24.0

		# Cute miniature Dino silhouette
		draw_rect(Rect2(dino_x - dino_w * 0.5, dino_y, dino_w, dino_h), Color(0.32, 0.96, 0.62))
		draw_rect(Rect2(dino_x + dino_w * 0.1, dino_y + 1.5, 2.0, 2.0), Color(0.05, 0.08, 0.10))

class _BuilderTrackCanvas extends Control:
	var owner_ui: PracticeHubUI
	const WORLD_SCALE_X: float = 0.35
	const CANVAS_GROUND_Y: float = 104.0

	func _init(p_owner: PracticeHubUI) -> void:
		owner_ui = p_owner
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.08, 0.11))
		# Grid lines & clear meter spacing markers (28px canvas = 80px world)
		for gx in range(0, int(size.x), 28):
			var is_major := (gx % 112 == 0)
			draw_line(Vector2(gx, 0), Vector2(gx, size.y), Color(0.20, 0.28, 0.36) if is_major else Color(0.11, 0.15, 0.20), 1.0)
		# Ground line
		draw_rect(Rect2(0, CANVAS_GROUND_Y, size.x, size.y - CANVAS_GROUND_Y), Color(0.22, 0.34, 0.20))
		draw_line(Vector2(0, CANVAS_GROUND_Y), Vector2(size.x, CANVAS_GROUND_Y), Color(0.45, 0.78, 0.42), 2.0)
		# Start marker
		draw_rect(Rect2(84.0 * WORLD_SCALE_X, CANVAS_GROUND_Y - 14.0, 10.0, 14.0), Color(0.35, 0.95, 0.62, 0.85))

		if not owner_ui:
			return

		# Draw passability gap lines & jump-arc hints between adjacent hazards
		var pass_data := owner_ui.compute_builder_passability()
		for sp in pass_data.get("spans", []):
			var x1: float = float(sp.get("x1", 0.0)) * WORLD_SCALE_X
			var x2: float = float(sp.get("x2", 0.0)) * WORLD_SCALE_X
			var scol: Color = sp.get("color", Color.GREEN)
			draw_line(Vector2(x1, CANVAS_GROUND_Y + 6.0), Vector2(x2, CANVAS_GROUND_Y + 6.0), scol, 3.0)
			# Subtle parabolic jump arc indicator over gap
			var mid_x := (x1 + x2) * 0.5
			draw_line(Vector2(x1, CANVAS_GROUND_Y - 12.0), Vector2(mid_x, CANVAS_GROUND_Y - 34.0), Color(scol.r, scol.g, scol.b, 0.45), 1.0)
			draw_line(Vector2(mid_x, CANVAS_GROUND_Y - 34.0), Vector2(x2, CANVAS_GROUND_Y - 12.0), Color(scol.r, scol.g, scol.b, 0.45), 1.0)

		# Draw distinct recognizable silhouettes at true height
		for it in owner_ui.builder_items:
			var kind: String = str(it.get("type", "cactus"))
			var wx: float = float(it.get("x", 300.0))
			var wy: float = float(it.get("y", 216.0))
			var cx: float = wx * WORLD_SCALE_X
			var cy: float = CANVAS_GROUND_Y - (224.0 - wy) * 0.45
			var col: Color = Color.WHITE
			for p in PracticeHubUI.BUILDER_PALETTE:
				if p["id"] == kind:
					col = p["color"]
					break
			match kind:
				"cactus":
					draw_rect(Rect2(cx - 4, CANVAS_GROUND_Y - 16, 8, 16), col)
					draw_rect(Rect2(cx - 7, CANVAS_GROUND_Y - 12, 3, 5), col)
					draw_rect(Rect2(cx + 4, CANVAS_GROUND_Y - 14, 3, 5), col)
				"crate":
					draw_rect(Rect2(cx - 7, CANVAS_GROUND_Y - 22, 14, 22), col)
					draw_line(Vector2(cx - 7, CANVAS_GROUND_Y - 22), Vector2(cx + 7, CANVAS_GROUND_Y), col.darkened(0.4), 1.0)
				"overhang":
					draw_rect(Rect2(cx - 10, CANVAS_GROUND_Y - 34, 20, 16), col)
					draw_rect(Rect2(cx - 10, CANVAS_GROUND_Y - 16, 20, 2), Color(1.0, 0.85, 0.35, 0.5))
				"barrier":
					draw_rect(Rect2(cx - 5, CANVAS_GROUND_Y - 24, 10, 24), col)
				"crawler":
					draw_rect(Rect2(cx - 8, CANVAS_GROUND_Y - 10, 16, 10), col)
					draw_circle(Vector2(cx, CANVAS_GROUND_Y - 10), 4.0, col.lightened(0.2))
				"flyer":
					draw_circle(Vector2(cx, cy), 6.0, col)
					draw_line(Vector2(cx - 9, cy - 2), Vector2(cx + 9, cy - 2), col, 2.0)
				"lava":
					draw_rect(Rect2(cx - 14, CANVAS_GROUND_Y - 2, 28, 10), col)
				"trap":
					var tkind := int(it.get("trap_type", 0))
					var tcols := [Color(1.0, 0.85, 0.18), Color(0.68, 0.34, 1.0), Color(0.18, 0.92, 0.96), Color(1.0, 0.25, 0.32)]
					draw_colored_polygon(PackedVector2Array([Vector2(cx, cy - 7), Vector2(cx - 6, cy + 5), Vector2(cx + 6, cy + 5)]), tcols[clampi(tkind, 0, 3)])
				"platform":
					draw_rect(Rect2(cx - 12, cy - 2, 24, 5), col)
				"bounce":
					draw_rect(Rect2(cx - 7, CANVAS_GROUND_Y - 6, 14, 6), col)
				"wind":
					draw_line(Vector2(cx - 3, CANVAS_GROUND_Y - 2), Vector2(cx - 3, CANVAS_GROUND_Y - 28), col, 2.0)
					draw_line(Vector2(cx + 3, CANVAS_GROUND_Y - 4), Vector2(cx + 3, CANVAS_GROUND_Y - 30), col, 2.0)
				"gem":
					draw_colored_polygon(PackedVector2Array([Vector2(cx, cy - 6), Vector2(cx + 5, cy), Vector2(cx, cy + 6), Vector2(cx - 5, cy)]), col)
				"skill":
					draw_circle(Vector2(cx, cy), 6.5, col)
					draw_circle(Vector2(cx, cy), 6.5, Color.WHITE, false, 1.0)
				_:
					draw_rect(Rect2(cx - 7, cy - 7, 14, 14), col)

	func _gui_input(event: InputEvent) -> void:
		if not owner_ui:
			return
		var pressed_tap: bool = false
		var pos: Vector2 = Vector2.ZERO
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			pressed_tap = true
			pos = event.position
		elif event is InputEventScreenTouch and event.pressed:
			pressed_tap = true
			pos = event.position
		if pressed_tap:
			var max_wx: float = owner_ui._get_builder_world_length() - 120.0
			var wx: float = clampf(roundf((pos.x / WORLD_SCALE_X) / 24.0) * 24.0, 260.0, max_wx)
			var wy: float = clampf(224.0 - ((CANVAS_GROUND_Y - pos.y) / 0.45), 64.0, 224.0)
			wy = roundf(wy / 8.0) * 8.0

			if owner_ui.builder_selected_tool == "eraser":
				for i in range(owner_ui.builder_items.size() - 1, -1, -1):
					var it = owner_ui.builder_items[i]
					if absf(float(it.get("x", 0.0)) - wx) < 42.0:
						owner_ui.builder_items.remove_at(i)
						break
			else:
				for p in PracticeHubUI.BUILDER_PALETTE:
					if p["id"] == owner_ui.builder_selected_tool and bool(p.get("ground_locked", false)):
						wy = float(p.get("default_y", 230.0))
						break
				var new_item: Dictionary = {
					"type": owner_ui.builder_selected_tool,
					"x": wx,
					"y": wy
				}
				if owner_ui.builder_selected_tool == "trap":
					new_item["trap_type"] = owner_ui.builder_trap_type
				owner_ui.builder_items.append(new_item)
			owner_ui._update_builder_info()
			queue_redraw()
			accept_event()
