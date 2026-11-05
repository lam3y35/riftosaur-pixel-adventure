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

	# Simulate death
	runner.player.hit_hazard("Hit by Desert Cactus Rock")

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
