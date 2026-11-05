class_name GameHUD
extends CanvasLayer

signal start_requested()
signal mode_selected(mode: int)
signal jump_requested(pressed: bool)
signal slide_requested(pressed: bool)
signal steer_requested(dir: float)
signal pause_requested()
signal resume_requested()
signal retry_requested()
signal menu_requested()

@onready var score_label: Label = $TopBar/ScoreLabel
@onready var distance_label: Label = $TopBar/DistanceLabel
@onready var best_label: Label = $TopBar/BestLabel
@onready var pause_button: Button = $TopBar/PauseButton

@onready var touch_controls: Control = $TouchControls
@onready var slide_button: Button = $TouchControls/SlideButton
@onready var steer_left_btn: Button = $TouchControls/SteerLeftButton
@onready var steer_right_btn: Button = $TouchControls/SteerRightButton
@onready var jump_button: Button = $TouchControls/JumpButton

@onready var start_menu: Control = $StartMenu
@onready var start_best_label: Label = $StartMenu/Panel/VBox/StartBestLabel
@onready var mode_casual_btn: Button = $StartMenu/Panel/VBox/ModeHBox/ModeCasualBtn
@onready var mode_runner_btn: Button = $StartMenu/Panel/VBox/ModeHBox/ModeRunnerBtn
@onready var mode_freestyle_btn: Button = $StartMenu/Panel/VBox/ModeHBox/ModeFreestyleBtn
@onready var mode_desc_label: Label = $StartMenu/Panel/VBox/ModeDescLabel
@onready var play_button: Button = $StartMenu/Panel/VBox/PlayButton

@onready var pause_menu: Control = $PauseMenu
@onready var resume_button: Button = $PauseMenu/Panel/VBox/ResumeButton
@onready var restart_button: Button = $PauseMenu/Panel/VBox/RestartButton
@onready var pause_menu_button: Button = $PauseMenu/Panel/VBox/PauseMenuButton

@onready var game_over_menu: Control = $GameOverMenu
@onready var cause_label: Label = $GameOverMenu/Panel/VBox/CauseLabel
@onready var final_score_label: Label = $GameOverMenu/Panel/VBox/FinalScoreLabel
@onready var final_dist_label: Label = $GameOverMenu/Panel/VBox/FinalDistLabel
@onready var best_score_label: Label = $GameOverMenu/Panel/VBox/BestScoreLabel
@onready var new_best_label: Label = $GameOverMenu/Panel/VBox/NewBestLabel
@onready var retry_button: Button = $GameOverMenu/Panel/VBox/RetryButton
@onready var game_over_menu_button: Button = $GameOverMenu/Panel/VBox/GameOverMenuButton

var current_mode: int = 1 # 0 = Casual, 1 = Runner, 2 = Freestyle
var retry_debounce: bool = false

# Touch gesture tracking
var touch_start_positions: Dictionary = {}
var jump_touch_index: int = -1
var slide_touch_index: int = -1
const SWIPE_THRESHOLD: float = 20.0

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

	# Freestyle steer buttons
	steer_left_btn.button_down.connect(func(): steer_requested.emit(-1.0))
	steer_left_btn.button_up.connect(func(): steer_requested.emit(0.0))
	steer_right_btn.button_down.connect(func(): steer_requested.emit(1.0))
	steer_right_btn.button_up.connect(func(): steer_requested.emit(0.0))

	select_mode(1) # Default to Runner mode

	pause_menu.visible = false
	game_over_menu.visible = false
	start_menu.visible = false

func select_mode(mode: int) -> void:
	current_mode = mode
	mode_selected.emit(mode)

	mode_casual_btn.modulate = Color(1.2, 1.2, 0.4, 1.0) if mode == 0 else Color(1, 1, 1, 0.7)
	mode_runner_btn.modulate = Color(1.2, 1.2, 0.4, 1.0) if mode == 1 else Color(1, 1, 1, 0.7)
	mode_freestyle_btn.modulate = Color(1.2, 1.2, 0.4, 1.0) if mode == 2 else Color(1, 1, 1, 0.7)

	match mode:
		0: # Casual
			mode_desc_label.text = "Fixed speed • Only Jump • Relaxed classic play"
			slide_button.visible = false
			steer_left_btn.visible = false
			steer_right_btn.visible = false
		1: # Runner
			mode_desc_label.text = "Accelerating speed • Jump & Slide • Intense challenge"
			slide_button.visible = true
			slide_button.offset_left = 14.0
			slide_button.offset_right = 90.0
			slide_button.text = "▼ SLIDE"
			steer_left_btn.visible = false
			steer_right_btn.visible = false
		2: # Freestyle
			mode_desc_label.text = "Steer Left/Right • Air control • Overcome hard puzzles"
			steer_left_btn.visible = true
			steer_right_btn.visible = true
			slide_button.visible = true
			# Reposition slide button to the right of steering buttons so there is ZERO overlap
			slide_button.offset_left = 130.0
			slide_button.offset_right = 196.0
			slide_button.text = "▼ DUCK"

func show_start_menu(best_score: int) -> void:
	start_best_label.text = "BEST: %05d" % best_score
	start_menu.visible = true
	touch_controls.visible = false

func hide_start_menu() -> void:
	start_menu.visible = false
	touch_controls.visible = true

func update_hud(score: int, distance_m: float, best_score: int) -> void:
	score_label.text = "SCORE: %05d" % score
	distance_label.text = "DIST: %dm" % int(distance_m)
	best_label.text = "HI: %05d" % best_score

func show_game_over(cause: String, score: int, distance_m: float, best_score: int, is_new_best: bool) -> void:
	cause_label.text = cause
	final_score_label.text = "SCORE: %d" % score
	final_dist_label.text = "DISTANCE: %dm" % int(distance_m)
	best_score_label.text = "BEST: %d" % best_score
	new_best_label.visible = is_new_best
	game_over_menu.visible = true
	touch_controls.visible = false
	retry_debounce = false

func hide_game_over() -> void:
	game_over_menu.visible = false
	touch_controls.visible = true

func show_pause_menu() -> void:
	pause_menu.visible = true
	touch_controls.visible = false

func hide_pause_menu() -> void:
	pause_menu.visible = false
	touch_controls.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if game_over_menu.visible:
		if event.is_action_pressed("jump"):
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

	if pos.x >= split_x:
		# Strictly RIGHT HALF = JUMP ZONE
		if jump_touch_index == -1:
			jump_touch_index = index
			jump_requested.emit(true)
	else:
		# In Casual mode, ignore left side touches (jump only)
		if current_mode == 0:
			return
		# In Runner mode: tap or hold left side = Slide
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
