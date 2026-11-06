class_name TestEndlessRunner
extends RefCounted

const RunnerScene = preload("res://scenes/gameplay/endless_runner.tscn")

func get_test_name() -> String:
	return "EndlessRunnerLoopTest"

func _create_runner_world() -> Dictionary:
	var tree = Engine.get_main_loop() as SceneTree
	var runner = RunnerScene.instantiate() as EndlessRunner
	tree.root.add_child(runner)
	return {"tree": tree, "runner": runner}

func _destroy_runner_world(w: Dictionary) -> void:
	if w.has("runner") and is_instance_valid(w["runner"]):
		var runner = w["runner"]
		if runner.get_parent():
			runner.get_parent().remove_child(runner)
		runner.free()

func test_runner_initialization() -> Variant:
	var w = _create_runner_world()
	var runner: EndlessRunner = w["runner"]

	if runner.is_game_over:
		_destroy_runner_world(w)
		return "Runner should not start in game over state"

	if runner.current_score != 0 or runner.distance_m != 0.0:
		_destroy_runner_world(w)
		return "Score or distance non-zero at start"

	if runner.chunk_pool.size() < 3:
		_destroy_runner_world(w)
		return "Expected at least 3 initial chunks spawned, got %d" % runner.chunk_pool.size()

	_destroy_runner_world(w)
	return true

func test_distance_and_score_progression() -> Variant:
	var w = _create_runner_world()
	var runner: EndlessRunner = w["runner"]
	runner.begin_run()

	# Step 60 physics ticks (1 second)
	for _i in range(60):
		runner.player._physics_process(1.0 / 60.0)
		runner._physics_process(1.0 / 60.0)

	var dist = runner.distance_m
	var score = runner.current_score
	_destroy_runner_world(w)

	if dist <= 10.0:
		return "Distance did not increase as expected: %.1fm" % dist

	if score <= 10:
		return "Score did not accumulate with distance: %d" % score

	return true

func test_pause_and_resume() -> Variant:
	var w = _create_runner_world()
	var runner: EndlessRunner = w["runner"]
	runner.begin_run()

	runner.pause_game()
	if not runner.is_paused or not runner.get_tree().paused:
		_destroy_runner_world(w)
		return "Game was not paused properly"

	runner.resume_game()
	if runner.is_paused or runner.get_tree().paused:
		_destroy_runner_world(w)
		return "Game was not resumed properly"

	_destroy_runner_world(w)
	return true

func test_game_over_and_instant_retry() -> Variant:
	var w = _create_runner_world()
	var runner: EndlessRunner = w["runner"]
	runner.begin_run()

	# Simulate death
	runner.player.hit_hazard("Hit by Desert Cactus Rock", true)

	if not runner.is_game_over:
		_destroy_runner_world(w)
		return "Runner did not enter game over on player death"

	if not runner.hud.game_over_menu.visible:
		_destroy_runner_world(w)
		return "Game over UI was not shown"

	var cause_txt = runner.hud.cause_label.text
	if cause_txt != "Hit by Desert Cactus Rock":
		_destroy_runner_world(w)
		return "Cause label mismatch: '%s'" % cause_txt

	# Instant retry
	runner.restart_run()

	if runner.is_game_over:
		_destroy_runner_world(w)
		return "Runner remained in game over after restart"

	if runner.player.state_machine.current_state != PlayerStateMachine.State.RUN:
		_destroy_runner_world(w)
		return "Player state not reset to RUN on restart: %s" % runner.player.state_machine.get_state_name()

	if runner.current_score != 0 or runner.distance_m != 0.0:
		_destroy_runner_world(w)
		return "Score/distance not reset on restart"

	_destroy_runner_world(w)
	return true

func test_camera_ground_lock_during_jump() -> Variant:
	var w = _create_runner_world()
	var runner: EndlessRunner = w["runner"]
	runner.begin_run()

	var cam = runner.camera
	if cam == null:
		_destroy_runner_world(w)
		return "Runner camera not found"

	# Baseline Y is 135.0
	if absf(cam.global_position.y - 135.0) > 1.0:
		_destroy_runner_world(w)
		return "Camera baseline Y expected 135.0, got %.1f" % cam.global_position.y

	# Player jumps
	runner.player._execute_jump()
	for _i in range(15):
		runner.player._physics_process(1.0 / 60.0)
		cam._physics_process(1.0 / 60.0)

	# Camera Y must NOT move during mid-air jump (prevents background/ground disconnect)
	if absf(cam.global_position.y - 135.0) > 1.0:
		var cam_y = cam.global_position.y
		_destroy_runner_world(w)
		return "Camera Y moved to %.1f during jump (expected 135.0 ground lock)" % cam_y

	_destroy_runner_world(w)
	return true

func test_skin_switching_and_shop_dialog() -> Variant:
	var w = _create_runner_world()
	var runner: EndlessRunner = w["runner"]

	# Test player skin switching
	var switched_emerald = runner.player.set_skin("emerald")
	if not switched_emerald or runner.player.get_skin() != "emerald":
		_destroy_runner_world(w)
		return "Failed to switch player skin to emerald"

	var switched_ruby = runner.player.set_skin("ruby")
	if not switched_ruby or runner.player.get_skin() != "ruby":
		_destroy_runner_world(w)
		return "Failed to switch player skin to ruby"

	var switched_invalid = runner.player.set_skin("nonexistent_skin_xyz")
	if switched_invalid:
		_destroy_runner_world(w)
		return "Player.set_skin should return false for invalid skin"

	# Test HUD shop dialog opening & closing
	runner.hud.open_skin_shop()
	if not runner.hud.skin_shop_dialog.visible:
		_destroy_runner_world(w)
		return "Skin shop dialog should be visible after open_skin_shop()"

	runner.hud.close_skin_shop()
	if runner.hud.skin_shop_dialog.visible:
		_destroy_runner_world(w)
		return "Skin shop dialog should be hidden after close_skin_shop()"

	# Test HUD challenges dialog opening & closing
	runner.hud.open_challenges()
	if not runner.hud.challenges_dialog.visible:
		_destroy_runner_world(w)
		return "Challenges dialog should be visible after open_challenges()"

	runner.hud.close_challenges()
	if runner.hud.challenges_dialog.visible:
		_destroy_runner_world(w)
		return "Challenges dialog should be hidden after close_challenges()"

	_destroy_runner_world(w)
	return true

func test_quests_dialog_scroll_and_touch_swipe() -> Variant:
	var w = _create_runner_world()
	var runner: EndlessRunner = w["runner"]
	var hud: GameHUD = runner.hud

	hud.open_challenges()
	if not hud.challenges_dialog.visible:
		_destroy_runner_world(w)
		return "Challenges dialog should be visible"

	var scroll = hud.quests_scroll
	var list = hud.quests_list

	if scroll == null or list == null:
		_destroy_runner_world(w)
		return "Quests scroll container or list is null"

	if list.get_child_count() != 8:
		_destroy_runner_world(w)
		return "Expected 8 challenge cards, got %d" % list.get_child_count()

	if list.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_destroy_runner_world(w)
		return "Quests list should have mouse_filter = MOUSE_FILTER_IGNORE"

	for card in list.get_children():
		if card.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			_destroy_runner_world(w)
			return "Challenge card must have mouse_filter = MOUSE_FILTER_IGNORE"
		for child in card.get_children():
			if child.mouse_filter != Control.MOUSE_FILTER_IGNORE:
				_destroy_runner_world(w)
				return "Challenge card internal container must ignore mouse filter: %s" % child.name

	# Ensure scroll range allows scrolling in headless test environment
	if scroll.get_v_scroll_bar().max_value <= 0.0:
		scroll.get_v_scroll_bar().max_value = 500.0

	var init_scroll = scroll.scroll_vertical

	# Simulate touch down
	var ev_touch_down = InputEventScreenTouch.new()
	ev_touch_down.index = 0
	ev_touch_down.pressed = true
	ev_touch_down.position = Vector2(240, 180)
	hud._on_quests_scroll_gui_input(ev_touch_down)

	# Simulate drag upward (swipe up -> content moves up -> scroll_vertical increases)
	var ev_drag = InputEventScreenDrag.new()
	ev_drag.index = 0
	ev_drag.position = Vector2(240, 120)
	ev_drag.relative = Vector2(0, -60)
	ev_drag.velocity = Vector2(0, -300)
	hud._on_quests_scroll_gui_input(ev_drag)

	var val_after_drag = scroll.scroll_vertical
	if val_after_drag <= init_scroll:
		_destroy_runner_world(w)
		return "Scroll vertical did not advance on swipe up drag: %d vs %d" % [val_after_drag, init_scroll]

	# Simulate touch up
	var ev_touch_up = InputEventScreenTouch.new()
	ev_touch_up.index = 0
	ev_touch_up.pressed = false
	ev_touch_up.position = Vector2(240, 120)
	hud._on_quests_scroll_gui_input(ev_touch_up)

	# Verify momentum step
	var scroll_before_momentum = scroll.scroll_vertical
	hud._process(0.05)
	if scroll.scroll_vertical < scroll_before_momentum:
		_destroy_runner_world(w)
		return "Kinetic momentum failed to continue scrolling forward: %d vs %d" % [scroll.scroll_vertical, scroll_before_momentum]

	hud.close_challenges()
	if hud.challenges_dialog.visible:
		_destroy_runner_world(w)
		return "Challenges dialog failed to close"

	_destroy_runner_world(w)
	return true
