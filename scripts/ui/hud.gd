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

@onready var score_label: Label = $TopBar/ScoreLabel
@onready var distance_label: Label = $TopBar/DistanceLabel
@onready var best_label: Label = $TopBar/BestLabel
@onready var points_label: Label = $TopBar/PointsLabel
@onready var pause_button: Button = $TopBar/PauseButton

@onready var touch_controls: Control = $TouchControls
@onready var slide_button: Button = $TouchControls/SlideButton
@onready var steer_left_btn: Button = $TouchControls/SteerLeftButton
@onready var steer_right_btn: Button = $TouchControls/SteerRightButton
@onready var jump_button: Button = $TouchControls/JumpButton

@onready var start_menu: Control = $StartMenu
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
@onready var resume_button: Button = $PauseMenu/Panel/VBox/ResumeButton
@onready var restart_button: Button = $PauseMenu/Panel/VBox/RestartButton
@onready var pause_menu_button: Button = $PauseMenu/Panel/VBox/PauseMenuButton

@onready var game_over_menu: Control = $GameOverMenu
@onready var cause_label: Label = $GameOverMenu/Panel/VBox/CauseLabel
@onready var final_score_label: Label = $GameOverMenu/Panel/VBox/StatsHBox/FinalScoreLabel
@onready var final_dist_label: Label = $GameOverMenu/Panel/VBox/StatsHBox/FinalDistLabel
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
@onready var shop_points_label: Label = $SkinShopDialog/Panel/VBox/HeaderHBox/ShopPointsLabel
@onready var shop_close_btn: Button = $SkinShopDialog/Panel/VBox/HeaderHBox/ShopCloseBtn
@onready var skins_hbox: HBoxContainer = $SkinShopDialog/Panel/VBox/SkinsHBox

@onready var challenges_dialog: Control = $ChallengesDialog
@onready var quests_points_label: Label = $ChallengesDialog/Panel/VBox/HeaderHBox/QuestsPointsLabel
@onready var quests_close_btn: Button = $ChallengesDialog/Panel/VBox/HeaderHBox/QuestsCloseBtn
@onready var quests_bottom_close_btn: Button = $ChallengesDialog/Panel/VBox/QuestsBottomCloseBtn
@onready var quests_list: VBoxContainer = $ChallengesDialog/Panel/VBox/ScrollContainer/QuestsList

@onready var challenge_toast: PanelContainer = $ChallengeToast
@onready var toast_label: Label = $ChallengeToast/ToastLabel

var current_mode: int = 1 # 0 = Casual, 1 = Runner, 2 = Freestyle
var retry_debounce: bool = false
var save_service: SaveService
var challenge_service: ChallengeService

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
		"desc": "Monochrome"
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
		"desc": "Volcanic"
	},
	{
		"id": "cyber",
		"name": "Cyber",
		"price": 500,
		"icon": "res://assets/sprites/skin_icon_cyber.png",
		"desc": "Synthwave"
	},
	{
		"id": "gold",
		"name": "Gold",
		"price": 1000,
		"icon": "res://assets/sprites/skin_icon_gold.png",
		"desc": "24k Fossil"
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

	select_mode(1) # Default to Runner mode

	pause_menu.visible = false
	game_over_menu.visible = false
	start_menu.visible = false
	skin_shop_dialog.visible = false
	challenges_dialog.visible = false
	challenge_toast.visible = false

func bind_services(p_save: SaveService, p_challenge: ChallengeService) -> void:
	save_service = p_save
	challenge_service = p_challenge
	if challenge_service:
		challenge_service.challenge_unlocked.connect(_on_challenge_unlocked)

func select_mode(mode: int) -> void:
	current_mode = mode
	mode_selected.emit(mode)

	mode_casual_btn.modulate = Color(1.2, 1.2, 0.4, 1.0) if mode == 0 else Color(1, 1, 1, 0.7)
	mode_runner_btn.modulate = Color(1.2, 1.2, 0.4, 1.0) if mode == 1 else Color(1, 1, 1, 0.7)
	mode_freestyle_btn.modulate = Color(1.2, 1.2, 0.4, 1.0) if mode == 2 else Color(1, 1, 1, 0.7)

	match mode:
		0: # Arcade Jump (Spicy)
			mode_desc_label.text = "⚡ Spicy Speed (310-520 px/s) • Pure Jump Reflexes • High-Speed Challenge"
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
			slide_button.offset_left = 130.0
			slide_button.offset_right = 196.0
			slide_button.text = "▼ DUCK"

func show_start_menu(best_score: int, points: int = 0) -> void:
	start_best_label.text = "BEST: %05d   " % best_score
	start_points_label.text = "PTS: %05d" % points
	points_label.text = "PTS: %05d" % points
	start_menu.visible = true
	touch_controls.visible = false
	skin_shop_dialog.visible = false
	challenges_dialog.visible = false

func hide_start_menu() -> void:
	start_menu.visible = false
	skin_shop_dialog.visible = false
	challenges_dialog.visible = false
	touch_controls.visible = true

func update_hud(score: int, distance_m: float, best_score: int, points: int = 0) -> void:
	score_label.text = "SCORE: %05d" % score
	distance_label.text = "DIST: %dm" % int(distance_m)
	best_label.text = "HI: %05d" % best_score
	points_label.text = "PTS: %05d" % points

func show_game_over(cause: String, score: int, distance_m: float, best_score: int, is_new_best: bool, run_pts: int = 0, total_pts: int = 0) -> void:
	cause_label.text = cause
	final_score_label.text = "SCORE: %d   " % score
	final_dist_label.text = "DIST: %dm" % int(distance_m)
	run_points_label.text = "+%d PTS EARNED" % run_pts
	best_score_label.text = "BEST: %d   " % best_score
	total_points_label.text = "TOTAL PTS: %d" % total_pts
	new_best_label.visible = is_new_best
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
	shop_points_label.text = "PTS: %05d" % current_pts
	points_label.text = "PTS: %05d" % current_pts
	start_points_label.text = "PTS: %05d" % current_pts

	# Clear previous cards
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
	panel.custom_minimum_size = Vector2(76, 150)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	# Name Label
	var name_lbl = Label.new()
	name_lbl.text = info["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	# Icon Texture
	var icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(32, 32)
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if ResourceLoader.exists(info["icon"]):
		icon_rect.texture = load(info["icon"])
	vbox.add_child(icon_rect)

	# Price / Status Label
	var price_lbl = Label.new()
	price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if is_unlocked:
		price_lbl.text = "OWNED"
		price_lbl.modulate = Color(0.4, 1.0, 0.4)
	else:
		price_lbl.text = "%d PTS" % info["price"]
		price_lbl.modulate = Color(1.0, 0.85, 0.2)
	vbox.add_child(price_lbl)

	# Action Button
	var btn = Button.new()
	if is_equipped:
		btn.text = "EQUIPPED"
		btn.disabled = true
		btn.modulate = Color(0.3, 0.9, 1.0)
	elif is_unlocked:
		btn.text = "EQUIP"
		btn.pressed.connect(func(): _on_equip_clicked(skin_id))
	else:
		if current_pts >= info["price"]:
			btn.text = "BUY"
			btn.modulate = Color(1.1, 1.1, 0.4)
			btn.pressed.connect(func(): _on_buy_clicked(skin_id, info["price"]))
		else:
			btn.text = "LOCKED"
			btn.disabled = true
			btn.modulate = Color(0.6, 0.6, 0.6)
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
	challenges_dialog.visible = true
	refresh_challenges()

func close_challenges() -> void:
	challenges_dialog.visible = false

func refresh_challenges() -> void:
	if save_service == null or challenge_service == null:
		return
	var current_pts = save_service.get_points()
	quests_points_label.text = "PTS: %05d" % current_pts

	for child in quests_list.get_children():
		child.queue_free()

	for ch in challenge_service.get_all_challenges():
		var row = _create_challenge_row(ch)
		quests_list.add_child(row)

func _create_challenge_row(ch: Dictionary) -> Control:
	var is_comp = save_service.is_challenge_completed(ch["id"])

	var panel = PanelContainer.new()
	var hbox = HBoxContainer.new()
	panel.add_child(hbox)

	var text_vbox = VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var title_lbl = Label.new()
	title_lbl.text = "★ " + ch["title"]
	title_lbl.modulate = Color(1.0, 0.9, 0.3)
	text_vbox.add_child(title_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text = ch["desc"]
	desc_lbl.modulate = Color(0.8, 0.8, 0.8)
	text_vbox.add_child(desc_lbl)

	hbox.add_child(text_vbox)

	var reward_lbl = Label.new()
	reward_lbl.text = "+%d PTS  " % ch["reward"]
	reward_lbl.modulate = Color(1.0, 0.85, 0.2)
	hbox.add_child(reward_lbl)

	var status_lbl = Label.new()
	if is_comp:
		status_lbl.text = "[CLAIMED]"
		status_lbl.modulate = Color(0.3, 1.0, 0.4)
	else:
		status_lbl.text = "[IN PROGRESS]"
		status_lbl.modulate = Color(0.6, 0.6, 0.6)
	hbox.add_child(status_lbl)

	return panel

func _on_challenge_unlocked(_id: String, title: String, reward: int) -> void:
	show_challenge_toast(title, reward)

func show_challenge_toast(title: String, reward: int) -> void:
	toast_label.text = "🏆 CHALLENGE COMPLETE: %s (+%d PTS)!" % [title, reward]
	challenge_toast.visible = true
	challenge_toast.modulate.a = 0.0

	var tw = create_tween()
	tw.tween_property(challenge_toast, "modulate:a", 1.0, 0.3)
	tw.tween_interval(2.5)
	tw.tween_property(challenge_toast, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func(): challenge_toast.visible = false)

# ==========================================
# Input & Touch Handling
# ==========================================
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
