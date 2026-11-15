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
	{"id": "cactus", "label": "Cactus", "color": Color(0.25, 0.82, 0.35), "default_y": 216.0},
	{"id": "overhang", "label": "Arch", "color": Color(0.65, 0.58, 0.48), "default_y": 176.0},
	{"id": "crate", "label": "Crate", "color": Color(0.82, 0.55, 0.25), "default_y": 212.0},
	{"id": "barrier", "label": "Barrier", "color": Color(0.72, 0.38, 0.22), "default_y": 208.0},
	{"id": "crawler", "label": "Crawler", "color": Color(0.95, 0.35, 0.35), "default_y": 216.0},
	{"id": "flyer", "label": "Flyer", "color": Color(0.92, 0.45, 0.78), "default_y": 152.0},
	{"id": "lava", "label": "Lava", "color": Color(1.0, 0.38, 0.12), "default_y": 228.0},
	{"id": "platform", "label": "Platform", "color": Color(0.45, 0.78, 0.95), "default_y": 168.0},
	{"id": "bounce", "label": "Bounce", "color": Color(0.95, 0.85, 0.25), "default_y": 220.0},
	{"id": "wind", "label": "Wind", "color": Color(0.55, 0.95, 0.95), "default_y": 216.0},
	{"id": "gem", "label": "Gem", "color": Color(1.0, 0.78, 0.15), "default_y": 172.0},
	{"id": "skill", "label": "Skill", "color": Color(0.75, 0.45, 1.0), "default_y": 176.0},
	{"id": "eraser", "label": "Erase", "color": Color(0.9, 0.2, 0.2), "default_y": 216.0}
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
var _skill_checkboxes: Dictionary = {}

var section_dialog: PanelContainer
var section_list_vbox: VBoxContainer

var builder_dialog: PanelContainer
var builder_name_edit: LineEdit
var builder_world_idx: int = 0
var builder_world_btn: Button
var builder_speed_idx: int = 1
var builder_speed_btn: Button
var builder_immortal_btn: Button
var builder_immortal: bool = false
var builder_selected_tool: String = "cactus"
var builder_palette_btns: Dictionary = {}
var builder_canvas: Control
var builder_items: Array[Dictionary] = []
var builder_saved_maps_hbox: HBoxContainer
var builder_info_label: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	hide_all()

func bind_save_service(sv: SaveService) -> void:
	save_service = sv

func _process(delta: float) -> void:
	if hint_banner and hint_banner.visible and _hint_timer > 0.0:
		_hint_timer -= delta
		if _hint_timer <= 0.0:
			hint_banner.visible = false

func hide_all() -> void:
	if entry_panel: entry_panel.visible = false
	if tutorial_banner: tutorial_banner.visible = false
	if hint_banner: hint_banner.visible = false
	if practice_bar: practice_bar.visible = false
	if skills_lab_dialog: skills_lab_dialog.visible = false
	if section_dialog: section_dialog.visible = false
	if builder_dialog: builder_dialog.visible = false

func show_entry_choice() -> void:
	hide_all()
	if entry_panel:
		entry_panel.visible = true

func hide_entry_choice() -> void:
	if entry_panel:
		entry_panel.visible = false

func show_practice_bar(mode_text: String = "FREE PRACTICE • NO DEATH • NO SCORE") -> void:
	if practice_bar:
		practice_bar.visible = true
	if practice_status_label:
		practice_status_label.text = mode_text

func hide_practice_bar() -> void:
	if practice_bar:
		practice_bar.visible = false

func show_tutorial_step(title_txt: String, body_txt: String, badge_txt: String, badge_color: Color, status_txt: String = "Try it now!") -> void:
	if tutorial_banner:
		tutorial_banner.visible = true
	if tutorial_step_title:
		tutorial_step_title.text = title_txt
	if tutorial_step_body:
		tutorial_step_body.text = body_txt
	if tutorial_step_status:
		tutorial_step_status.text = status_txt
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
	if hint_banner and hint_label:
		hint_label.text = "💡 TIP: " + text_msg
		hint_banner.visible = true
		_hint_timer = duration

func hide_adaptive_hint() -> void:
	if hint_banner:
		hint_banner.visible = false
	_hint_timer = 0.0

func open_skills_lab() -> void:
	_refresh_skills_lab()
	if skills_lab_dialog:
		skills_lab_dialog.visible = true
	modal_opened.emit()

func close_skills_lab() -> void:
	if skills_lab_dialog:
		skills_lab_dialog.visible = false
	modal_closed.emit()

func open_section_practice() -> void:
	if section_dialog:
		section_dialog.visible = true
	modal_opened.emit()

func close_section_practice() -> void:
	if section_dialog:
		section_dialog.visible = false
	modal_closed.emit()

func open_map_builder() -> void:
	_refresh_saved_maps_bar()
	if builder_canvas:
		builder_canvas.queue_redraw()
	if builder_dialog:
		builder_dialog.visible = true
	modal_opened.emit()

func close_map_builder() -> void:
	if builder_dialog:
		builder_dialog.visible = false
	modal_closed.emit()

func close_active_modal() -> bool:
	if builder_dialog and builder_dialog.visible:
		close_map_builder()
		return true
	if section_dialog and section_dialog.visible:
		close_section_practice()
		return true
	if skills_lab_dialog and skills_lab_dialog.visible:
		close_skills_lab()
		return true
	return false

func has_modal_open() -> bool:
	return (
		(entry_panel != null and entry_panel.visible)
		or (skills_lab_dialog != null and skills_lab_dialog.visible)
		or (section_dialog != null and section_dialog.visible)
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
	var n = _make_panel_style(bg, border)
	n.content_margin_left = 8
	n.content_margin_right = 8
	n.content_margin_top = 4
	n.content_margin_bottom = 4
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
	_build_builder_dialog()

func _build_entry_panel() -> void:
	entry_panel = PanelContainer.new()
	entry_panel.name = "PracticeEntryPanel"
	entry_panel.anchor_left = 0.5
	entry_panel.anchor_right = 0.5
	entry_panel.anchor_top = 0.5
	entry_panel.anchor_bottom = 0.5
	entry_panel.offset_left = -185
	entry_panel.offset_right = 185
	entry_panel.offset_top = -105
	entry_panel.offset_bottom = 105
	entry_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.08, 0.11, 0.16, 0.96), Color(0.35, 0.78, 0.95)))
	add_child(entry_panel)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	entry_panel.add_child(vb)

	var title = Label.new()
	title.text = "TUTORIAL & PRACTICE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vb.add_child(title)

	var sub = Label.new()
	sub.text = "Live playable training • Zero death • Test all 12 skills • Build maps"
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
	tools_row.add_theme_constant_override("separation", 6)
	vb.add_child(tools_row)

	var skills_btn = Button.new()
	skills_btn.name = "EntrySkillsLabBtn"
	skills_btn.text = "⚡ SKILLS LAB"
	_style_btn(skills_btn, Color(0.32, 0.22, 0.52), Color(0.75, 0.52, 1.0), 9)
	skills_btn.pressed.connect(open_skills_lab)
	tools_row.add_child(skills_btn)

	var sec_btn = Button.new()
	sec_btn.name = "EntrySectionsBtn"
	sec_btn.text = "🎯 SECTIONS"
	_style_btn(sec_btn, Color(0.38, 0.28, 0.16), Color(0.95, 0.68, 0.32), 9)
	sec_btn.pressed.connect(open_section_practice)
	tools_row.add_child(sec_btn)

	var bld_btn = Button.new()
	bld_btn.name = "EntryBuilderBtn"
	bld_btn.text = "🛠 MAP BUILDER"
	_style_btn(bld_btn, Color(0.22, 0.36, 0.34), Color(0.45, 0.9, 0.82), 9)
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
	tutorial_banner.offset_left = -180
	tutorial_banner.offset_right = 180
	tutorial_banner.offset_top = 34
	tutorial_banner.offset_bottom = 104
	tutorial_banner.add_theme_stylebox_override("panel", _make_panel_style(Color(0.06, 0.10, 0.18, 0.92), Color(0.38, 0.85, 1.0)))
	add_child(tutorial_banner)

	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	tutorial_banner.add_child(hb)

	tutorial_icon_rect = ColorRect.new()
	tutorial_icon_rect.custom_minimum_size = Vector2(52, 48)
	tutorial_icon_rect.color = Color(0.2, 0.55, 0.85)
	hb.add_child(tutorial_icon_rect)

	tutorial_icon_label = Label.new()
	tutorial_icon_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	tutorial_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tutorial_icon_label.add_theme_font_size_override("font_size", 10)
	tutorial_icon_rect.add_child(tutorial_icon_label)

	var vb = VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 2)
	hb.add_child(vb)

	var top_row = HBoxContainer.new()
	vb.add_child(top_row)

	tutorial_step_title = Label.new()
	tutorial_step_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	tutorial_step_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_step_body.add_theme_font_size_override("font_size", 8)
	tutorial_step_body.add_theme_color_override("font_color", Color(0.95, 0.96, 0.98))
	vb.add_child(tutorial_step_body)

	tutorial_step_status = Label.new()
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
	hint_banner.offset_top = 34
	hint_banner.offset_bottom = 78
	hint_banner.add_theme_stylebox_override("panel", _make_panel_style(Color(0.18, 0.12, 0.05, 0.94), Color(1.0, 0.72, 0.2)))
	add_child(hint_banner)

	var hb = HBoxContainer.new()
	hint_banner.add_child(hb)

	hint_label = Label.new()
	hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	practice_bar.offset_left = 8
	practice_bar.offset_top = 4
	practice_bar.offset_right = 330
	practice_bar.offset_bottom = 30
	practice_bar.add_theme_stylebox_override("panel", _make_panel_style(Color(0.08, 0.14, 0.22, 0.88), Color(0.35, 0.75, 0.95)))
	add_child(practice_bar)

	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 4)
	practice_bar.add_child(hb)

	practice_status_label = Label.new()
	practice_status_label.text = "🛡 PRACTICE • NO SCORE"
	practice_status_label.add_theme_font_size_override("font_size", 8)
	practice_status_label.add_theme_color_override("font_color", Color(0.55, 0.92, 1.0))
	hb.add_child(practice_status_label)

	var b_skills = Button.new()
	b_skills.text = "⚡Skills"
	_style_btn(b_skills, Color(0.28, 0.2, 0.45), Color(0.7, 0.5, 0.95), 8)
	b_skills.pressed.connect(open_skills_lab)
	hb.add_child(b_skills)

	var b_sec = Button.new()
	b_sec.text = "🎯Sections"
	_style_btn(b_sec, Color(0.35, 0.25, 0.15), Color(0.9, 0.65, 0.3), 8)
	b_sec.pressed.connect(open_section_practice)
	hb.add_child(b_sec)

	var b_bld = Button.new()
	b_bld.text = "🛠Builder"
	_style_btn(b_bld, Color(0.18, 0.34, 0.32), Color(0.4, 0.85, 0.78), 8)
	b_bld.pressed.connect(open_map_builder)
	hb.add_child(b_bld)

func _build_skills_lab_dialog() -> void:
	skills_lab_dialog = PanelContainer.new()
	skills_lab_dialog.name = "SkillsLabDialog"
	skills_lab_dialog.anchor_left = 0.5
	skills_lab_dialog.anchor_right = 0.5
	skills_lab_dialog.anchor_top = 0.5
	skills_lab_dialog.anchor_bottom = 0.5
	skills_lab_dialog.offset_left = -215
	skills_lab_dialog.offset_right = 215
	skills_lab_dialog.offset_top = -125
	skills_lab_dialog.offset_bottom = 125
	skills_lab_dialog.add_theme_stylebox_override("panel", _make_panel_style(Color(0.08, 0.09, 0.15, 0.98), Color(0.72, 0.48, 1.0)))
	add_child(skills_lab_dialog)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)
	skills_lab_dialog.add_child(vb)

	var header = HBoxContainer.new()
	vb.add_child(header)

	var ttl = Label.new()
	ttl.text = "⚡ SKILLS LAB • TEST & SELECT MAP SKILLS"
	ttl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ttl.add_theme_font_size_override("font_size", 10)
	ttl.add_theme_color_override("font_color", Color(0.88, 0.72, 1.0))
	header.add_child(ttl)

	var all_b = Button.new()
	all_b.text = "ALL"
	_style_btn(all_b, Color(0.2, 0.42, 0.28), Color(0.45, 0.88, 0.55), 8)
	all_b.pressed.connect(func(): _set_all_map_skills(true))
	header.add_child(all_b)

	var clr_b = Button.new()
	clr_b.text = "NONE"
	_style_btn(clr_b, Color(0.42, 0.2, 0.2), Color(0.88, 0.45, 0.45), 8)
	clr_b.pressed.connect(func(): _set_all_map_skills(false))
	header.add_child(clr_b)

	var cls_b = Button.new()
	cls_b.text = "CLOSE"
	_style_btn(cls_b, Color(0.26, 0.28, 0.34), Color(0.65, 0.68, 0.75), 8)
	cls_b.pressed.connect(close_skills_lab)
	header.add_child(cls_b)

	var note = Label.new()
	note.text = "Higher-tier skills (Epic/Legendary) spawn much more rarely in runs than Common skills!"
	note.add_theme_font_size_override("font_size", 7)
	note.add_theme_color_override("font_color", Color(0.75, 0.82, 0.92))
	vb.add_child(note)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
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

	var enabled: Array[int] = save_service.get_enabled_map_skills() if save_service else [1,2,3,4,5,6,7,8,9,10,11,12]
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
		row_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.12, 0.14, 0.22), tier_col * 0.7))
		skills_list_vbox.add_child(row_panel)

		var hb = HBoxContainer.new()
		hb.add_theme_constant_override("separation", 6)
		row_panel.add_child(hb)

		var chk = CheckBox.new()
		chk.button_pressed = enabled.has(sk_id)
		chk.text = ""
		chk.toggled.connect(func(pressed: bool): _on_skill_toggled(sk_id, pressed))
		hb.add_child(chk)
		_skill_checkboxes[sk_id] = chk

		var text_vb = VBoxContainer.new()
		text_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(text_vb)

		var dur_val: float = float(info.get("duration", 0.0))
		var dur_str := "Passive" if dur_val < 0.0 else ("Instant" if dur_val == 0.0 else "%.1fs" % dur_val)
		var rate_str := (" | Drop: %.0f%%" % pct) if enabled.has(sk_id) else " | Disabled"

		var name_lbl = Label.new()
		name_lbl.text = "%s [%s] • Dur: %s%s" % [info.get("name", "Skill"), info.get("tier_name", "Common"), dur_str, rate_str]
		name_lbl.add_theme_font_size_override("font_size", 8)
		name_lbl.add_theme_color_override("font_color", tier_col)
		text_vb.add_child(name_lbl)

		var desc_lbl = Label.new()
		desc_lbl.text = str(info.get("desc", ""))
		desc_lbl.add_theme_font_size_override("font_size", 7)
		desc_lbl.add_theme_color_override("font_color", Color(0.84, 0.88, 0.94))
		text_vb.add_child(desc_lbl)

		var test_btn = Button.new()
		test_btn.text = "TEST"
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
	if enabled_flag and not current.has(skill_id):
		current.append(skill_id)
	elif not enabled_flag and current.has(skill_id):
		current.erase(skill_id)
	save_service.set_enabled_map_skills(current)
	map_skills_updated.emit(current)
	_refresh_skills_lab()

func _set_all_map_skills(enable_all: bool) -> void:
	if not save_service:
		return
	var next: Array[int] = []
	if enable_all:
		for sk in SkillManagerScript.get_all_skill_types():
			next.append(int(sk))
	save_service.set_enabled_map_skills(next)
	map_skills_updated.emit(next)
	_refresh_skills_lab()

func _build_section_dialog() -> void:
	section_dialog = PanelContainer.new()
	section_dialog.name = "SectionPracticeDialog"
	section_dialog.anchor_left = 0.5
	section_dialog.anchor_right = 0.5
	section_dialog.anchor_top = 0.5
	section_dialog.anchor_bottom = 0.5
	section_dialog.offset_left = -205
	section_dialog.offset_right = 205
	section_dialog.offset_top = -120
	section_dialog.offset_bottom = 120
	section_dialog.add_theme_stylebox_override("panel", _make_panel_style(Color(0.10, 0.09, 0.14, 0.98), Color(0.95, 0.68, 0.30)))
	add_child(section_dialog)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)
	section_dialog.add_child(vb)

	var header = HBoxContainer.new()
	vb.add_child(header)

	var ttl = Label.new()
	ttl.text = "🎯 SECTION PRACTICE • DRILL SPECIFIC OBSTACLES"
	ttl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(scroll)

	section_list_vbox = VBoxContainer.new()
	section_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section_list_vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(section_list_vbox)

	for sec in PRACTICE_SECTIONS:
		var row = PanelContainer.new()
		row.add_theme_stylebox_override("panel", _make_panel_style(Color(0.14, 0.13, 0.20), Color(0.55, 0.42, 0.25)))
		section_list_vbox.add_child(row)

		var hb = HBoxContainer.new()
		row.add_child(hb)

		var tv = VBoxContainer.new()
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(tv)

		var n_lbl = Label.new()
		n_lbl.text = sec["name"]
		n_lbl.add_theme_font_size_override("font_size", 9)
		n_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.52))
		tv.add_child(n_lbl)

		var d_lbl = Label.new()
		d_lbl.text = sec["desc"]
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

func _build_builder_dialog() -> void:
	builder_dialog = PanelContainer.new()
	builder_dialog.name = "MapBuilderDialog"
	builder_dialog.anchor_left = 0.5
	builder_dialog.anchor_right = 0.5
	builder_dialog.anchor_top = 0.5
	builder_dialog.anchor_bottom = 0.5
	builder_dialog.offset_left = -228
	builder_dialog.offset_right = 228
	builder_dialog.offset_top = -128
	builder_dialog.offset_bottom = 128
	builder_dialog.add_theme_stylebox_override("panel", _make_panel_style(Color(0.07, 0.11, 0.13, 0.98), Color(0.42, 0.9, 0.82)))
	add_child(builder_dialog)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	builder_dialog.add_child(vb)

	# Row 1: Header + Name + World + Speed + Immortal + Close
	var top_hb = HBoxContainer.new()
	top_hb.add_theme_constant_override("separation", 4)
	vb.add_child(top_hb)

	builder_name_edit = LineEdit.new()
	builder_name_edit.text = "My Custom Map"
	builder_name_edit.custom_minimum_size = Vector2(95, 20)
	builder_name_edit.add_theme_font_size_override("font_size", 8)
	top_hb.add_child(builder_name_edit)

	builder_world_btn = Button.new()
	builder_world_btn.text = "Plains"
	_style_btn(builder_world_btn, Color(0.18, 0.35, 0.25), Color(0.45, 0.85, 0.55), 8)
	builder_world_btn.pressed.connect(_cycle_builder_world)
	top_hb.add_child(builder_world_btn)

	builder_speed_btn = Button.new()
	builder_speed_btn.text = "Normal"
	_style_btn(builder_speed_btn, Color(0.2, 0.3, 0.45), Color(0.5, 0.75, 0.95), 8)
	builder_speed_btn.pressed.connect(_cycle_builder_speed)
	top_hb.add_child(builder_speed_btn)

	builder_immortal_btn = Button.new()
	builder_immortal_btn.text = "Mortality: ON"
	_style_btn(builder_immortal_btn, Color(0.35, 0.22, 0.22), Color(0.9, 0.45, 0.45), 8)
	builder_immortal_btn.pressed.connect(_toggle_builder_immortal)
	top_hb.add_child(builder_immortal_btn)

	var cls_b = Button.new()
	cls_b.text = "✕"
	_style_btn(cls_b, Color(0.26, 0.28, 0.34), Color(0.65, 0.68, 0.75), 8)
	cls_b.pressed.connect(close_map_builder)
	top_hb.add_child(cls_b)

	# Row 2: Palette
	var pal_scroll = ScrollContainer.new()
	pal_scroll.custom_minimum_size = Vector2(0, 26)
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

	# Row 3: Interactive Track Canvas inside ScrollContainer
	var canvas_scroll = ScrollContainer.new()
	canvas_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(canvas_scroll)

	builder_canvas = _BuilderTrackCanvas.new(self)
	builder_canvas.custom_minimum_size = Vector2(1200, 128)
	canvas_scroll.add_child(builder_canvas)

	# Row 4: Saved Maps + Actions
	builder_saved_maps_hbox = HBoxContainer.new()
	builder_saved_maps_hbox.add_theme_constant_override("separation", 4)
	vb.add_child(builder_saved_maps_hbox)

	var act_hb = HBoxContainer.new()
	act_hb.add_theme_constant_override("separation", 5)
	vb.add_child(act_hb)

	builder_info_label = Label.new()
	builder_info_label.text = "Tap track to place objects (0 placed)"
	builder_info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	play_btn.text = "▶ PLAY MAP"
	_style_btn(play_btn, Color(0.18, 0.55, 0.30), Color(0.45, 0.95, 0.55), 8)
	play_btn.pressed.connect(func():
		var map_dict = _build_map_dict()
		close_map_builder()
		hide_entry_choice()
		play_custom_map_requested.emit(map_dict)
	)
	act_hb.add_child(play_btn)

func _select_builder_tool(tool_id: String) -> void:
	builder_selected_tool = tool_id
	if builder_info_label:
		builder_info_label.text = "Tool: %s • %d objects placed" % [tool_id.capitalize(), builder_items.size()]

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

func _toggle_builder_immortal() -> void:
	builder_immortal = not builder_immortal
	if builder_immortal_btn:
		builder_immortal_btn.text = "Immortal: ON" if builder_immortal else "Mortality: ON"

func _update_builder_info() -> void:
	if builder_info_label:
		builder_info_label.text = "Tool: %s • %d objects placed" % [builder_selected_tool.capitalize(), builder_items.size()]

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

func _refresh_saved_maps_bar() -> void:
	if not builder_saved_maps_hbox or not save_service:
		return
	for c in builder_saved_maps_hbox.get_children():
		c.queue_free()
	var maps = save_service.get_custom_maps()
	if maps.is_empty():
		var lbl = Label.new()
		lbl.text = "No saved maps yet"
		lbl.add_theme_font_size_override("font_size", 7)
		lbl.add_theme_color_override("font_color", Color(0.6, 0.65, 0.72))
		builder_saved_maps_hbox.add_child(lbl)
		return
	for m in maps:
		var mb = Button.new()
		mb.text = str(m.get("name", "Map"))
		_style_btn(mb, Color(0.16, 0.24, 0.34), Color(0.45, 0.72, 0.95), 7)
		var map_copy: Dictionary = m.duplicate(true)
		mb.pressed.connect(func(): _load_builder_map(map_copy))
		builder_saved_maps_hbox.add_child(mb)

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
	builder_immortal = bool(m.get("immortal", false))
	if builder_immortal_btn:
		builder_immortal_btn.text = "Immortal: ON" if builder_immortal else "Mortality: ON"
	builder_items.clear()
	for it in m.get("items", []):
		if typeof(it) == TYPE_DICTIONARY:
			builder_items.append(it.duplicate(true))
	_update_builder_info()
	if builder_canvas:
		builder_canvas.queue_redraw()

class _BuilderTrackCanvas extends Control:
	var owner_ui: PracticeHubUI
	const WORLD_SCALE_X: float = 0.35 # 1200px canvas = ~3400px world
	const CANVAS_GROUND_Y: float = 104.0

	func _init(p_owner: PracticeHubUI) -> void:
		owner_ui = p_owner
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.08, 0.11))
		# Grid lines
		for gx in range(0, int(size.x), 42):
			draw_line(Vector2(gx, 0), Vector2(gx, size.y), Color(0.14, 0.18, 0.24), 1.0)
		# Ground line
		draw_rect(Rect2(0, CANVAS_GROUND_Y, size.x, size.y - CANVAS_GROUND_Y), Color(0.22, 0.34, 0.20))
		draw_line(Vector2(0, CANVAS_GROUND_Y), Vector2(size.x, CANVAS_GROUND_Y), Color(0.45, 0.78, 0.42), 2.0)

		if not owner_ui:
			return
		for it in owner_ui.builder_items:
			var wx: float = float(it.get("x", 300.0))
			var wy: float = float(it.get("y", 216.0))
			var cx: float = wx * WORLD_SCALE_X
			var cy: float = CANVAS_GROUND_Y - (224.0 - wy) * 0.45
			var col: Color = Color.WHITE
			var lbl: String = "?"
			for p in PracticeHubUI.BUILDER_PALETTE:
				if p["id"] == it.get("type", ""):
					col = p["color"]
					lbl = p["label"].substr(0, 3).to_upper()
					break
			draw_rect(Rect2(cx - 8, cy - 8, 16, 16), col)
			draw_rect(Rect2(cx - 8, cy - 8, 16, 16), Color.WHITE, false, 1.0)

	func _gui_input(event: InputEvent) -> void:
		if not owner_ui:
			return
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var pos: Vector2 = event.position
			var wx: float = clampf(roundf((pos.x / WORLD_SCALE_X) / 24.0) * 24.0, 260.0, 3400.0)
			var wy: float = clampf(224.0 - ((CANVAS_GROUND_Y - pos.y) / 0.45), 64.0, 224.0)
			wy = roundf(wy / 8.0) * 8.0

			if owner_ui.builder_selected_tool == "eraser":
				for i in range(owner_ui.builder_items.size() - 1, -1, -1):
					var it = owner_ui.builder_items[i]
					if absf(float(it.get("x", 0.0)) - wx) < 42.0:
						owner_ui.builder_items.remove_at(i)
						break
			else:
				owner_ui.builder_items.append({
					"type": owner_ui.builder_selected_tool,
					"x": wx,
					"y": wy
				})
			owner_ui._update_builder_info()
			queue_redraw()
			accept_event()
