class_name GameHUD
extends CanvasLayer

signal jump_requested(pressed: bool)
signal slide_requested(pressed: bool)
signal pause_requested()
signal resume_requested()
signal retry_requested()

@onready var score_label: Label = $TopBar/ScoreLabel
@onready var distance_label: Label = $TopBar/DistanceLabel
@onready var best_label: Label = $TopBar/BestLabel
@onready var pause_button: Button = $TopBar/PauseButton

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
var gesture_touch_index: int = -1
const SWIPE_THRESHOLD: float = 24.0 # Minimum pixels to qualify as downward swipe

func _ready() -> void:
	pause_button.pressed.connect(_on_pause_button_pressed)
	resume_button.pressed.connect(_on_resume_button_pressed)
	restart_button.pressed.connect(_on_restart_button_pressed)
	retry_button.pressed.connect(_on_retry_button_pressed)

	pause_menu.visible = false
	game_over_menu.visible = false

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

func hide_game_over() -> void:
	game_over_menu.visible = false

func show_pause_menu() -> void:
	pause_menu.visible = true

func hide_pause_menu() -> void:
	pause_menu.visible = false

func _unhandled_input(event: InputEvent) -> void:
	# Touch Screen Gesture Processing
	if event is InputEventScreenTouch:
		if event.pressed:
			_handle_touch_down(event.index, event.position)
		else:
			_handle_touch_up(event.index, event.position)
	elif event is InputEventScreenDrag:
		_handle_touch_drag(event.index, event.position)

func _handle_touch_down(index: int, pos: Vector2) -> void:
	touch_start_positions[index] = pos

	# Right half of screen (>= 240px) is designated Jump Zone
	if pos.x >= 240.0 and pos.y >= 35.0:
		if jump_touch_index == -1:
			jump_touch_index = index
			jump_requested.emit(true)
	# Left half of screen (< 240px) is Swipe / Gesture Zone
	elif pos.x < 240.0 and pos.y >= 35.0:
		if gesture_touch_index == -1:
			gesture_touch_index = index

func _handle_touch_drag(index: int, pos: Vector2) -> void:
	if index == gesture_touch_index and touch_start_positions.has(index):
		var start_pos: Vector2 = touch_start_positions[index]
		var delta = pos - start_pos
		# Detect downward swipe for slide
		if delta.y > SWIPE_THRESHOLD and absf(delta.y) > absf(delta.x) * 1.2:
			slide_requested.emit(true)

func _handle_touch_up(index: int, _pos: Vector2) -> void:
	if index == jump_touch_index:
		jump_touch_index = -1
		jump_requested.emit(false)
	elif index == gesture_touch_index:
		gesture_touch_index = -1
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
