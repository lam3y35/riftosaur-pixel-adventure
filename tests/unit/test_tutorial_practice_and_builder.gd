class_name TestTutorialPracticeAndBuilder
extends RefCounted

const RunnerScene = preload("res://scenes/gameplay/endless_runner.tscn")

func get_test_name() -> String:
	return "TutorialPracticeAndBuilderTest"

func _create_runner() -> EndlessRunner:
	var tree = Engine.get_main_loop() as SceneTree
	var runner = RunnerScene.instantiate() as EndlessRunner
	tree.root.add_child(runner)
	return runner

func _destroy_runner(runner: EndlessRunner) -> void:
	if is_instance_valid(runner):
		if runner.get_parent():
			runner.get_parent().remove_child(runner)
		runner.free()

func test_per_mode_high_scores_isolated_and_practice_no_score() -> Variant:
	var runner = _create_runner()
	var sv = runner.save_service
	sv.data = sv.get_default_data()

	sv.update_mode_high_score(0, 1200, 100.0, false)
	sv.update_mode_high_score(1, 2500, 220.0, false)
	sv.update_mode_high_score(2, 800, 75.0, false)
	var p_updated = sv.update_mode_high_score(3, 99999, 999.0, false)

	if p_updated:
		_destroy_runner(runner)
		return "Mode 3 (Tutorial & Practice) must never update high score"
	if sv.get_mode_best_score(0) != 1200 or sv.get_mode_best_score(1) != 2500 or sv.get_mode_best_score(2) != 800:
		_destroy_runner(runner)
		return "Per-mode best scores did not stay isolated: %s" % str(sv.data.get("mode_best_scores"))
	if sv.get_mode_best_score(3) != 0:
		_destroy_runner(runner)
		return "Mode 3 best score should always be 0"

	# Verify HUD hides score in Mode 3 and shows it in Mode 1
	runner.hud.select_mode(3)
	runner.current_mode = 3
	runner.hud.update_hud(500, 20.0, 0, 50)
	if runner.hud.score_label.visible or runner.hud.best_label.visible:
		_destroy_runner(runner)
		return "Score and Best labels must be hidden in Tutorial & Practice mode"

	runner.hud.select_mode(1)
	runner.current_mode = 1
	runner.hud.update_hud(500, 20.0, 2500, 50)
	if not runner.hud.score_label.visible or not runner.hud.best_label.visible:
		_destroy_runner(runner)
		return "Score and Best labels must be visible in Runner mode"

	_destroy_runner(runner)
	return true

func test_first_launch_auto_tutorial_flag() -> Variant:
	var runner = _create_runner()
	runner.save_service.data = runner.save_service.get_default_data()

	if not runner.should_auto_launch_tutorial():
		_destroy_runner(runner)
		return "Fresh save should report should_auto_launch_tutorial() == true"

	runner.hud.select_mode(3)
	runner.current_mode = 3
	runner.go_to_title_menu()

	if runner.should_auto_launch_tutorial():
		_destroy_runner(runner)
		return "Exiting Tutorial & Practice to Main Menu should mark first_launch_completed"

	_destroy_runner(runner)
	return true

func test_practice_immortality_and_adaptive_hints() -> Variant:
	var runner = _create_runner()
	runner.hud.select_mode(3)
	runner.begin_run()

	if not runner.player.practice_immortal:
		_destroy_runner(runner)
		return "Mode 3 must set player.practice_immortal = true"

	# Clear starter shield so we test pure immortality on repeated hits
	runner.player.skill_manager.clear_skill()
	var crate_scene = load("res://scenes/obstacles/obstacle_crate_block.tscn") as PackedScene
	var crate_node = crate_scene.instantiate() as Node2D
	runner.chunk_container.add_child(crate_node)
	var crate = crate_node.get_node("FrontHazard") as Hazard

	runner.player.invulnerability_timer = 0.0
	runner.player.hit_hazard("Crate collision", false, crate)
	if runner.player.state_machine.current_state == PlayerStateMachine.State.DEAD:
		_destroy_runner(runner)
		return "Player must never die in Practice mode (1st hit)"

	runner.player.invulnerability_timer = 0.0
	runner.player.hit_hazard("Crate collision", false, crate)
	if runner.player.state_machine.current_state == PlayerStateMachine.State.DEAD:
		_destroy_runner(runner)
		return "Player must never die in Practice mode (2nd hit)"

	if not runner.hud.practice_hub.hint_banner.visible:
		_destroy_runner(runner)
		return "Expected adaptive hint banner after 2 hits on same obstacle type"

	_destroy_runner(runner)
	return true

func test_live_tutorial_flow_and_skip() -> Variant:
	var runner = _create_runner()
	runner.hud.select_mode(3)
	runner.begin_run()
	runner.start_live_tutorial()

	if not runner.tutorial_active or not runner.hud.practice_hub.tutorial_banner.visible:
		_destroy_runner(runner)
		return "start_live_tutorial() should activate tutorial and show banner"

	runner._on_skip_to_practice()
	if runner.tutorial_active or runner.hud.practice_hub.tutorial_banner.visible:
		_destroy_runner(runner)
		return "Skip to Practice should deactivate tutorial and hide tutorial banner"
	if not runner.hud.practice_hub.practice_bar.visible:
		_destroy_runner(runner)
		return "Practice quick bar should be visible after skipping to Practice"

	_destroy_runner(runner)
	return true

func test_12_skills_tiers_rarity_and_map_selection() -> Variant:
	var all_skills = SkillManager.get_all_skill_types()
	if all_skills.size() != 12:
		return "Expected 12 skills, got %d" % all_skills.size()

	var runner = _create_runner()
	# Select only 1 Common (Bone Blade) and 1 Legendary (Phoenix Wings)
	var chosen: Array[int] = [int(SkillManager.SkillType.BONE_BLADE), int(SkillManager.SkillType.PHOENIX_WINGS)]
	runner.save_service.set_enabled_map_skills(chosen, false)
	runner._refill_skill_bag()

	var count_common := 0
	var count_legendary := 0
	for sk in runner._skill_bag:
		if sk == int(SkillManager.SkillType.BONE_BLADE):
			count_common += 1
		elif sk == int(SkillManager.SkillType.PHOENIX_WINGS):
			count_legendary += 1
		else:
			_destroy_runner(runner)
			return "Unselected skill %d appeared in _skill_bag!" % sk

	if count_common <= count_legendary:
		_destroy_runner(runner)
		return "Expected Common skill (%d) to appear more often than Legendary (%d)" % [count_common, count_legendary]

	# Test new skills activation
	runner.begin_run()
	runner.player.skill_manager.equip_skill(SkillManager.SkillType.FEATHER_FALL)
	if not runner.player.skill_manager.activate() or runner.player.gravity_scale_modifier >= 1.0:
		_destroy_runner(runner)
		return "Feather Fall skill failed to reduce gravity_scale_modifier"

	runner.player.skill_manager.equip_skill(SkillManager.SkillType.DOUBLE_GEM)
	if not runner.player.skill_manager.activate() or not runner.player.skill_manager.double_gem_active:
		_destroy_runner(runner)
		return "Double Gem skill failed to activate double_gem_active"

	runner.player.skill_manager.equip_skill(SkillManager.SkillType.PHOENIX_WINGS)
	if not runner.player.skill_manager.activate() or not runner.player.is_flying:
		_destroy_runner(runner)
		return "Phoenix Wings skill failed to activate flight"
	runner.player.skill_manager.clear_skill()
	if runner.player.is_flying:
		_destroy_runner(runner)
		return "Phoenix Wings clear_skill() failed to end flight"

	_destroy_runner(runner)
	return true

func test_section_practice_and_custom_map_builder() -> Variant:
	var runner = _create_runner()
	runner._on_section_practice_requested(5, "Crate + Cactus")
	if runner.practice_section_index != 5:
		_destroy_runner(runner)
		return "Section practice did not set practice_section_index = 5"

	var map_dict := {
		"id": "test_arena",
		"name": "Test Arena",
		"world_index": 2,
		"speed_preset": 0,
		"immortal": true,
		"items": [
			{"type": "cactus", "x": 360.0, "y": 216.0},
			{"type": "gem", "x": 420.0, "y": 172.0}
		]
	}
	runner.save_service.save_custom_map(map_dict, false)
	if runner.save_service.get_custom_maps().is_empty():
		_destroy_runner(runner)
		return "Failed to save custom map in SaveService"

	runner.start_custom_map(map_dict)
	if not runner.custom_map_active or runner.current_world_index != 2 or not runner.player.practice_immortal:
		_destroy_runner(runner)
		return "Custom map failed to apply world_index=2 and immortal=true"

	_destroy_runner(runner)
	return true
