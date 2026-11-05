class_name GameHUD
extends CanvasLayer

signal start_requested()
signal jump_requested(pressed: bool)
signal slide_requested(pressed: bool)
signal pause_requested()
signal resume_requested()
signal retry_requested()

@onready var score_label: Label = $TopBar/ScoreLabel
@onready var distance_label: Label = $TopBar/DistanceLabel
@onready var best_label: Label = $TopBar/BestLabel
@onready var pause_button: Button = $TopBar/PauseButton

@onready var touch_controls: Control = $TouchControls
@onready var slide_button: Button = $TouchControls/SlideButton
@onready var jump_button: Button = $TouchControls/JumpButton

@onready var start_menu: Control = $StartMenu
@onready var start_best_label: Label = $StartMenu/Panel/VBox/StartBestLabel
@onready var play_button: Button = $StartMenu/Panel/VBox/PlayButton

@onready var pause_menu: Control = $PauseMenu
@onready var resume_button: Button = $PauseMenu/Panel/VBox/ResumeButton
@onready var restart_button: Button = $PauseMenu/Panel/VBox/RestartButton

@onready var game_over_menu: Control = $GameOverMenu
@onready var cause_label: Label = $GameOverMenu/Panel/VBox/CauseLabel
@onready var final_score_label: Label = $GameOverMenu/Panel/VBox/FinalScoreLabel
@onready var final_dist_label: Label = $GameOverMenu/Panel/VBox/FinalDistLabel
@onready var best_score_label: Label = $GameOverMenu/Panel/VBox/BestScoreLabel
@onready var new_best_label: Label = $GameOverMenu/Panel/VBox/NewBestLabel
@onready var retry_button: Button = $GameOverMenu/Panel/VBox/RetryButton

# Touch gesture tracking
var touch_start_positions: Dictionary = {} # touch_index -> Vector2
var jump_touch_index: int = -1
var slide_touch_index: int = -1
const SWIPE_THRESHOLD: float = 20.0 # Minimum pixels to qualify as downward swipe

func _ready() -> void:
	play_button.pressed.connect(func(): start_requested.emit())
	pause_button.pressed.connect(_on_pause_button_pressed)
	resume_button.pressed.connect(_on_resume_button_pressed)
	restart_button.pressed.connect(_on_restart_button_pressed)
	retry_button.pressed.connect(_on_retry_button_pressed)

	# Direct button bindings for on-screen touch targets
	slide_button.button_down.connect(func(): slide_requested.emit(true))
	slide_button.button_up.connect(func(): slide_requested.emit(false))
	jump_button.button_down.connect(func(): jump_requested.emit(true))
	jump_button.button_up.connect(func(): jump_requested.emit(false))

	pause_menu.visible = false
	game_over_menu.visible = false
	start_menu.visible = false

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
	# If start menu is open, tapping screen starts the game
	if start_menu.visible:
		if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
			start_requested.emit()
		return

	# Touch screen gesture processing
	if event is InputEventScreenTouch:
		if event.pressed:
			_handle_touch_down(event.index, event.position)
		else:
			_handle_touch_up(event.index, event.position)
	elif event is InputEventScreenDrag:
		_handle_touch_drag(event.index, event.position)

func _handle_touch_down(index: int, pos: Vector2) -> void:
	touch_start_positions[index] = pos

	# Dynamic screen half split based on current visible viewport width
	var vp_width = get_viewport().get_visible_rect().size.x
	var split_x = vp_width * 0.5

	# Ignore clicks on very top bar (pause button area)
	if pos.y < 34.0:
		return

	if pos.x >= split_x:
		# Strictly RIGHT HALF = JUMP ZONE
		if jump_touch_index == -1:
			jump_touch_index = index
			jump_requested.emit(true)
	else:
		# Strictly LEFT HALF = SLIDE / DIVE ZONE (tap or hold)
		if slide_touch_index == -1:
			slide_touch_index = index
			slide_requested.emit(true)

func _handle_touch_drag(index: int, pos: Vector2) -> void:
	# Downward swipe on left side reinforces slide / dive
	if index == slide_touch_index and touch_start_positions.has(index):
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
	retry_requested.emit()
