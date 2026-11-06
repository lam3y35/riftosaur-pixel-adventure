class_name GameHUD
extends CanvasLayer

const SaveService = preload("res://scripts/systems/save_service.gd")
const ChallengeService = preload("res://scripts/systems/challenge_service.gd")

signal start_requested()
signal mode_selected(mode: int)
signal jump_requested(pressed: bool)
signal slide_requested(pressed: bool)
signal steer_requested(dir: float)
signal pause_requested()
signal resume_requested()
signal retry_requested()
signal menu_requested()
signal skin_selected(skin_id: String)
signal skill_requested()

@onready var score_label: Label = $TopBar/ScoreLabel
@onready var distance_label: Label = get_node_or_null("TopBar/DistanceLabel")
@onready var best_label: Label = $TopBar/BestLabel
@onready var points_label: Label = $TopBar/PointsLabel
@onready var gems_label: Label = get_node_or_null("TopBar/GemsLabel")
@onready var skill_slot: PanelContainer = get_node_or_null("TopBar/SkillSlot")
@onready var skill_icon: TextureRect = get_node_or_null("TopBar/SkillSlot/HBox/SkillIcon")
@onready var skill_label: Label = get_node_or_null("TopBar/SkillSlot/HBox/SkillLabel")
@onready var pause_button: Button = $TopBar/PauseButton

@onready var touch_controls: Control = $TouchControls
@onready var slide_button: Button = $TouchControls/SlideButton
@onready var steer_left_btn: Button = $TouchControls/SteerLeftButton
@onready var steer_right_btn: Button = $TouchControls/SteerRightButton
@onready var jump_button: Button = $TouchControls/JumpButton
@onready var skill_button: Button = get_node_or_null("TouchControls/SkillButton")
@onready var skill_toast: PanelContainer = get_node_or_null("SkillToast")
@onready var skill_toast_label: Label = get_node_or_null("SkillToast/SkillToastLabel")

@onready var start_menu: Control = $StartMenu
@onready var start_panel: PanelContainer = $StartMenu/Panel
@onready var mascot_left: TextureRect = get_node_or_null("StartMenu/Panel/VBox/HeaderHBox/MascotLeft")
@onready var mascot_right: TextureRect = get_node_or_null("StartMenu/Panel/VBox/HeaderHBox/MascotRight")
@onready var start_best_label: Label = $StartMenu/Panel/VBox/StatsHBox/StartBestLabel
@onready var start_points_label: Label = $StartMenu/Panel/VBox/StatsHBox/StartPointsLabel
@onready var mode_casual_btn: Button = $StartMenu/Panel/VBox/ModeHBox/ModeCasualBtn
@onready var mode_runner_btn: Button = $StartMenu/Panel/VBox/ModeHBox/ModeRunnerBtn
@onready var mode_freestyle_btn: Button = $StartMenu/Panel/VBox/ModeHBox/ModeFreestyleBtn
@onready var mode_desc_label: Label = $StartMenu/Panel/VBox/ModeDescLabel
@onready var start_shop_btn: Button = $StartMenu/Panel/VBox/ShopQuestsHBox/StartShopBtn
@onready var start_quests_btn: Button = $StartMenu/Panel/VBox/ShopQuestsHBox/StartQuestsBtn
@onready var play_button: Button = $StartMenu/Panel/VBox/PlayButton

@onready var pause_menu: Control = $PauseMenu
@onready var pause_panel: PanelContainer = $PauseMenu/Panel
@onready var resume_button: Button = $PauseMenu/Panel/VBox/ResumeButton
@onready var restart_button: Button = $PauseMenu/Panel/VBox/RestartButton
@onready var pause_menu_button: Button = $PauseMenu/Panel/VBox/PauseMenuButton

@onready var game_over_menu: Control = $GameOverMenu
@onready var game_over_panel: PanelContainer = $GameOverMenu/Panel
@onready var cause_label: Label = $GameOverMenu/Panel/VBox/CauseLabel
@onready var final_score_label: Label = $GameOverMenu/Panel/VBox/StatsHBox/FinalScoreLabel
@onready var final_dist_label: Label = get_node_or_null("GameOverMenu/Panel/VBox/StatsHBox/FinalDistLabel")
@onready var run_points_label: Label = $GameOverMenu/Panel/VBox/RunPointsLabel
@onready var best_score_label: Label = $GameOverMenu/Panel/VBox/TotalsHBox/BestScoreLabel
@onready var total_points_label: Label = $GameOverMenu/Panel/VBox/TotalsHBox/TotalPointsLabel
@onready var new_best_label: Label = $GameOverMenu/Panel/VBox/NewBestLabel
@onready var game_over_shop_btn: Button = $GameOverMenu/Panel/VBox/GameOverShopQuestsHBox/GameOverShopBtn
@onready var game_over_quests_btn: Button = $GameOverMenu/Panel/VBox/GameOverShopQuestsHBox/GameOverQuestsBtn
@onready var retry_button: Button = $GameOverMenu/Panel/VBox/RetryButton
@onready var game_over_menu_button: Button = $GameOverMenu/Panel/VBox/GameOverMenuButton

# Shop & Quests Dialogs
@onready var skin_shop_dialog: Control = $SkinShopDialog
@onready var shop_panel: PanelContainer = $SkinShopDialog/Panel
@onready var shop_points_label: Label = $SkinShopDialog/Panel/VBox/HeaderHBox/ShopPointsLabel
@onready var shop_close_btn: Button = $SkinShopDialog/Panel/VBox/HeaderHBox/ShopCloseBtn
@onready var skins_hbox: HBoxContainer = $SkinShopDialog/Panel/VBox/SkinsHBox

@onready var challenges_dialog: Control = $ChallengesDialog
@onready var quests_panel: PanelContainer = $ChallengesDialog/Panel
@onready var quests_points_label: Label = $ChallengesDialog/Panel/VBox/HeaderHBox/QuestsPointsLabel
@onready var quests_close_btn: Button = $ChallengesDialog/Panel/VBox/HeaderHBox/QuestsCloseBtn
@onready var quests_bottom_close_btn: Button = $ChallengesDialog/Panel/VBox/QuestsBottomCloseBtn
@onready var quests_scroll: ScrollContainer = $ChallengesDialog/Panel/VBox/ScrollContainer
@onready var quests_list: VBoxContainer = $ChallengesDialog/Panel/VBox/ScrollContainer/QuestsList

@onready var challenge_toast: PanelContainer = $ChallengeToast
@onready var toast_label: Label = $ChallengeToast/ToastLabel

var current_mode: int = 1 # 0 = Casual, 1 = Runner, 2 = Freestyle
var retry_debounce: bool = false
var save_service: SaveService
var challenge_service: ChallengeService
var pulse_timer: float = 0.0

# Quests swipe / scroll touch handling
var _quest_scroll_dragging: bool = false
var _quest_scroll_drag_touch_id: int = -1
var _quest_scroll_velocity: float = 0.0

# Touch gesture tracking
var touch_start_positions: Dictionary = {}
var jump_touch_index: int = -1
var slide_touch_index: int = -1
const SWIPE_THRESHOLD: float = 20.0

const SKINS: Array[Dictionary] = [
	{
		"id": "classic",
		"name": "Classic",
		"price": 0,
		"icon": "res://assets/sprites/skin_icon_classic.png",
		"desc": "Shadow"
	},
	{
		"id": "emerald",
		"name": "Emerald",
		"price": 100,
		"icon": "res://assets/sprites/skin_icon_emerald.png",
		"desc": "Jungle"
	},
	{
		"id": "ruby",
		"name": "Ruby",
		"price": 250,
		"icon": "res://assets/sprites/skin_icon_ruby.png",
		"desc": "Magma"
	},
	{
		"id": "cyber",
		"name": "Cyber",
		"price": 500,
		"icon": "res://assets/sprites/skin_icon_cyber.png",
		"desc": "Rift"
	},
	{
		"id": "gold",
		"name": "Gold",
		"price": 1000,
		"icon": "res://assets/sprites/skin_icon_gold.png",
		"desc": "24K"
	}
]

func _ready() -> void:
	play_button.pressed.connect(func(): start_requested.emit())
	pause_button.pressed.connect(_on_pause_button_pressed)
	resume_button.pressed.connect(_on_resume_button_pressed)
	restart_button.pressed.connect(_on_restart_button_pressed)

	# Main Menu navigation
	pause_menu_button.pressed.connect(func(): menu_requested.emit())
	game_over_menu_button.pressed.connect(func(): menu_requested.emit())

	# Direct instant response on Retry Button
	retry_button.button_down.connect(_on_retry_button_pressed)
	retry_button.pressed.connect(_on_retry_button_pressed)

	# Mode selection buttons
	mode_casual_btn.pressed.connect(func(): select_mode(0))
	mode_runner_btn.pressed.connect(func(): select_mode(1))
	mode_freestyle_btn.pressed.connect(func(): select_mode(2))

	# Action buttons
	slide_button.button_down.connect(func(): slide_requested.emit(true))
	slide_button.button_up.connect(func(): slide_requested.emit(false))
	jump_button.button_down.connect(func(): jump_requested.emit(true))
	jump_button.button_up.connect(func(): jump_requested.emit(false))
	if skill_button:
		skill_button.pressed.connect(func(): skill_requested.emit())
		skill_button.button_down.connect(func(): skill_requested.emit())

	# Freestyle steer buttons
	steer_left_btn.button_down.connect(func(): steer_requested.emit(-1.0))
	steer_left_btn.button_up.connect(func(): steer_requested.emit(0.0))
	steer_right_btn.button_down.connect(func(): steer_requested.emit(1.0))
	steer_right_btn.button_up.connect(func(): steer_requested.emit(0.0))

	# Shop & Quests buttons
	start_shop_btn.pressed.connect(open_skin_shop)
	game_over_shop_btn.pressed.connect(open_skin_shop)
	shop_close_btn.pressed.connect(close_skin_shop)

	start_quests_btn.pressed.connect(open_challenges)
	game_over_quests_btn.pressed.connect(open_challenges)
	quests_close_btn.pressed.connect(close_challenges)
	quests_bottom_close_btn.pressed.connect(close_challenges)

	if quests_list:
		quests_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if quests_scroll:
		quests_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		quests_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		quests_scroll.gui_input.connect(_on_quests_scroll_gui_input)

	if distance_label:
		distance_label.visible = false
	if final_dist_label:
		final_dist_label.visible = false

	_apply_catchy_theme()
	select_mode(1) # Default to Runner mode

	pause_menu.visible = false
	game_over_menu.visible = false
	start_menu.visible = false
	skin_shop_dialog.visible = false
	challenges_dialog.visible = false
	challenge_toast.visible = false

func _process(delta: float) -> void:
	if start_menu.visible and not skin_shop_dialog.visible and not challenges_dialog.visible:
		pulse_timer += delta * 4.5
		var glow = 1.0 + 0.08 * sin(pulse_timer)
		play_button.modulate = Color(glow, glow + 0.04, glow, 1.0)

	if challenges_dialog.visible and quests_scroll:
		if not _quest_scroll_dragging and abs(_quest_scroll_velocity) > 5.0:
			quests_scroll.scroll_vertical -= int(_quest_scroll_velocity * delta)
			_quest_scroll_velocity = move_toward(_quest_scroll_velocity, 0.0, 1600.0 * delta)

# ==========================================
# Catchy Arcade UI Theme Engine
# ==========================================
func _make_box(bg: Color, border: Color, bw_side: int = 2, bw_bottom: int = 3, radius: int = 6, pad_h: int = 8, pad_v: int = 3, shadow: int = 3) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_left = bw_side
	sb.border_width_top = bw_side
	sb.border_width_right = bw_side
	sb.border_width_bottom = bw_bottom
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	sb.content_margin_left = pad_h
	sb.content_margin_right = pad_h
	sb.content_margin_top = pad_v
	sb.content_margin_bottom = pad_v
	if shadow > 0:
		sb.shadow_color = Color(0, 0, 0, 0.55)
		sb.shadow_size = shadow
		sb.shadow_offset = Vector2(0, 2)
	return sb

func _style_arcade_button(btn: Button, bg: Color, border: Color, font_size: int = 10, font_col: Color = Color.WHITE) -> void:
	if btn == null:
		return
	var normal = _make_box(bg, border, 2, 4, 6, 8, 3, 3)
	var hover = _make_box(bg.lightened(0.14), border.lightened(0.2), 2, 4, 6, 8, 3, 4)
	var pressed = _make_box(bg.darkened(0.15), border, 2, 2, 6, 8, 4, 1)
	var disabled = _make_box(Color(0.14, 0.18, 0.26, 0.9), Color(0.32, 0.38, 0.48, 0.8), 1, 2, 6, 8, 3, 0)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("focus", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", font_col)
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 0.85))
	btn.add_theme_color_override("font_pressed_color", Color(0.9, 0.95, 1.0))
	btn.add_theme_color_override("font_disabled_color", Color(0.58, 0.64, 0.72))
	btn.add_theme_constant_override("outline_size", 2)
	btn.add_theme_color_override("font_outline_color", Color(0.03, 0.05, 0.1, 1.0))

func _apply_catchy_theme() -> void:
	# 1. Modal Panels — Deep Arcade Indigo with Glowing Neon Borders
	var panel_cyan = _make_box(Color(0.06, 0.09, 0.18, 0.96), Color(0.22, 0.78, 0.98, 1.0), 2, 4, 10, 12, 8, 8)
	var panel_gold = _make_box(Color(0.07, 0.09, 0.18, 0.97), Color(0.98, 0.78, 0.18, 1.0), 2, 4, 10, 10, 8, 8)
	var panel_crimson = _make_box(Color(0.08, 0.07, 0.16, 0.96), Color(0.98, 0.38, 0.42, 1.0), 2, 4, 10, 12, 8, 8)

	if start_panel:
		start_panel.add_theme_stylebox_override("panel", panel_cyan)
	if pause_panel:
		pause_panel.add_theme_stylebox_override("panel", panel_cyan)
	if game_over_panel:
		game_over_panel.add_theme_stylebox_override("panel", panel_crimson)
	if shop_panel:
		shop_panel.add_theme_stylebox_override("panel", panel_gold)
	if quests_panel:
		quests_panel.add_theme_stylebox_override("panel", panel_gold)
	if challenge_toast:
		challenge_toast.add_theme_stylebox_override("panel", _make_box(Color(0.08, 0.14, 0.24, 0.96), Color(1.0, 0.84, 0.18, 1.0), 2, 3, 8, 10, 4, 6))

	# 2. TopBar HUD Pill Badges
	var pill_score = _make_box(Color(0.05, 0.11, 0.22, 0.86), Color(0.22, 0.78, 0.98, 0.95), 1, 2, 6, 6, 2, 2)
	var pill_best = _make_box(Color(0.09, 0.08, 0.22, 0.86), Color(0.68, 0.45, 0.98, 0.95), 1, 2, 6, 6, 2, 2)
	var pill_pts = _make_box(Color(0.14, 0.1, 0.04, 0.88), Color(0.98, 0.78, 0.18, 0.95), 1, 2, 6, 6, 2, 2)

	score_label.add_theme_stylebox_override("normal", pill_score)
	best_label.add_theme_stylebox_override("normal", pill_best)
	points_label.add_theme_stylebox_override("normal", pill_pts)

	start_best_label.add_theme_stylebox_override("normal", pill_best)
	start_points_label.add_theme_stylebox_override("normal", pill_pts)
	shop_points_label.add_theme_stylebox_override("normal", pill_pts)
	quests_points_label.add_theme_stylebox_override("normal", pill_pts)
	final_score_label.add_theme_stylebox_override("normal", pill_score)
	best_score_label.add_theme_stylebox_override("normal", pill_best)
	total_points_label.add_theme_stylebox_override("normal", pill_pts)

	# 3. Primary Play / Retry Buttons (Vibrant Emerald Arcade 3D)
	_style_arcade_button(play_button, Color(0.09, 0.64, 0.29), Color(0.45, 0.95, 0.62), 12)
	_style_arcade_button(retry_button, Color(0.09, 0.64, 0.29), Color(0.45, 0.95, 0.62), 11)
	_style_arcade_button(resume_button, Color(0.09, 0.64, 0.29), Color(0.45, 0.95, 0.62), 10)

	# 4. Shop & Quests Buttons (Royal Violet & Golden Amber)
	_style_arcade_button(start_shop_btn, Color(0.46, 0.22, 0.88), Color(0.76, 0.52, 0.99), 10)
	_style_arcade_button(game_over_shop_btn, Color(0.46, 0.22, 0.88), Color(0.76, 0.52, 0.99), 10)
	_style_arcade_button(start_quests_btn, Color(0.82, 0.46, 0.06), Color(0.99, 0.82, 0.26), 10)
	_style_arcade_button(game_over_quests_btn, Color(0.82, 0.46, 0.06), Color(0.99, 0.82, 0.26), 10)

	# 5. Secondary & Close Buttons
	_style_arcade_button(pause_button, Color(0.12, 0.22, 0.38, 0.9), Color(0.38, 0.78, 0.98), 9)
	_style_arcade_button(restart_button, Color(0.18, 0.32, 0.54), Color(0.45, 0.75, 0.98), 10)
	_style_arcade_button(pause_menu_button, Color(0.22, 0.26, 0.36), Color(0.52, 0.6, 0.74), 10)
	_style_arcade_button(game_over_menu_button, Color(0.22, 0.26, 0.36), Color(0.52, 0.6, 0.74), 10)
	_style_arcade_button(shop_close_btn, Color(0.75, 0.18, 0.24), Color(0.98, 0.48, 0.52), 10)
	_style_arcade_button(quests_close_btn, Color(0.75, 0.18, 0.24), Color(0.98, 0.48, 0.52), 10)
	_style_arcade_button(quests_bottom_close_btn, Color(0.18, 0.32, 0.54), Color(0.45, 0.75, 0.98), 10)

	# 6. On-Screen Touch Controls (Frosted Glassmorphic Arcade Pads)
	_style_arcade_button(jump_button, Color(0.08, 0.38, 0.68, 0.62), Color(0.45, 0.88, 1.0, 0.9), 11)
	_style_arcade_button(slide_button, Color(0.58, 0.32, 0.08, 0.62), Color(1.0, 0.78, 0.32, 0.9), 11)
	_style_arcade_button(steer_left_btn, Color(0.14, 0.28, 0.48, 0.62), Color(0.55, 0.85, 1.0, 0.9), 11)
	_style_arcade_button(steer_right_btn, Color(0.14, 0.28, 0.48, 0.62), Color(0.55, 0.85, 1.0, 0.9), 11)

func bind_services(p_save: SaveService, p_challenge: ChallengeService) -> void:
	save_service = p_save
	challenge_service = p_challenge
	if challenge_service:
		challenge_service.challenge_unlocked.connect(_on_challenge_unlocked)
	_update_mascot_icons()

func _update_mascot_icons() -> void:
	if save_service == null:
		return
	var equipped = save_service.get_equipped_skin()
	for s in SKINS:
		if s["id"] == equipped and ResourceLoader.exists(s["icon"]):
			var tex = load(s["icon"])
			if mascot_left:
				mascot_left.texture = tex
			if mascot_right:
				mascot_right.texture = tex
			break

func select_mode(mode: int) -> void:
	current_mode = mode
	mode_selected.emit(mode)

	var active_bg = Color(0.85, 0.52, 0.06)
	var active_border = Color(1.0, 0.92, 0.38)
	var idle_bg = Color(0.14, 0.19, 0.3)
	var idle_border = Color(0.34, 0.44, 0.6)

	_style_arcade_button(mode_casual_btn, active_bg if mode == 0 else idle_bg, active_border if mode == 0 else idle_border, 9)
	_style_arcade_button(mode_runner_btn, active_bg if mode == 1 else idle_bg, active_border if mode == 1 else idle_border, 9)
	_style_arcade_button(mode_freestyle_btn, active_bg if mode == 2 else idle_bg, active_border if mode == 2 else idle_border, 9)

	match mode:
		0: # Arcade Jump (Spicy)
			mode_desc_label.text = "⚡ Fast Spicy Speed • Pure Jump Reflexes • Tap Anywhere!"
			slide_button.visible = false
			steer_left_btn.visible = false
			steer_right_btn.visible = false
		1: # Runner
			mode_desc_label.text = "🔥 Accelerating Speed • Jump & Slide • Intense Rhythm"
			slide_button.visible = true
			slide_button.offset_left = 14.0
			slide_button.offset_right = 96.0
			slide_button.text = "▼ SLIDE"
			steer_left_btn.visible = false
			steer_right_btn.visible = false
		2: # Freestyle
			mode_desc_label.text = "🌀 Steer Left/Right • Air Control • Master Precision"
			steer_left_btn.visible = true
			steer_right_btn.visible = true
			slide_button.visible = true
			slide_button.offset_left = 130.0
			slide_button.offset_right = 198.0
			slide_button.text = "▼ DUCK"

func show_start_menu(best_score: int, points: int = 0) -> void:
	start_best_label.text = "🏆 BEST: %05d" % best_score
	start_points_label.text = "💎 PTS: %05d" % points
	points_label.text = "💎 PTS: %05d" % points
	_update_mascot_icons()
	start_menu.visible = true
	touch_controls.visible = false
	skin_shop_dialog.visible = false
	challenges_dialog.visible = false

func hide_start_menu() -> void:
	start_menu.visible = false
	skin_shop_dialog.visible = false
	challenges_dialog.visible = false
	touch_controls.visible = true

func update_hud(score: int, _distance_m: float = 0.0, best_score: int = 0, points: int = 0) -> void:
	score_label.text = "SCORE: %05d" % score
	best_label.text = "🏆 HI: %05d" % best_score
	points_label.text = "💎 PTS: %05d" % points
	if distance_label:
		distance_label.visible = false

func update_gems(count: int) -> void:
	if gems_label:
		gems_label.text = "💎 %d" % count

func update_skill_slot(info: Dictionary, cd: float = 0.0, dur: float = 0.0, charges: int = 1) -> void:
	if skill_slot:
		var has_skill = info.get("name", "None") != "None"
		skill_slot.visible = has_skill
		if has_skill:
			var icon_p = info.get("icon", "")
			if skill_icon and icon_p != "" and ResourceLoader.exists(icon_p):
				skill_icon.texture = load(icon_p)
			update_skill_status(cd, dur, charges)

func update_skill_status(cd: float, dur: float, charges: int) -> void:
	if skill_label:
		if cd > 0.0:
			skill_label.text = "%.1fs" % cd
			skill_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.35))
		elif dur > 0.0:
			skill_label.text = "%.1fs" % dur
			skill_label.add_theme_color_override("font_color", Color(0.35, 1.0, 0.6))
		elif charges > 1:
			skill_label.text = "x%d" % charges
			skill_label.add_theme_color_override("font_color", Color(0.45, 0.9, 1.0))
		elif charges == 1:
			skill_label.text = "RDY"
			skill_label.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
		else:
			skill_label.text = "--"
			skill_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))

func show_skill_toast(message: String) -> void:
	if skill_toast and skill_toast_label:
		skill_toast_label.text = message
		skill_toast.visible = true
		skill_toast.modulate.a = 0.0
		var tw = create_tween()
		if tw:
			tw.tween_property(skill_toast, "modulate:a", 1.0, 0.15)
			tw.tween_interval(1.8)
			tw.tween_property(skill_toast, "modulate:a", 0.0, 0.35)
			tw.tween_callback(func(): skill_toast.visible = false)

func show_game_over(cause: String, score: int, _distance_m: float = 0.0, best_score: int = 0, is_new_best: bool = false, run_pts: int = 0, total_pts: int = 0) -> void:
	cause_label.text = cause
	final_score_label.text = "FINAL SCORE: %05d" % score
	best_score_label.text = "🏆 BEST: %05d" % best_score
	run_points_label.text = "✨ +%d PTS EARNED ✨" % run_pts
	total_points_label.text = "💎 TOTAL PTS: %d" % total_pts
	new_best_label.visible = is_new_best
	if final_dist_label:
		final_dist_label.visible = false
	game_over_menu.visible = true
	touch_controls.visible = false
	skin_shop_dialog.visible = false
	challenges_dialog.visible = false
	retry_debounce = false

func hide_game_over() -> void:
	game_over_menu.visible = false
	skin_shop_dialog.visible = false
	challenges_dialog.visible = false
	touch_controls.visible = true

func show_pause_menu() -> void:
	pause_menu.visible = true
	touch_controls.visible = false

func hide_pause_menu() -> void:
	pause_menu.visible = false
	touch_controls.visible = true

# ==========================================
# Skin Shop Implementation
# ==========================================
func open_skin_shop() -> void:
	skin_shop_dialog.visible = true
	refresh_skin_shop()

func close_skin_shop() -> void:
	skin_shop_dialog.visible = false

func refresh_skin_shop() -> void:
	if save_service == null:
		return
	var current_pts = save_service.get_points()
	var equipped = save_service.get_equipped_skin()
	shop_points_label.text = "💎 PTS: %05d" % current_pts
	points_label.text = "💎 PTS: %05d" % current_pts
	start_points_label.text = "💎 PTS: %05d" % current_pts
	_update_mascot_icons()

	for child in skins_hbox.get_children():
		child.queue_free()

	for skin_info in SKINS:
		var card = _create_skin_card(skin_info, current_pts, equipped)
		skins_hbox.add_child(card)

func _create_skin_card(info: Dictionary, current_pts: int, equipped_skin: String) -> Control:
	var skin_id: String = info["id"]
	var is_unlocked: bool = save_service.is_skin_unlocked(skin_id)
	var is_equipped: bool = (skin_id == equipped_skin)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(80, 165)

	if is_equipped:
		panel.add_theme_stylebox_override("panel", _make_box(Color(0.06, 0.22, 0.36, 0.96), Color(0.25, 0.88, 1.0), 2, 3, 8, 5, 6, 4))
	elif is_unlocked:
		panel.add_theme_stylebox_override("panel", _make_box(Color(0.08, 0.18, 0.24, 0.95), Color(0.28, 0.78, 0.52), 1, 3, 8, 5, 6, 2))
	elif current_pts >= info["price"]:
		panel.add_theme_stylebox_override("panel", _make_box(Color(0.14, 0.12, 0.22, 0.95), Color(0.98, 0.78, 0.22), 1, 3, 8, 5, 6, 2))
	else:
		panel.add_theme_stylebox_override("panel", _make_box(Color(0.09, 0.11, 0.18, 0.92), Color(0.26, 0.32, 0.44), 1, 2, 8, 5, 6, 1))

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	# Name Label
	var name_lbl = Label.new()
	name_lbl.text = info["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
	name_lbl.add_theme_constant_override("outline_size", 2)
	name_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	vbox.add_child(name_lbl)

	# Framed Icon Preview (40x40 crisp nearest-neighbor)
	var icon_frame = PanelContainer.new()
	icon_frame.add_theme_stylebox_override("panel", _make_box(Color(0.03, 0.06, 0.12, 0.9), Color(0.22, 0.36, 0.54), 1, 1, 6, 4, 4, 0))
	var icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(36, 36)
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if ResourceLoader.exists(info["icon"]):
		icon_rect.texture = load(info["icon"])
	icon_frame.add_child(icon_rect)
	vbox.add_child(icon_frame)

	# Price / Status Label
	var price_lbl = Label.new()
	price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_lbl.add_theme_font_size_override("font_size", 9)
	price_lbl.add_theme_constant_override("outline_size", 2)
	price_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	if is_unlocked:
		price_lbl.text = "✓ OWNED"
		price_lbl.add_theme_color_override("font_color", Color(0.38, 0.98, 0.56))
	else:
		price_lbl.text = "💎 %d PTS" % info["price"]
		price_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.22))
	vbox.add_child(price_lbl)

	# Action Button
	var btn = Button.new()
	if is_equipped:
		btn.text = "★ ACTIVE"
		btn.disabled = true
		_style_arcade_button(btn, Color(0.08, 0.45, 0.68), Color(0.38, 0.9, 1.0), 9)
		btn.add_theme_color_override("font_disabled_color", Color(0.45, 0.95, 1.0))
	elif is_unlocked:
		btn.text = "EQUIP"
		_style_arcade_button(btn, Color(0.12, 0.58, 0.34), Color(0.42, 0.95, 0.62), 9)
		btn.pressed.connect(func(): _on_equip_clicked(skin_id))
	else:
		if current_pts >= info["price"]:
			btn.text = "BUY NOW"
			_style_arcade_button(btn, Color(0.84, 0.52, 0.06), Color(1.0, 0.88, 0.32), 9)
			btn.pressed.connect(func(): _on_buy_clicked(skin_id, info["price"]))
		else:
			btn.text = "LOCKED"
			btn.disabled = true
			_style_arcade_button(btn, Color(0.16, 0.19, 0.26), Color(0.32, 0.38, 0.48), 9)
	vbox.add_child(btn)

	return panel

func _on_buy_clicked(skin_id: String, price: int) -> void:
	if save_service and save_service.spend_points(price):
		save_service.unlock_skin(skin_id)
		save_service.equip_skin(skin_id)
		skin_selected.emit(skin_id)
		refresh_skin_shop()

func _on_equip_clicked(skin_id: String) -> void:
	if save_service and save_service.equip_skin(skin_id):
		skin_selected.emit(skin_id)
		refresh_skin_shop()

# ==========================================
# Challenges / Quests Implementation
# ==========================================
func open_challenges() -> void:
	_quest_scroll_dragging = false
	_quest_scroll_drag_touch_id = -1
	_quest_scroll_velocity = 0.0
	challenges_dialog.visible = true
	refresh_challenges()

func close_challenges() -> void:
	_quest_scroll_dragging = false
	_quest_scroll_drag_touch_id = -1
	_quest_scroll_velocity = 0.0
	challenges_dialog.visible = false

func refresh_challenges() -> void:
	if save_service == null or challenge_service == null:
		return
	var current_pts = save_service.get_points()
	quests_points_label.text = "💎 PTS: %05d" % current_pts

	for child in quests_list.get_children():
		child.queue_free()

	for ch in challenge_service.get_all_challenges():
		var row = _create_challenge_row(ch)
		quests_list.add_child(row)

func _create_challenge_row(ch: Dictionary) -> Control:
	var is_comp = save_service.is_challenge_completed(ch["id"])

	var panel = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_comp:
		panel.add_theme_stylebox_override("panel", _make_box(Color(0.06, 0.2, 0.16, 0.94), Color(0.28, 0.88, 0.5), 1, 2, 6, 8, 4, 1))
	else:
		panel.add_theme_stylebox_override("panel", _make_box(Color(0.09, 0.13, 0.22, 0.94), Color(0.28, 0.38, 0.56), 1, 2, 6, 8, 4, 1))

	var hbox = HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 8)
	panel.add_child(hbox)

	var text_vbox = VBoxContainer.new()
	text_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.add_theme_constant_override("separation", 1)

	var title_lbl = Label.new()
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_lbl.text = ("★ " if is_comp else "☆ ") + ch["title"]
	title_lbl.add_theme_font_size_override("font_size", 10)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.32))
	title_lbl.add_theme_constant_override("outline_size", 2)
	title_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	text_vbox.add_child(title_lbl)

	var desc_lbl = Label.new()
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_lbl.text = ch["desc"]
	desc_lbl.add_theme_font_size_override("font_size", 9)
	desc_lbl.add_theme_color_override("font_color", Color(0.84, 0.9, 0.98))
	text_vbox.add_child(desc_lbl)

	hbox.add_child(text_vbox)

	var reward_lbl = Label.new()
	reward_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward_lbl.text = "💎 +%d PTS" % ch["reward"]
	reward_lbl.add_theme_font_size_override("font_size", 10)
	reward_lbl.add_theme_color_override("font_color", Color(1.0, 0.86, 0.22))
	reward_lbl.add_theme_constant_override("outline_size", 2)
	reward_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	hbox.add_child(reward_lbl)

	var status_lbl = Label.new()
	status_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_lbl.add_theme_font_size_override("font_size", 9)
	status_lbl.add_theme_constant_override("outline_size", 2)
	status_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	if is_comp:
		status_lbl.text = "✓ CLAIMED"
		status_lbl.add_theme_color_override("font_color", Color(0.35, 1.0, 0.52))
	else:
		status_lbl.text = "ACTIVE"
		status_lbl.add_theme_color_override("font_color", Color(0.55, 0.75, 0.95))
	hbox.add_child(status_lbl)

	return panel

func _on_quests_scroll_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_quest_scroll_dragging = true
			_quest_scroll_drag_touch_id = event.index
			_quest_scroll_velocity = 0.0
		elif event.index == _quest_scroll_drag_touch_id:
			_quest_scroll_dragging = false
			_quest_scroll_drag_touch_id = -1
		if quests_scroll:
			quests_scroll.accept_event()
	elif event is InputEventScreenDrag:
		if _quest_scroll_dragging and event.index == _quest_scroll_drag_touch_id:
			if quests_scroll:
				quests_scroll.scroll_vertical -= int(event.relative.y)
			_quest_scroll_velocity = event.velocity.y
		if quests_scroll:
			quests_scroll.accept_event()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_quest_scroll_dragging = true
				_quest_scroll_velocity = 0.0
			else:
				_quest_scroll_dragging = false
			if quests_scroll:
				quests_scroll.accept_event()
	elif event is InputEventMouseMotion:
		if _quest_scroll_dragging:
			if quests_scroll:
				quests_scroll.scroll_vertical -= int(event.relative.y)
			_quest_scroll_velocity = event.velocity.y
			if quests_scroll:
				quests_scroll.accept_event()

func _on_challenge_unlocked(_id: String, title: String, reward: int) -> void:
	show_challenge_toast(title, reward)

func show_challenge_toast(title: String, reward: int) -> void:
	toast_label.text = "🏆 QUEST COMPLETE: %s (+%d PTS)!" % [title, reward]
	challenge_toast.visible = true
	challenge_toast.modulate.a = 0.0

	var tw = create_tween()
	tw.tween_property(challenge_toast, "modulate:a", 1.0, 0.25)
	tw.tween_interval(2.5)
	tw.tween_property(challenge_toast, "modulate:a", 0.0, 0.45)
	tw.tween_callback(func(): challenge_toast.visible = false)

# ==========================================
# Input & Touch Handling
# ==========================================
func _unhandled_input(event: InputEvent) -> void:
	if challenges_dialog.visible or skin_shop_dialog.visible or start_menu.visible or pause_menu.visible or game_over_menu.visible:
		if game_over_menu.visible and event.is_action_pressed("jump"):
			_on_retry_button_pressed()
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			_handle_touch_down(event.index, event.position)
		else:
			_handle_touch_up(event.index, event.position)
	elif event is InputEventScreenDrag:
		_handle_touch_drag(event.index, event.position)

func _handle_touch_down(index: int, pos: Vector2) -> void:
	touch_start_positions[index] = pos

	var vp_width = get_viewport().get_visible_rect().size.x
	var split_x = vp_width * 0.5

	if pos.y < 34.0:
		return

	if current_mode == 0:
		if jump_touch_index == -1:
			jump_touch_index = index
			jump_requested.emit(true)
		return

	if pos.x >= split_x:
		if jump_touch_index == -1:
			jump_touch_index = index
			jump_requested.emit(true)
	else:
		if current_mode == 1:
			if slide_touch_index == -1:
				slide_touch_index = index
				slide_requested.emit(true)

func _handle_touch_drag(index: int, pos: Vector2) -> void:
	if current_mode == 1 and index == slide_touch_index and touch_start_positions.has(index):
		var start_pos: Vector2 = touch_start_positions[index]
		var delta = pos - start_pos
		if delta.y > SWIPE_THRESHOLD:
			slide_requested.emit(true)

func _handle_touch_up(index: int, _pos: Vector2) -> void:
	if index == jump_touch_index:
		jump_touch_index = -1
		jump_requested.emit(false)
	elif index == slide_touch_index:
		slide_touch_index = -1
		slide_requested.emit(false)

	touch_start_positions.erase(index)

func _on_pause_button_pressed() -> void:
	pause_requested.emit()

func _on_resume_button_pressed() -> void:
	resume_requested.emit()

func _on_restart_button_pressed() -> void:
	retry_requested.emit()

func _on_retry_button_pressed() -> void:
	if retry_debounce:
		return
	retry_debounce = true
	retry_requested.emit()
