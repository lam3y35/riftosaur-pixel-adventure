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
signal flight_up_requested(pressed: bool)
signal flight_down_requested(pressed: bool)
signal settings_changed()
signal ui_interacted()

@onready var top_bar: Control = $TopBar
@onready var score_label: Label = $TopBar/ScoreLabel
@onready var distance_label: Label = get_node_or_null("TopBar/DistanceLabel")
@onready var best_label: Label = $TopBar/BestLabel
@onready var points_label: Label = $TopBar/PointsLabel
@onready var gems_label: Label = get_node_or_null("TopBar/GemsLabel")
@onready var skill_slot: PanelContainer = get_node_or_null("TopBar/SkillSlot")
@onready var skill_icon: TextureRect = get_node_or_null("TopBar/SkillSlot/HBox/SkillIcon")
@onready var skill_label: Label = get_node_or_null("TopBar/SkillSlot/HBox/SkillLabel")
@onready var world_label: Label = get_node_or_null("TopBar/WorldLabel")
@onready var seed_label: Label = get_node_or_null("TopBar/SeedLabel")
@onready var pause_button: Button = $TopBar/PauseButton

@onready var touch_controls: Control = $TouchControls
@onready var slide_button: Button = $TouchControls/SlideButton
@onready var steer_left_btn: Button = $TouchControls/SteerLeftButton
@onready var steer_right_btn: Button = $TouchControls/SteerRightButton
@onready var jump_button: Button = $TouchControls/JumpButton
@onready var skill_button: Button = get_node_or_null("TouchControls/SkillButton")
@onready var flight_controls: Control = get_node_or_null("TouchControls/FlightControls")
@onready var flight_up_btn: Button = get_node_or_null("TouchControls/FlightControls/FlightUpButton")
@onready var flight_down_btn: Button = get_node_or_null("TouchControls/FlightControls/FlightDownButton")

@onready var skill_toast: PanelContainer = get_node_or_null("SkillToast")
@onready var skill_toast_label: Label = get_node_or_null("SkillToast/SkillToastLabel")
@onready var flight_timer_bar: PanelContainer = get_node_or_null("FlightTimerBar")
@onready var flight_icon_label: Label = get_node_or_null("FlightTimerBar/HBox/FlightIconLabel")
@onready var flight_timer_label: Label = get_node_or_null("FlightTimerBar/HBox/FlightTimerLabel")
@onready var flight_warning_label: Label = get_node_or_null("FlightTimerBar/HBox/FlightWarningLabel")
@onready var world_card: PanelContainer = get_node_or_null("WorldTransitionCard")
@onready var world_title_label: Label = get_node_or_null("WorldTransitionCard/VBox/WorldTitleLabel")
@onready var world_intro_label: Label = get_node_or_null("WorldTransitionCard/VBox/WorldIntroLabel")

@onready var start_menu: Control = $StartMenu
@onready var start_panel: PanelContainer = $StartMenu/Panel
@onready var mascot_left: TextureRect = get_node_or_null("StartMenu/Panel/VBox/HeaderHBox/MascotLeft")
@onready var mascot_right: TextureRect = get_node_or_null("StartMenu/Panel/VBox/HeaderHBox/MascotRight")
@onready var start_best_label: Label = $StartMenu/Panel/VBox/StatsHBox/StartBestLabel
@onready var start_points_label: Label = $StartMenu/Panel/VBox/StatsHBox/StartPointsLabel
@onready var mode_casual_btn: Button = $StartMenu/Panel/VBox/ModeHBox/ModeCasualBtn
@onready var mode_runner_btn: Button = $StartMenu/Panel/VBox/ModeHBox/ModeRunnerBtn
@onready var mode_freestyle_btn: Button = $StartMenu/Panel/VBox/ModeHBox/ModeFreestyleBtn
@onready var mode_practice_btn: Button = get_node_or_null("StartMenu/Panel/VBox/ModeHBox/ModePracticeBtn")
@onready var mode_desc_label: Label = $StartMenu/Panel/VBox/ModeDescLabel
@onready var start_shop_btn: Button = $StartMenu/Panel/VBox/ShopQuestsHBox/StartShopBtn
@onready var start_quests_btn: Button = $StartMenu/Panel/VBox/ShopQuestsHBox/StartQuestsBtn
@onready var start_settings_btn: Button = get_node_or_null("StartMenu/Panel/VBox/ExtraMenuHBox/StartSettingsBtn")
@onready var start_tutorial_btn: Button = get_node_or_null("StartMenu/Panel/VBox/ExtraMenuHBox/StartTutorialBtn")
@onready var start_credits_btn: Button = get_node_or_null("StartMenu/Panel/VBox/ExtraMenuHBox/StartCreditsBtn")
@onready var play_button: Button = $StartMenu/Panel/VBox/PlayButton
@onready var controls_hint: Label = get_node_or_null("StartMenu/Panel/VBox/ControlsHint")

@onready var pause_menu: Control = $PauseMenu
@onready var pause_panel: PanelContainer = $PauseMenu/Panel
@onready var resume_button: Button = $PauseMenu/Panel/VBox/ResumeButton
@onready var restart_button: Button = $PauseMenu/Panel/VBox/RestartButton
@onready var pause_settings_btn: Button = get_node_or_null("PauseMenu/Panel/VBox/PauseSettingsBtn")
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
@onready var skins_hbox: HBoxContainer = $SkinShopDialog/Panel/VBox/ShopScroll/SkinsHBox

@onready var challenges_dialog: Control = $ChallengesDialog
@onready var quests_panel: PanelContainer = $ChallengesDialog/Panel
@onready var quests_points_label: Label = $ChallengesDialog/Panel/VBox/HeaderHBox/QuestsPointsLabel
@onready var quests_close_btn: Button = $ChallengesDialog/Panel/VBox/HeaderHBox/QuestsCloseBtn
@onready var quests_bottom_close_btn: Button = $ChallengesDialog/Panel/VBox/QuestsBottomCloseBtn
@onready var quests_scroll: ScrollContainer = $ChallengesDialog/Panel/VBox/ScrollContainer
@onready var quests_list: VBoxContainer = $ChallengesDialog/Panel/VBox/ScrollContainer/QuestsList

@onready var challenge_toast: PanelContainer = $ChallengeToast
@onready var toast_label: Label = $ChallengeToast/ToastLabel

# Settings Dialog
@onready var settings_dialog: Control = get_node_or_null("SettingsDialog")
@onready var settings_close_btn: Button = get_node_or_null("SettingsDialog/Panel/VBox/HeaderHBox/SettingsCloseBtn")
@onready var settings_scroll: ScrollContainer = get_node_or_null("SettingsDialog/Panel/VBox/SettingsScroll")
@onready var sound_toggle_btn: Button = get_node_or_null("SettingsDialog/Panel/VBox/SettingsScroll/SettingsList/SoundToggleBtn")
@onready var vibration_toggle_btn: Button = get_node_or_null("SettingsDialog/Panel/VBox/SettingsScroll/SettingsList/VibrationToggleBtn")
@onready var motion_toggle_btn: Button = get_node_or_null("SettingsDialog/Panel/VBox/SettingsScroll/SettingsList/MotionToggleBtn")
@onready var contrast_toggle_btn: Button = get_node_or_null("SettingsDialog/Panel/VBox/SettingsScroll/SettingsList/ContrastToggleBtn")
@onready var handed_toggle_btn: Button = get_node_or_null("SettingsDialog/Panel/VBox/SettingsScroll/SettingsList/HandedToggleBtn")
@onready var auto_hold_toggle_btn: Button = get_node_or_null("SettingsDialog/Panel/VBox/SettingsScroll/SettingsList/AutoHoldToggleBtn")

# Credits Dialog
@onready var credits_dialog: Control = get_node_or_null("CreditsDialog")
@onready var credits_close_btn: Button = get_node_or_null("CreditsDialog/Panel/VBox/HeaderHBox/CreditsCloseBtn")

# Tutorial Dialog
@onready var tutorial_dialog: Control = get_node_or_null("TutorialDialog")
@onready var tutorial_step_label: Label = get_node_or_null("TutorialDialog/Panel/VBox/HeaderHBox/TutorialStepLabel")
@onready var tutorial_desc_label: Label = get_node_or_null("TutorialDialog/Panel/VBox/TutorialDescLabel")
@onready var tutorial_close_btn: Button = get_node_or_null("TutorialDialog/Panel/VBox/HeaderHBox/TutorialCloseBtn")
@onready var tutorial_prev_btn: Button = get_node_or_null("TutorialDialog/Panel/VBox/TutorialActionHBox/TutorialPrevBtn")
@onready var tutorial_next_btn: Button = get_node_or_null("TutorialDialog/Panel/VBox/TutorialActionHBox/TutorialNextBtn")

# Developer Overlay
@onready var dev_overlay: PanelContainer = get_node_or_null("DevOverlay")
@onready var dev_text: Label = get_node_or_null("DevOverlay/DevText")

var tutorial_step: int = 0
var prev_menu_before_settings: String = "start"

var current_mode: int = 1 # 0 = Casual, 1 = Runner, 2 = Freestyle, 3 = Practice
var retry_debounce: bool = false
var save_service: SaveService
var challenge_service: ChallengeService
var pulse_timer: float = 0.0

# Dynamic HUD widgets & tween handles
var combo_panel: PanelContainer
var combo_label: Label
var combo_bar: ColorRect
var combo_bar_fill: ColorRect
var settings_music_btn: Button
var settings_sfx_btn: Button
var settings_dev_btn: Button
var career_summary_label: Label
var _skill_toast_tween: Tween
var _world_toast_tween: Tween
var _challenge_toast_tween: Tween
var _high_contrast_active: bool = false
var _has_active_skill_button: bool = false

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
		skill_button.button_down.connect(func(): skill_requested.emit())

	# Flight up and down buttons (shown only during flight)
	if flight_up_btn:
		flight_up_btn.button_down.connect(func(): flight_up_requested.emit(true))
		flight_up_btn.button_up.connect(func(): flight_up_requested.emit(false))
	if flight_down_btn:
		flight_down_btn.button_down.connect(func(): flight_down_requested.emit(true))
		flight_down_btn.button_up.connect(func(): flight_down_requested.emit(false))

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

	if mode_practice_btn:
		mode_practice_btn.pressed.connect(func(): select_mode(3))

	if start_settings_btn:
		start_settings_btn.pressed.connect(func(): open_settings("start"))
	if pause_settings_btn:
		pause_settings_btn.pressed.connect(func(): open_settings("pause"))
	if settings_close_btn:
		settings_close_btn.pressed.connect(close_settings)

	if sound_toggle_btn:
		sound_toggle_btn.pressed.connect(_on_sound_toggle_pressed)
	if vibration_toggle_btn:
		vibration_toggle_btn.pressed.connect(_on_vibration_toggle_pressed)
	if motion_toggle_btn:
		motion_toggle_btn.pressed.connect(_on_motion_toggle_pressed)
	if contrast_toggle_btn:
		contrast_toggle_btn.pressed.connect(_on_contrast_toggle_pressed)
	if handed_toggle_btn:
		handed_toggle_btn.pressed.connect(_on_handed_toggle_pressed)
	if auto_hold_toggle_btn:
		auto_hold_toggle_btn.pressed.connect(_on_auto_hold_toggle_pressed)

	if start_credits_btn:
		start_credits_btn.pressed.connect(open_credits)
	if credits_close_btn:
		credits_close_btn.pressed.connect(close_credits)

	if start_tutorial_btn:
		start_tutorial_btn.pressed.connect(open_tutorial)
	if tutorial_close_btn:
		tutorial_close_btn.pressed.connect(close_tutorial)
	if tutorial_prev_btn:
		tutorial_prev_btn.pressed.connect(_on_tutorial_prev_pressed)
	if tutorial_next_btn:
		tutorial_next_btn.pressed.connect(_on_tutorial_next_pressed)

	if quests_list:
		quests_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if quests_scroll:
		quests_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		quests_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		quests_scroll.gui_input.connect(_on_quests_scroll_gui_input)

	_create_dynamic_ui()
	_wire_menu_sfx()

	if distance_label:
		distance_label.visible = true
	if final_dist_label:
		final_dist_label.visible = false

	_apply_catchy_theme()
	select_mode(1) # Default to Runner mode
	refresh_accessibility_visuals()
	_apply_safe_area_layout()
	if get_viewport() and not get_viewport().size_changed.is_connected(_apply_safe_area_layout):
		get_viewport().size_changed.connect(_apply_safe_area_layout)

	pause_menu.visible = false
	game_over_menu.visible = false
	start_menu.visible = false
	skin_shop_dialog.visible = false
	challenges_dialog.visible = false
	if settings_dialog: settings_dialog.visible = false
	if credits_dialog: credits_dialog.visible = false
	if tutorial_dialog: tutorial_dialog.visible = false
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
	if skill_button:
		_style_arcade_button(skill_button, Color(0.36, 0.14, 0.64, 0.82), Color(0.76, 0.48, 1.0, 0.95), 10)
	if flight_up_btn:
		_style_arcade_button(flight_up_btn, Color(0.08, 0.44, 0.68, 0.75), Color(0.42, 0.92, 1.0, 0.95), 10)
	if flight_down_btn:
		_style_arcade_button(flight_down_btn, Color(0.52, 0.28, 0.08, 0.75), Color(1.0, 0.72, 0.28, 0.95), 10)

	# 7. Settings, Credits & Tutorial Dialog Styling
	for dlg in [settings_dialog, credits_dialog, tutorial_dialog]:
		if dlg:
			var p = dlg.get_node_or_null("Panel")
			if p is PanelContainer:
				p.add_theme_stylebox_override("panel", panel_cyan)
	for btn in [start_settings_btn, pause_settings_btn, start_tutorial_btn, start_credits_btn]:
		if btn:
			_style_arcade_button(btn, Color(0.14, 0.21, 0.34), Color(0.36, 0.56, 0.82), 9)
	for btn in [settings_close_btn, credits_close_btn, tutorial_close_btn]:
		if btn:
			_style_arcade_button(btn, Color(0.75, 0.18, 0.24), Color(0.98, 0.48, 0.52), 9)
	for btn in [tutorial_prev_btn, tutorial_next_btn]:
		if btn:
			_style_arcade_button(btn, Color(0.12, 0.42, 0.68), Color(0.45, 0.85, 1.0), 10)
	for btn in [sound_toggle_btn, vibration_toggle_btn, motion_toggle_btn, contrast_toggle_btn, handed_toggle_btn, auto_hold_toggle_btn, settings_music_btn, settings_sfx_btn, settings_dev_btn]:
		if btn:
			_style_arcade_button(btn, Color(0.12, 0.19, 0.31), Color(0.35, 0.56, 0.8), 9)

func bind_services(p_save: SaveService, p_challenge: ChallengeService) -> void:
	save_service = p_save
	challenge_service = p_challenge
	if challenge_service and not challenge_service.challenge_unlocked.is_connected(_on_challenge_unlocked):
		challenge_service.challenge_unlocked.connect(_on_challenge_unlocked)
	_update_mascot_icons()
	refresh_settings_ui()
	refresh_accessibility_visuals()
	apply_control_layout(_is_left_handed())

func _is_left_handed() -> bool:
	if save_service:
		return bool(save_service.get_setting("left_handed", false))
	return false

func _wire_menu_sfx() -> void:
	var btns: Array = [
		play_button, mode_casual_btn, mode_runner_btn, mode_freestyle_btn, mode_practice_btn,
		start_shop_btn, game_over_shop_btn, shop_close_btn,
		start_quests_btn, game_over_quests_btn, quests_close_btn, quests_bottom_close_btn,
		start_settings_btn, pause_settings_btn, settings_close_btn,
		start_tutorial_btn, tutorial_close_btn, tutorial_prev_btn, tutorial_next_btn,
		start_credits_btn, credits_close_btn,
		pause_button, resume_button, restart_button, pause_menu_button,
		retry_button, game_over_menu_button
	]
	for b in btns:
		if b is Button and not b.pressed.is_connected(_emit_ui_interacted):
			b.pressed.connect(_emit_ui_interacted)

func _emit_ui_interacted() -> void:
	ui_interacted.emit()

func _create_dynamic_ui() -> void:
	var top_bar = score_label.get_parent() if score_label else null
	if top_bar and combo_panel == null:
		combo_panel = PanelContainer.new()
		combo_panel.name = "ComboPanel"
		combo_panel.visible = false
		combo_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		combo_panel.anchor_left = 1.0
		combo_panel.anchor_right = 1.0
		combo_panel.offset_left = -84.0
		combo_panel.offset_top = 30.0
		combo_panel.offset_right = -8.0
		combo_panel.offset_bottom = 52.0
		combo_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		combo_panel.add_theme_stylebox_override("panel", _make_box(Color(0.24, 0.08, 0.02, 0.92), Color(1.0, 0.72, 0.18, 1.0), 1, 3, 4, 2, 2, 2))
		top_bar.add_child(combo_panel)

		var cvbox = VBoxContainer.new()
		cvbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cvbox.add_theme_constant_override("separation", 1)
		combo_panel.add_child(cvbox)

		combo_label = Label.new()
		combo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		combo_label.text = "⚡ x2"
		combo_label.add_theme_font_size_override("font_size", 8)
		combo_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.35))
		combo_label.add_theme_constant_override("outline_size", 2)
		combo_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		cvbox.add_child(combo_label)

		combo_bar = ColorRect.new()
		combo_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		combo_bar.custom_minimum_size = Vector2(0, 2)
		combo_bar.color = Color(0.1, 0.08, 0.14, 0.85)
		cvbox.add_child(combo_bar)

		combo_bar_fill = ColorRect.new()
		combo_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		combo_bar_fill.color = Color(1.0, 0.78, 0.18)
		combo_bar_fill.anchor_right = 1.0
		combo_bar_fill.anchor_bottom = 1.0
		combo_bar.add_child(combo_bar_fill)

	if settings_dialog:
		var s_list = settings_dialog.get_node_or_null("Panel/VBox/SettingsScroll/SettingsList")
		if s_list == null:
			s_list = settings_dialog.get_node_or_null("Panel/VBox")
		if s_list is VBoxContainer:
			s_list.add_theme_constant_override("separation", 4)
			if settings_music_btn == null:
				settings_music_btn = Button.new()
				settings_music_btn.name = "MusicVolBtn"
				settings_music_btn.text = "🎵 MUSIC VOL: 75%"
				settings_music_btn.pressed.connect(_on_music_vol_pressed)
				s_list.add_child(settings_music_btn)
			if settings_sfx_btn == null:
				settings_sfx_btn = Button.new()
				settings_sfx_btn.name = "SfxVolBtn"
				settings_sfx_btn.text = "🔊 SFX VOL: 100%"
				settings_sfx_btn.pressed.connect(_on_sfx_vol_pressed)
				s_list.add_child(settings_sfx_btn)
			if settings_dev_btn == null:
				settings_dev_btn = Button.new()
				settings_dev_btn.name = "DevOverlayBtn"
				settings_dev_btn.text = "🛠 DEV STATS: OFF"
				settings_dev_btn.pressed.connect(_on_dev_overlay_pressed)
				s_list.add_child(settings_dev_btn)
		if settings_scroll:
			settings_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
			settings_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

	if challenges_dialog and quests_scroll:
		var q_vbox = quests_scroll.get_parent()
		if q_vbox is VBoxContainer and career_summary_label == null:
			career_summary_label = Label.new()
			career_summary_label.name = "CareerSummaryLabel"
			career_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			career_summary_label.add_theme_font_size_override("font_size", 8)
			career_summary_label.add_theme_color_override("font_color", Color(0.65, 0.92, 1.0))
			career_summary_label.add_theme_constant_override("outline_size", 2)
			career_summary_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
			q_vbox.add_child(career_summary_label)
			q_vbox.move_child(career_summary_label, quests_scroll.get_index())

	# Stagger vertical bands cleanly so toasts, flight bar, and DevOverlay never collide
	if flight_timer_bar:
		flight_timer_bar.offset_left = -105.0
		flight_timer_bar.offset_top = 58.0
		flight_timer_bar.offset_right = 105.0
		flight_timer_bar.offset_bottom = 80.0
	if challenge_toast:
		challenge_toast.offset_top = 84.0
		challenge_toast.offset_bottom = 106.0
	if skill_toast:
		skill_toast.offset_top = 84.0
		skill_toast.offset_bottom = 106.0
	if dev_overlay:
		dev_overlay.offset_left = 6.0
		dev_overlay.offset_top = 110.0
		dev_overlay.offset_right = 210.0
		dev_overlay.offset_bottom = 132.0

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
	if mode_practice_btn:
		_style_arcade_button(mode_practice_btn, active_bg if mode == 3 else idle_bg, active_border if mode == 3 else idle_border, 9)

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
		3: # Practice
			mode_desc_label.text = "🛡 Chill Practice • Shielded Start • Forgiving Timing"
			slide_button.visible = true
			slide_button.offset_left = 14.0
			slide_button.offset_right = 96.0
			slide_button.text = "▼ SLIDE"
			steer_left_btn.visible = false
			steer_right_btn.visible = false
	apply_control_layout(_is_left_handed())

func show_start_menu(best_score: int, points: int = 0) -> void:
	start_best_label.text = "🏆 BEST: %05d" % best_score
	start_points_label.text = "💎 PTS: %05d" % points
	points_label.text = "💎 PTS: %05d" % points
	_update_mascot_icons()
	start_menu.visible = true
	touch_controls.visible = false
	skin_shop_dialog.visible = false
	challenges_dialog.visible = false
	if settings_dialog: settings_dialog.visible = false
	if credits_dialog: credits_dialog.visible = false
	if tutorial_dialog: tutorial_dialog.visible = false

func hide_start_menu() -> void:
	start_menu.visible = false
	skin_shop_dialog.visible = false
	challenges_dialog.visible = false
	if settings_dialog: settings_dialog.visible = false
	if credits_dialog: credits_dialog.visible = false
	if tutorial_dialog: tutorial_dialog.visible = false
	touch_controls.visible = true

func update_hud(score: int, distance_m: float = 0.0, best_score: int = 0, points: int = 0) -> void:
	score_label.text = "SCORE: %05d" % score
	best_label.text = "🏆 HI: %05d" % best_score
	points_label.text = "💎 PTS: %05d" % points
	if distance_label:
		distance_label.text = "📏 %dm" % int(distance_m)
		distance_label.visible = true

func update_combo(count: int, mult: int, fever: bool, progress: float) -> void:
	if combo_panel == null or combo_label == null:
		return
	if count <= 0 and not fever:
		combo_panel.visible = false
		return
	combo_panel.visible = true
	if fever:
		combo_label.text = "🔥 FEVER x%d" % mult
		combo_label.add_theme_color_override("font_color", Color(1.0, 0.36, 0.22))
		combo_panel.add_theme_stylebox_override("panel", _make_box(Color(0.3, 0.05, 0.08, 0.94), Color(1.0, 0.32, 0.25, 1.0), 1, 3, 4, 2, 2, 2))
		if combo_bar_fill:
			combo_bar_fill.color = Color(1.0, 0.35, 0.25)
			combo_bar_fill.anchor_right = 1.0
	else:
		combo_label.text = "⚡ %d HIT x%d" % [count, mult] if mult > 1 else "⚡ %d HIT" % count
		combo_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.35))
		combo_panel.add_theme_stylebox_override("panel", _make_box(Color(0.18, 0.09, 0.03, 0.9), Color(1.0, 0.72, 0.18, 1.0), 1, 3, 4, 2, 2, 2))
		if combo_bar_fill:
			combo_bar_fill.color = Color(1.0, 0.82, 0.2)
			combo_bar_fill.anchor_right = clampf(progress, 0.05, 1.0)

func update_gems(count: int) -> void:
	if gems_label:
		gems_label.text = "💎 %d" % count

func update_skill_slot(info: Dictionary, cd: float = 0.0, dur: float = 0.0, charges: int = 1) -> void:
	var has_skill = info.get("name", "None") != "None"
	var is_passive = has_skill and float(info.get("duration", 0.0)) < 0.0
	_has_active_skill_button = has_skill and not is_passive
	if skill_button:
		skill_button.visible = _has_active_skill_button and (flight_controls == null or not flight_controls.visible)
	if skill_slot:
		skill_slot.visible = has_skill
		if has_skill:
			var icon_p = info.get("icon", "")
			if skill_icon and icon_p != "" and ResourceLoader.exists(icon_p):
				skill_icon.texture = load(icon_p)
			if is_passive and skill_label:
				skill_label.text = "SHIELD"
				skill_label.add_theme_color_override("font_color", Color(0.55, 0.95, 1.0))
			else:
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
		if _skill_toast_tween and _skill_toast_tween.is_valid():
			_skill_toast_tween.kill()
		skill_toast_label.text = message
		skill_toast.visible = true
		skill_toast.modulate.a = 0.0
		_skill_toast_tween = create_tween()
		if _skill_toast_tween:
			_skill_toast_tween.tween_property(skill_toast, "modulate:a", 1.0, 0.14)
			_skill_toast_tween.tween_interval(1.6)
			_skill_toast_tween.tween_property(skill_toast, "modulate:a", 0.0, 0.3)
			_skill_toast_tween.tween_callback(func(): skill_toast.visible = false)

# --- Session 6 Flight HUD ---

func show_flight_hud(f_type: int, total_duration: float) -> void:
	clear_touch_inputs()
	if flight_controls:
		flight_controls.visible = true
	if jump_button:
		jump_button.visible = false
	if skill_button:
		skill_button.visible = false

	if flight_timer_bar:
		flight_timer_bar.visible = true
	if flight_icon_label:
		flight_icon_label.text = "✈ WINGS" if f_type == 1 else "🚀 ROCKET"
	if flight_warning_label:
		flight_warning_label.visible = false
	update_flight_timer(total_duration, total_duration)

func update_flight_timer(remaining: float, _total: float) -> void:
	if flight_timer_label:
		flight_timer_label.text = "FLIGHT: %.1fs" % maxf(remaining, 0.0)
	if remaining <= 2.0 and remaining > 0.0:
		if flight_warning_label:
			flight_warning_label.visible = true
			var flash = int(remaining * 6.0) % 2 == 0
			flight_warning_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2) if flash else Color(1.0, 0.9, 0.2))
	else:
		if flight_warning_label:
			flight_warning_label.visible = false

func hide_flight_hud() -> void:
	if flight_controls:
		flight_controls.visible = false
	if jump_button:
		jump_button.visible = true
	if skill_button:
		skill_button.visible = _has_active_skill_button
	if flight_timer_bar:
		flight_timer_bar.visible = false

# --- Session 7 World Transitions HUD ---

func update_world_name(w_name: String) -> void:
	if world_label:
		world_label.text = "🌍 " + w_name.to_upper()

func update_seed(seed_val: int) -> void:
	if seed_label:
		seed_label.text = "🎲 %d" % seed_val

func show_world_transition_card(w_name: String, intro: String) -> void:
	if world_card and world_title_label and world_intro_label:
		if _world_toast_tween and _world_toast_tween.is_valid():
			_world_toast_tween.kill()
		world_title_label.text = "ENTERING %s" % w_name.to_upper()
		world_intro_label.text = intro
		world_card.visible = true
		world_card.modulate.a = 0.0
		_world_toast_tween = create_tween()
		if _world_toast_tween:
			_world_toast_tween.tween_property(world_card, "modulate:a", 1.0, 0.25)
			_world_toast_tween.tween_interval(1.9)
			_world_toast_tween.tween_property(world_card, "modulate:a", 0.0, 0.45)
			_world_toast_tween.tween_callback(func(): world_card.visible = false)

func show_game_over(cause: String, score: int, distance_m: float = 0.0, best_score: int = 0, is_new_best: bool = false, run_pts: int = 0, total_pts: int = 0, max_combo: int = 0, next_biome_hint: String = "") -> void:
	cause_label.text = cause
	final_score_label.text = "FINAL SCORE: %05d" % score
	best_score_label.text = "🏆 BEST: %05d" % best_score
	run_points_label.text = "✨ +%d PTS EARNED ✨" % run_pts
	total_points_label.text = "💎 TOTAL PTS: %d" % total_pts
	new_best_label.visible = is_new_best
	if is_new_best:
		new_best_label.text = "★ NEW HIGH SCORE! ★"
	if final_dist_label:
		var parts: Array[String] = ["📏 %dm" % int(distance_m)]
		if max_combo >= 2:
			parts.append("🔥 MAX x%d" % max_combo)
		if next_biome_hint != "":
			parts.append(next_biome_hint)
		final_dist_label.text = "  •  ".join(parts)
		final_dist_label.visible = true
	game_over_menu.visible = true
	touch_controls.visible = false
	skin_shop_dialog.visible = false
	challenges_dialog.visible = false
	if settings_dialog: settings_dialog.visible = false
	if credits_dialog: credits_dialog.visible = false
	if tutorial_dialog: tutorial_dialog.visible = false
	retry_debounce = false

func hide_game_over() -> void:
	game_over_menu.visible = false
	skin_shop_dialog.visible = false
	challenges_dialog.visible = false
	if settings_dialog: settings_dialog.visible = false
	if credits_dialog: credits_dialog.visible = false
	if tutorial_dialog: tutorial_dialog.visible = false
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

func _on_buy_clicked(skin_id: String, _price: int) -> void:
	ui_interacted.emit()
	if save_service and save_service.purchase_skin(skin_id):
		skin_selected.emit(skin_id)
		refresh_skin_shop()

func _on_equip_clicked(skin_id: String) -> void:
	ui_interacted.emit()
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

	if career_summary_label:
		var runs := save_service.get_lifetime_stat("total_runs")
		var max_dist := save_service.get_lifetime_stat("max_distance")
		var near_misses := save_service.get_lifetime_stat("total_near_misses")
		var mastery_ids := ["mastery_combo_10", "mastery_near_miss_5", "mastery_destroy_5", "mastery_world_4"]
		var mastery_done := 0
		for mid in mastery_ids:
			if save_service.is_mastery_completed(mid):
				mastery_done += 1
		career_summary_label.text = "📊 RUNS: %d  |  MAX DIST: %dm  |  CLOSE CALLS: %d  |  MASTERY: %d/4" % [runs, max_dist, near_misses, mastery_done]

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
	if _challenge_toast_tween and _challenge_toast_tween.is_valid():
		_challenge_toast_tween.kill()
	toast_label.text = "🏆 QUEST COMPLETE: %s (+%d PTS)!" % [title, reward]
	challenge_toast.visible = true
	challenge_toast.modulate.a = 0.0

	_challenge_toast_tween = create_tween()
	if _challenge_toast_tween:
		_challenge_toast_tween.tween_property(challenge_toast, "modulate:a", 1.0, 0.25)
		_challenge_toast_tween.tween_interval(2.5)
		_challenge_toast_tween.tween_property(challenge_toast, "modulate:a", 0.0, 0.45)
		_challenge_toast_tween.tween_callback(func(): challenge_toast.visible = false)

# ==========================================
# Input & Touch Handling
# ==========================================
func _unhandled_input(event: InputEvent) -> void:
	var any_subdialog := challenges_dialog.visible or skin_shop_dialog.visible
	if settings_dialog and settings_dialog.visible:
		any_subdialog = true
	if credits_dialog and credits_dialog.visible:
		any_subdialog = true
	if tutorial_dialog and tutorial_dialog.visible:
		any_subdialog = true

	if any_subdialog or start_menu.visible or pause_menu.visible or game_over_menu.visible:
		if game_over_menu.visible and not any_subdialog:
			var r_pressed: bool = event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R
			if event.is_action_pressed("jump") or r_pressed:
				_on_retry_button_pressed()
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			_handle_touch_down(event.index, event.position)
		else:
			_handle_touch_up(event.index, event.position)
	elif event is InputEventScreenDrag:
		_handle_touch_drag(event.index, event.position)

func clear_touch_inputs() -> void:
	jump_touch_index = -1
	slide_touch_index = -1
	touch_start_positions.clear()
	jump_requested.emit(false)
	slide_requested.emit(false)
	steer_requested.emit(0.0)
	flight_up_requested.emit(false)
	flight_down_requested.emit(false)

func _handle_touch_down(index: int, pos: Vector2) -> void:
	touch_start_positions[index] = pos

	var vp_width = get_viewport().get_visible_rect().size.x
	var split_x = vp_width * 0.5

	if pos.y < 34.0:
		return

	if flight_controls and flight_controls.visible:
		return

	if current_mode == 0:
		if jump_touch_index == -1:
			jump_touch_index = index
			jump_requested.emit(true)
		return

	var jump_side: bool = (pos.x < split_x) if _is_left_handed() else (pos.x >= split_x)
	if jump_side:
		if jump_touch_index == -1:
			jump_touch_index = index
			jump_requested.emit(true)
	else:
		if current_mode in [1, 2, 3]:
			if slide_touch_index == -1:
				slide_touch_index = index
				slide_requested.emit(true)

func _handle_touch_drag(index: int, pos: Vector2) -> void:
	if current_mode in [1, 2, 3] and touch_start_positions.has(index):
		var start_pos: Vector2 = touch_start_positions[index]
		var delta := pos - start_pos
		if delta.y > SWIPE_THRESHOLD:
			if index == jump_touch_index:
				jump_touch_index = -1
				jump_requested.emit(false)
			slide_touch_index = index
			touch_start_positions[index] = pos
			slide_requested.emit(true)

func _get_safe_area_insets() -> Dictionary:
	var result := {"left": 0.0, "top": 0.0, "right": 0.0, "bottom": 0.0}
	if DisplayServer.get_name() == "headless":
		return result
	var win_size: Vector2i = DisplayServer.window_get_size()
	var vp := get_viewport()
	if win_size.x <= 0 or win_size.y <= 0 or vp == null:
		return result
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	if safe.size.x <= 0 or safe.size.y <= 0:
		return result
	var vp_size: Vector2 = vp.get_visible_rect().size
	var scale_x: float = vp_size.x / float(win_size.x)
	var scale_y: float = vp_size.y / float(win_size.y)
	result["left"] = clampf(float(safe.position.x) * scale_x, 0.0, 28.0)
	result["top"] = clampf(float(safe.position.y) * scale_y, 0.0, 24.0)
	result["right"] = clampf(float(win_size.x - safe.end.x) * scale_x, 0.0, 28.0)
	result["bottom"] = clampf(float(win_size.y - safe.end.y) * scale_y, 0.0, 24.0)
	return result

func _apply_safe_area_layout(override_insets: Dictionary = {}) -> void:
	var insets: Dictionary = override_insets if not override_insets.is_empty() else _get_safe_area_insets()
	var s_left: float = float(insets.get("left", 0.0))
	var s_top: float = float(insets.get("top", 0.0))
	var s_right: float = float(insets.get("right", 0.0))
	var s_bottom: float = float(insets.get("bottom", 0.0))
	if top_bar:
		top_bar.offset_left = s_left
		top_bar.offset_top = s_top
		top_bar.offset_right = -s_right
		top_bar.offset_bottom = 58.0 + s_top
		var vp := get_viewport()
		var vp_w: float = vp.get_visible_rect().size.x if vp else 480.0
		var avail_w: float = maxf(320.0, vp_w - s_left - s_right)
		_relayout_top_bar(avail_w)
	if touch_controls:
		touch_controls.offset_left = s_left
		touch_controls.offset_top = s_top
		touch_controls.offset_right = -s_right
		touch_controls.offset_bottom = -s_bottom
	if combo_panel:
		# combo_panel is parented under top_bar, which already carries safe-area offsets
		combo_panel.offset_left = -84.0
		combo_panel.offset_right = -8.0
		combo_panel.offset_top = 30.0
		combo_panel.offset_bottom = 52.0
	if flight_timer_bar:
		flight_timer_bar.offset_top = 58.0 + s_top
		flight_timer_bar.offset_bottom = 80.0 + s_top
	if skill_toast:
		skill_toast.offset_top = 84.0 + s_top
		skill_toast.offset_bottom = 106.0 + s_top

func _set_left_rect(ctrl: Control, x0: float, x1: float, y0: float, y1: float) -> void:
	if ctrl == null:
		return
	ctrl.anchor_left = 0.0
	ctrl.anchor_right = 0.0
	if ctrl is Label:
		(ctrl as Label).clip_text = true
	ctrl.offset_left = x0
	ctrl.offset_right = x1
	ctrl.offset_top = y0
	ctrl.offset_bottom = y1
	ctrl.position = Vector2(x0, y0)
	ctrl.size = Vector2(maxf(8.0, x1 - x0), maxf(8.0, y1 - y0))

func _relayout_top_bar(avail_w: float) -> void:
	# Row 1: ScoreLabel, BestLabel, PointsLabel, GemsLabel, PauseButton
	_set_left_rect(pause_button, avail_w - 82.0, avail_w - 8.0, 5.0, 27.0)
	_set_left_rect(gems_label, avail_w - 134.0, avail_w - 86.0, 5.0, 27.0)
	var b1: float = maxf(180.0, avail_w - 144.0)
	_set_left_rect(score_label, 6.0, 6.0 + b1 * 0.34, 5.0, 27.0)
	_set_left_rect(best_label, 6.0 + b1 * 0.35, 6.0 + b1 * 0.67, 5.0, 27.0)
	_set_left_rect(points_label, 6.0 + b1 * 0.68, 6.0 + b1 * 0.99, 5.0, 27.0)

	# Row 2: SkillSlot, WorldLabel, DistanceLabel, SeedLabel (stays cleanly left of ComboPanel)
	var b2: float = maxf(200.0, avail_w - 92.0)
	var skill_end: float = 6.0 + minf(88.0, b2 * 0.25)
	_set_left_rect(skill_slot, 6.0, skill_end, 31.0, 55.0)
	var world_start: float = skill_end + 4.0
	var world_end: float = world_start + minf(122.0, b2 * 0.34)
	_set_left_rect(world_label, world_start, world_end, 32.0, 54.0)
	var dist_start: float = world_end + 4.0
	var dist_end: float = dist_start + minf(76.0, b2 * 0.20)
	_set_left_rect(distance_label, dist_start, dist_end, 32.0, 54.0)
	var seed_start: float = dist_end + 4.0
	var seed_end: float = maxf(seed_start + 36.0, b2)
	_set_left_rect(seed_label, seed_start, minf(seed_start + 74.0, seed_end), 32.0, 54.0)

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

# ==========================================
# Session 9: Settings, Accessibility, Credits & Tutorial
# ==========================================

const TUTORIAL_STEPS: Array[Dictionary] = [
	{
		"title": "🎓 STEP 1/5: RUNNING",
		"desc": "You auto-run forward across ancient biomes. Focus your reflexes on upcoming terrain and speed surges!"
	},
	{
		"title": "🎓 STEP 2/5: JUMPING",
		"desc": "Tap to short-hop over low hurdles. Hold jump to vault higher over elevated platforms!"
	},
	{
		"title": "🎓 STEP 3/5: SLIDING & DIVING",
		"desc": "Tap or swipe down on the left to slide under stone arches and avoid flying hazards. In mid-air, swipe down to dive!"
	},
	{
		"title": "🎓 STEP 4/5: SKILLS & RELICS",
		"desc": "Collect glowing orbs to acquire Bone Blade, Boomerang, Stone Shield, Magnet Relic, or Flight!"
	},
	{
		"title": "🎓 STEP 5/5: POWERS & FLIGHT",
		"desc": "Tap the large SKILL button on the right to unleash your active power. Use flight controls to glide through the skies!"
	}
]

func open_settings(from_menu: String = "start") -> void:
	prev_menu_before_settings = from_menu
	if settings_dialog:
		settings_dialog.visible = true
		refresh_settings_ui()

func close_settings() -> void:
	if settings_dialog:
		settings_dialog.visible = false

func refresh_settings_ui() -> void:
	if save_service == null:
		return
	var sound = save_service.get_setting("sound_enabled", true)
	var vib = save_service.get_setting("vibration_enabled", true)
	var motion = save_service.get_setting("reduce_motion", false)
	var contrast = save_service.get_setting("high_contrast", false)
	var handed = save_service.get_setting("left_handed", false)
	var auto_jump = save_service.get_setting("auto_hold_jump", false)
	var music_vol = float(save_service.get_setting("volume_music", 0.75))
	var sfx_vol = float(save_service.get_setting("volume_sfx", 1.0))
	var dev_on = bool(save_service.get_setting("dev_overlay", false))

	if sound_toggle_btn:
		sound_toggle_btn.text = "🔊 SOUND EFFECTS: " + ("ON" if sound else "OFF")
	if vibration_toggle_btn:
		vibration_toggle_btn.text = "📳 HAPTIC VIBRATION: " + ("ON" if vib else "OFF")
	if motion_toggle_btn:
		motion_toggle_btn.text = "🌀 REDUCE MOTION: " + ("ON" if motion else "OFF")
	if contrast_toggle_btn:
		contrast_toggle_btn.text = "👁 HIGH CONTRAST: " + ("ON" if contrast else "OFF")
	if handed_toggle_btn:
		handed_toggle_btn.text = "🖐 CONTROL LAYOUT: " + ("LEFT-HANDED" if handed else "RIGHT-HANDED")
	if auto_hold_toggle_btn:
		auto_hold_toggle_btn.text = "🦘 AUTO-HOLD JUMP: " + ("ON" if auto_jump else "OFF")
	if settings_music_btn:
		settings_music_btn.text = "🎵 MUSIC VOL: %d%%" % int(round(music_vol * 100.0))
	if settings_sfx_btn:
		settings_sfx_btn.text = "🔊 SFX VOL: %d%%" % int(round(sfx_vol * 100.0))
	if settings_dev_btn:
		settings_dev_btn.text = "🛠 DEV STATS: " + ("ON" if dev_on else "OFF")

func _on_sound_toggle_pressed() -> void:
	if save_service:
		var cur = save_service.get_setting("sound_enabled", true)
		save_service.set_setting("sound_enabled", not cur)
		refresh_settings_ui()
		settings_changed.emit()
		ui_interacted.emit()

func _on_vibration_toggle_pressed() -> void:
	if save_service:
		var cur = save_service.get_setting("vibration_enabled", true)
		save_service.set_setting("vibration_enabled", not cur)
		refresh_settings_ui()
		settings_changed.emit()
		ui_interacted.emit()

func _on_motion_toggle_pressed() -> void:
	if save_service:
		var cur = save_service.get_setting("reduce_motion", false)
		save_service.set_setting("reduce_motion", not cur)
		refresh_settings_ui()
		settings_changed.emit()
		ui_interacted.emit()

func _on_contrast_toggle_pressed() -> void:
	if save_service:
		var cur = save_service.get_setting("high_contrast", false)
		save_service.set_setting("high_contrast", not cur)
		refresh_settings_ui()
		refresh_accessibility_visuals()
		settings_changed.emit()
		ui_interacted.emit()

func _on_handed_toggle_pressed() -> void:
	if save_service:
		var cur = save_service.get_setting("left_handed", false)
		save_service.set_setting("left_handed", not cur)
		refresh_settings_ui()
		apply_control_layout(not cur)
		settings_changed.emit()
		ui_interacted.emit()

func _on_auto_hold_toggle_pressed() -> void:
	if save_service:
		var cur = save_service.get_setting("auto_hold_jump", false)
		save_service.set_setting("auto_hold_jump", not cur)
		refresh_settings_ui()
		settings_changed.emit()
		ui_interacted.emit()

func _cycle_volume(val: float) -> float:
	var steps: Array[float] = [1.0, 0.75, 0.5, 0.25, 0.0]
	for i in range(steps.size()):
		if absf(val - steps[i]) < 0.08:
			return steps[(i + 1) % steps.size()]
	return 0.75

func _on_music_vol_pressed() -> void:
	if save_service:
		var cur := float(save_service.get_setting("volume_music", 0.75))
		save_service.set_setting("volume_music", _cycle_volume(cur))
		refresh_settings_ui()
		settings_changed.emit()
		ui_interacted.emit()

func _on_sfx_vol_pressed() -> void:
	if save_service:
		var cur := float(save_service.get_setting("volume_sfx", 1.0))
		save_service.set_setting("volume_sfx", _cycle_volume(cur))
		refresh_settings_ui()
		settings_changed.emit()
		ui_interacted.emit()

func _on_dev_overlay_pressed() -> void:
	if save_service:
		var cur := bool(save_service.get_setting("dev_overlay", false))
		save_service.set_setting("dev_overlay", not cur)
		refresh_settings_ui()
		refresh_accessibility_visuals()
		settings_changed.emit()
		ui_interacted.emit()

func refresh_accessibility_visuals() -> void:
	var dev_on := false
	var hc := false
	if save_service:
		dev_on = bool(save_service.get_setting("dev_overlay", false))
		hc = bool(save_service.get_setting("high_contrast", false))
	if seed_label:
		seed_label.visible = dev_on
	if dev_overlay:
		dev_overlay.visible = dev_on
	if hc == _high_contrast_active:
		return
	_high_contrast_active = hc
	if hc:
		var hc_panel = _make_box(Color(0.0, 0.0, 0.0, 0.98), Color(1.0, 1.0, 0.2, 1.0), 2, 4, 10, 12, 8, 8)
		for p in [start_panel, pause_panel, game_over_panel, shop_panel, quests_panel]:
			if p:
				p.add_theme_stylebox_override("panel", hc_panel)
		_style_arcade_button(jump_button, Color(0.0, 0.0, 0.0, 0.92), Color(0.25, 1.0, 1.0, 1.0), 11, Color(1.0, 1.0, 1.0))
		_style_arcade_button(slide_button, Color(0.0, 0.0, 0.0, 0.92), Color(1.0, 0.92, 0.15, 1.0), 11, Color(1.0, 1.0, 0.35))
		if skill_button:
			_style_arcade_button(skill_button, Color(0.0, 0.0, 0.0, 0.92), Color(1.0, 0.45, 1.0, 1.0), 10, Color(1.0, 1.0, 1.0))
	else:
		_apply_catchy_theme()

func _is_mobile_touch_device() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")

func _update_controls_hint(is_left_handed: bool) -> void:
	if retry_button:
		retry_button.text = "▶ PLAY AGAIN" if _is_mobile_touch_device() else "▶ PLAY AGAIN (R)"
	if controls_hint == null:
		return
	if not _is_mobile_touch_device():
		match current_mode:
			0:
				controls_hint.text = "SPACE / W = JUMP  •  NO SLIDE IN SPICY  •  E = SKILL"
			2:
				controls_hint.text = "A / D = STEER  •  SPACE = JUMP  •  S = DUCK  •  E = SKILL"
			_:
				controls_hint.text = "SPACE / W = JUMP  •  S / ↓ = SLIDE / DIVE  •  E = SKILL"
		return
	match current_mode:
		0:
			controls_hint.text = "TAP %s / SCREEN = JUMP  •  NO SLIDE" % ("LEFT" if is_left_handed else "RIGHT")
		2:
			controls_hint.text = "STEER ◀ ▶  •  JUMP ▲  •  DUCK ▼"
		_:
			if is_left_handed:
				controls_hint.text = "TAP LEFT = JUMP  •  TAP RIGHT = SLIDE / DIVE"
			else:
				controls_hint.text = "TAP RIGHT = JUMP  •  TAP LEFT = SLIDE / DIVE"

func apply_control_layout(is_left_handed: bool) -> void:
	_update_controls_hint(is_left_handed)
	if not touch_controls:
		return
	if is_left_handed:
		jump_button.anchor_left = 0.0
		jump_button.anchor_right = 0.0
		jump_button.offset_left = 14.0
		jump_button.offset_right = 160.0

		if skill_button:
			skill_button.anchor_left = 0.0
			skill_button.anchor_right = 0.0
			skill_button.offset_left = 168.0
			skill_button.offset_right = 232.0
			if current_mode == 2:
				skill_button.offset_top = -104.0
				skill_button.offset_bottom = -62.0
			else:
				skill_button.offset_top = -54.0
				skill_button.offset_bottom = -12.0

		if flight_controls:
			flight_controls.anchor_left = 0.0
			flight_controls.anchor_right = 0.0
			flight_controls.offset_left = 14.0
			flight_controls.offset_right = 160.0

		slide_button.anchor_left = 1.0
		slide_button.anchor_right = 1.0
		if current_mode == 2:
			slide_button.offset_left = -212.0
			slide_button.offset_right = -144.0
		else:
			slide_button.offset_left = -96.0
			slide_button.offset_right = -14.0

		if steer_left_btn and steer_right_btn:
			steer_left_btn.anchor_left = 1.0
			steer_left_btn.anchor_right = 1.0
			steer_left_btn.offset_left = -136.0
			steer_left_btn.offset_right = -78.0
			steer_right_btn.anchor_left = 1.0
			steer_right_btn.anchor_right = 1.0
			steer_right_btn.offset_left = -72.0
			steer_right_btn.offset_right = -14.0
	else:
		jump_button.anchor_left = 1.0
		jump_button.anchor_right = 1.0
		jump_button.offset_left = -160.0
		jump_button.offset_right = -14.0

		if skill_button:
			skill_button.anchor_left = 1.0
			skill_button.anchor_right = 1.0
			skill_button.offset_left = -232.0
			skill_button.offset_right = -168.0
			if current_mode == 2:
				skill_button.offset_top = -104.0
				skill_button.offset_bottom = -62.0
			else:
				skill_button.offset_top = -54.0
				skill_button.offset_bottom = -12.0

		if flight_controls:
			flight_controls.anchor_left = 1.0
			flight_controls.anchor_right = 1.0
			flight_controls.offset_left = -160.0
			flight_controls.offset_right = -14.0

		slide_button.anchor_left = 0.0
		slide_button.anchor_right = 0.0
		if current_mode == 2:
			slide_button.offset_left = 144.0
			slide_button.offset_right = 212.0
		else:
			slide_button.offset_left = 14.0
			slide_button.offset_right = 96.0

		if steer_left_btn and steer_right_btn:
			steer_left_btn.anchor_left = 0.0
			steer_left_btn.anchor_right = 0.0
			steer_left_btn.offset_left = 14.0
			steer_left_btn.offset_right = 72.0
			steer_right_btn.anchor_left = 0.0
			steer_right_btn.anchor_right = 0.0
			steer_right_btn.offset_left = 78.0
			steer_right_btn.offset_right = 136.0

func open_credits() -> void:
	if credits_dialog:
		credits_dialog.visible = true

func close_credits() -> void:
	if credits_dialog:
		credits_dialog.visible = false

func open_tutorial() -> void:
	tutorial_step = 0
	if tutorial_dialog:
		tutorial_dialog.visible = true
		_display_tutorial_step(0)

func close_tutorial() -> void:
	if tutorial_dialog:
		tutorial_dialog.visible = false

func _display_tutorial_step(step: int) -> void:
	tutorial_step = clampi(step, 0, TUTORIAL_STEPS.size() - 1)
	var info = TUTORIAL_STEPS[tutorial_step]
	if tutorial_step_label:
		tutorial_step_label.text = info["title"]
	var is_lh := _is_left_handed()
	match step:
		2:
			var side := "right" if is_lh else "left"
			tutorial_desc_label.text = "Tap or swipe down on the %s to slide under stone arches and dodge flying hazards. In mid-air, swipe down to dive!" % side
		4:
			var s_side := "left" if is_lh else "right"
			tutorial_desc_label.text = "Tap the glowing SKILL button near your %s jump zone to unleash active powers. Use flight controls to glide the skies!" % s_side
		_:
			if tutorial_desc_label:
				tutorial_desc_label.text = info["desc"]
	if tutorial_prev_btn:
		tutorial_prev_btn.visible = (tutorial_step > 0)
	if tutorial_next_btn:
		tutorial_next_btn.text = "FINISH ✔" if (tutorial_step == TUTORIAL_STEPS.size() - 1) else "NEXT ▶"

func _on_tutorial_prev_pressed() -> void:
	if tutorial_step > 0:
		_display_tutorial_step(tutorial_step - 1)

func _on_tutorial_next_pressed() -> void:
	if tutorial_step < TUTORIAL_STEPS.size() - 1:
		_display_tutorial_step(tutorial_step + 1)
	else:
		close_tutorial()

func update_dev_overlay(fps: int, speed: float, state_name: String, seed_val: int) -> void:
	if dev_text:
		dev_text.text = "FPS: %d | SPD: %.0f | %s | 🎲 %d" % [fps, speed, state_name, seed_val]
