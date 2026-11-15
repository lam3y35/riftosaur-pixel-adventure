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

func _panel_rect(ctrl: Control, vp_size: Vector2) -> Rect2:
	var x0: float = ctrl.anchor_left * vp_size.x + ctrl.offset_left
	var y0: float = ctrl.anchor_top * vp_size.y + ctrl.offset_top
	var x1: float = ctrl.anchor_right * vp_size.x + ctrl.offset_right
	var y1: float = ctrl.anchor_bottom * vp_size.y + ctrl.offset_bottom
	return Rect2(x0, y0, maxf(ctrl.size.x, x1 - x0), maxf(ctrl.size.y, y1 - y0))

func test_practice_hub_viewport_bounds_and_no_top_bar_overlap() -> Variant:
	var runner = _create_runner()
	var hud: GameHUD = runner.hud
	var ph = hud.practice_hub
	var vp_size: Vector2 = runner.get_viewport().get_visible_rect().size
	if vp_size.x < 320.0:
		vp_size = Vector2(480.0, 270.0)

	hud.select_mode(3)
	runner.begin_run()
	ph._sync_viewport_rect()
	ph.show_entry_choice()
	ph.show_practice_bar("FREE PRACTICE")
	ph.show_tutorial_step("STEP 1/5", "Body", "JUMP", Color.GREEN, "Try")

	var full_vp := Rect2(Vector2(-0.5, -0.5), vp_size + Vector2(1.0, 1.0))
	for p in [ph.entry_panel, ph.tutorial_banner, ph.practice_bar, ph.section_dialog, ph.skills_lab_dialog, ph.builder_dialog]:
		var pname: String = p.name
		var r: Rect2 = _panel_rect(p, vp_size)
		if not full_vp.encloses(r):
			_destroy_runner(runner)
			return "PracticeHubUI panel %s is out of viewport %s: %s" % [pname, str(vp_size), str(r)]

	# Banners must never swallow gameplay touches and must sit below TopBar
	if ph.tutorial_banner.mouse_filter != Control.MOUSE_FILTER_IGNORE or ph.hint_banner.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_destroy_runner(runner)
		return "Tutorial/Hint banner must use MOUSE_FILTER_IGNORE so touches pass through"
	var tut_r := _panel_rect(ph.tutorial_banner, vp_size)
	if tut_r.position.y < hud.top_bar.offset_bottom:
		_destroy_runner(runner)
		return "LiveTutorialBanner (%s) overlaps TopBar bottom %.1f" % [str(tut_r), hud.top_bar.offset_bottom]

	# PracticeQuickBar sits in empty TopBar Row 1 left area without touching Gems/Pause/Row 2
	var bar_r := _panel_rect(ph.practice_bar, vp_size)
	for top_ctrl in [hud.gems_label, hud.pause_button, hud.world_label, hud.distance_label]:
		if top_ctrl:
			var tr := _panel_rect(top_ctrl, vp_size)
			if bar_r.intersects(tr):
				_destroy_runner(runner)
				return "PracticeQuickBar %s intersects TopBar %s %s" % [str(bar_r), top_ctrl.name, str(tr)]

	# Verify builder ground-locked items use properly grounded default_y
	for item in ph.BUILDER_PALETTE:
		var bid: String = str(item.get("id", ""))
		if bool(item.get("ground_locked", false)):
			var expected_y: float = 216.0 if bid == "barrier" else (222.0 if bid == "crawler" else 230.0)
			if not is_equal_approx(float(item.get("default_y", 0.0)), expected_y):
				_destroy_runner(runner)
				return "Builder ground-locked item %s should have default_y %.1f" % [bid, expected_y]

	_destroy_runner(runner)
	return true

func test_touch_jump_slide_controls_visibility_focus_and_no_overlap() -> Variant:
	var runner = _create_runner()
	var hud: GameHUD = runner.hud
	var vp_size: Vector2 = runner.get_viewport().get_visible_rect().size
	if vp_size.x < 320.0:
		vp_size = Vector2(480.0, 270.0)

	runner.save_service.set_setting("ps_controller_enabled", false)
	hud.select_mode(1)
	runner.begin_run()

	if not hud.jump_button.visible or not hud.slide_button.visible:
		_destroy_runner(runner)
		return "JumpButton and SlideButton must be visible in Mode 1 when PS controller is off"
	if hud.jump_button.focus_mode != Control.FOCUS_NONE or hud.slide_button.focus_mode != Control.FOCUS_NONE or hud.pause_button.focus_mode != Control.FOCUS_NONE:
		_destroy_runner(runner)
		return "HUD action buttons must use FOCUS_NONE so Space/Arrow keys trigger gameplay instead of buttons"

	# Bottom-corner touch regions must trigger jump_requested and slide_requested (no dead zone)
	var touch_hits := [false, false]
	hud.jump_requested.connect(func(p: bool):
		if p:
			touch_hits[0] = true
	)
	hud.slide_requested.connect(func(p: bool):
		if p:
			touch_hits[1] = true
	)
	hud._handle_touch_down(0, Vector2(vp_size.x - 16.0, vp_size.y - 16.0))
	hud._handle_touch_up(0, Vector2(vp_size.x - 16.0, vp_size.y - 16.0))
	hud._handle_touch_down(1, Vector2(16.0, vp_size.y - 16.0))
	hud._handle_touch_up(1, Vector2(16.0, vp_size.y - 16.0))
	if not touch_hits[0] or not touch_hits[1]:
		_destroy_runner(runner)
		return "Bottom-corner touches failed to emit jump=%s / slide=%s" % [str(touch_hits[0]), str(touch_hits[1])]

	# With 3 skill buttons equipped, TouchControls buttons must not overlap in RH or LH layouts
	hud.update_skill_slots([
		{"type": 1, "info": {"name": "Bone Blade", "duration": 0.3, "icon": ""}, "charges": 2, "cooldown": 0.0, "duration": 0.0},
		{"type": 2, "info": {"name": "Air Dash", "duration": 0.2, "icon": ""}, "charges": 2, "cooldown": 0.0, "duration": 0.0},
		{"type": 3, "info": {"name": "Shockwave Roar", "duration": 0.3, "icon": ""}, "charges": 1, "cooldown": 0.0, "duration": 0.0},
	])
	for lh in [false, true]:
		hud.apply_control_layout(lh)
		var rects: Array[Rect2] = []
		var names: Array[String] = []
		for ch in hud.touch_controls.get_children():
			if ch is Control and (ch as Control).visible:
				rects.append(_panel_rect(ch as Control, vp_size))
				names.append(ch.name)
		for i in range(rects.size()):
			for j in range(i + 1, rects.size()):
				if rects[i].intersects(rects[j]):
					_destroy_runner(runner)
					return "TouchControls overlap (LH=%s): %s %s vs %s %s" % [str(lh), names[i], str(rects[i]), names[j], str(rects[j])]

	_destroy_runner(runner)
	return true

func test_live_tutorial_ground_alignment_and_mechanic_advancement() -> Variant:
	var runner = _create_runner()
	runner.hud.select_mode(3)
	runner.begin_run()
	runner.start_live_tutorial()

	if runner._tut_target_node == null or not is_equal_approx(runner._tut_target_node.position.y, 230.0):
		_destroy_runner(runner)
		return "Tutorial Phase 0 cactus should spawn on ground y=230.0"

	# Should NOT auto-advance purely from timer if player hasn't jumped/passed obstacle
	runner._update_live_tutorial(10.0)
	if runner.tutorial_phase != 0:
		_destroy_runner(runner)
		return "Tutorial Phase 0 must not auto-skip on timer without performing the jump"

	# If player passes target without jumping, target respawns instead of advancing
	runner.player.global_position.x = runner._tut_target_node.global_position.x + 60.0
	var old_target = runner._tut_target_node
	runner._update_live_tutorial(0.016)
	if runner.tutorial_phase != 0 or runner._tut_target_node == old_target:
		_destroy_runner(runner)
		return "Tutorial Phase 0 should respawn target when missed instead of advancing"

	# Completing jump + passing target should celebrate & advance to Phase 1
	runner._tut_short_jump_done = true
	runner._tut_hit_current_obstacle = false
	runner.player.global_position.x = runner._tut_target_node.global_position.x + 60.0
	runner._update_live_tutorial(0.016)
	runner._update_live_tutorial(0.70)
	if runner.tutorial_phase != 1:
		_destroy_runner(runner)
		return "Tutorial should advance to Phase 1 after successful jump & clear"
	if runner._tut_target_node == null or not is_equal_approx(runner._tut_target_node.position.y, 230.0):
		_destroy_runner(runner)
		return "Tutorial Phase 1 crate should spawn on ground y=230.0"

	# Advance Phase 1 -> 2 -> 3 -> 4 and verify wooden barrier y=216.0
	runner._setup_tutorial_phase(4)
	if runner._tut_target_node == null or not is_equal_approx(runner._tut_target_node.position.y, 216.0):
		_destroy_runner(runner)
		return "Tutorial Phase 4 wooden barrier should spawn at ground-aligned y=216.0"

	_destroy_runner(runner)
	return true
