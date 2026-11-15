extends RefCounted

const RunnerScene = preload("res://scenes/gameplay/endless_runner.tscn")
const TrapPickupScript = preload("res://scripts/objects/trap_pickup.gd")
const HUDScript = preload("res://scripts/ui/hud.gd")
const PracticeHubScript = preload("res://scripts/ui/practice_hub_ui.gd")

func get_test_name() -> String:
	return "V4OverhaulFeaturesTest"

func _clean_saves() -> void:
	for path in ["user://save_game.json", "user://save_game.bak"]:
		var abs_p := ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(abs_p)

func _create_runner() -> EndlessRunner:
	_clean_saves()
	var tree := Engine.get_main_loop() as SceneTree
	var r := RunnerScene.instantiate() as EndlessRunner
	tree.root.add_child(r)
	if r.save_service:
		r.save_service.data = r.save_service.get_default_data()
	return r

func _destroy_runner(r: EndlessRunner) -> void:
	if r and is_instance_valid(r):
		if r.get_parent():
			r.get_parent().remove_child(r)
		r.free()
	_clean_saves()

func test_60fps_settings_and_camera_zoom_clarity() -> Variant:
	if int(ProjectSettings.get_setting("application/run/max_fps", 0)) != 60:
		return "application/run/max_fps must be 60"
	if int(ProjectSettings.get_setting("physics/common/physics_ticks_per_second", 0)) != 60:
		return "physics_ticks_per_second must be 60"
	if not is_equal_approx(float(ProjectSettings.get_setting("physics/common/physics_jitter_fix", 1.0)), 0.0):
		return "physics_jitter_fix must be 0.0 for crisp 60fps scrolling"

	var r := _create_runner()
	r.begin_run()
	r.player.current_speed = 550.0
	for _i in range(40):
		r.camera._physics_process(1.0 / 60.0)
	var z := r.camera.zoom.x
	_destroy_runner(r)
	if z < 0.93 or z > 1.05:
		return "Camera zoom %.3f drifted outside crisp high-speed clarity range 0.94..1.04" % z
	return true

func test_difficulty_modes_opening_speeds_and_hearts() -> Variant:
	var r := _create_runner()

	# Mode 0: Easy (2 hearts, 196 opening speed)
	r.hud.select_mode(0)
	r.begin_run()
	if not is_equal_approx(r.player.current_speed, 196.0) or r.player.max_hearts != 2 or r.player.current_hearts != 2:
		var msg := "Mode 0 Easy mismatch: spd=%.1f hearts=%d/%d" % [r.player.current_speed, r.player.current_hearts, r.player.max_hearts]
		_destroy_runner(r)
		return msg
	r.player.invulnerability_timer = 0.0
	r.player.hit_hazard("Test Spike 1")
	if r.player.state_machine.current_state == PlayerStateMachine.State.DEAD or r.player.current_hearts != 1:
		_destroy_runner(r)
		return "Easy mode 2-heart shield must absorb 1st hit and leave 1 heart"
	r.player.invulnerability_timer = 0.0
	r.player.hit_hazard("Test Spike 2")
	if r.player.state_machine.current_state != PlayerStateMachine.State.DEAD or r.player.current_hearts != 0:
		_destroy_runner(r)
		return "Easy mode must die on 2nd hit"

	# Mode 1: Medium (1 heart, 216 opening speed)
	r.hud.select_mode(1)
	r.start_new_run()
	if not is_equal_approx(r.player.current_speed, 216.0) or r.player.max_hearts != 1:
		var msg1 := "Mode 1 Medium mismatch: spd=%.1f max_hearts=%d" % [r.player.current_speed, r.player.max_hearts]
		_destroy_runner(r)
		return msg1

	# Mode 2: Hard (3 hearts, 232 opening speed, steering enabled)
	r.hud.select_mode(2)
	r.start_new_run()
	if not is_equal_approx(r.player.current_speed, 232.0) or r.player.max_hearts != 3 or r.player.current_hearts != 3:
		var msg2 := "Mode 2 Hard mismatch: spd=%.1f hearts=%d/%d" % [r.player.current_speed, r.player.current_hearts, r.player.max_hearts]
		_destroy_runner(r)
		return msg2
	r.player.invulnerability_timer = 0.0
	r.player.hit_hazard("Hit 1")
	r.player.invulnerability_timer = 0.0
	r.player.hit_hazard("Hit 2")
	if r.player.state_machine.current_state == PlayerStateMachine.State.DEAD or r.player.current_hearts != 1:
		_destroy_runner(r)
		return "Hard mode must survive 2 hits and have 1 heart left"
	r.player.invulnerability_timer = 0.0
	r.player.hit_hazard("Hit 3")
	if r.player.state_machine.current_state != PlayerStateMachine.State.DEAD:
		_destroy_runner(r)
		return "Hard mode must die on 3rd hit"

	# Mode 3: Practice (continuous shield aura)
	r.hud.select_mode(3)
	r.start_new_run()
	if not r.player.practice_immortal or not r.fx_manager.active_immortal_shield:
		_destroy_runner(r)
		return "Practice mode must keep continuous active_immortal_shield aura on player"

	_destroy_runner(r)
	return true

func test_jump_slide_hit_pads_and_frame1_start() -> Variant:
	var r := _create_runner()
	r.hud.select_mode(1)
	r.init_title_screen()
	if r.hud._jump_hit_pad == null or r.hud._slide_hit_pad == null:
		_destroy_runner(r)
		return "Expected enlarged HitZoneLayer jump/slide hit pads to exist"
	if r.hud.jump_button.offset_right - r.hud.jump_button.offset_left < 78.0:
		_destroy_runner(r)
		return "Expected enlarged Jump button width >= 80px"

	# Pressing Jump before run starts begins run AND jumps immediately on frame 1
	r._on_hud_jump(true)
	if not r.is_game_started:
		_destroy_runner(r)
		return "_on_hud_jump(true) when not started must start the run immediately"
	r.player._physics_process(1.0 / 60.0)
	if r.player.velocity.y >= 0.0:
		_destroy_runner(r)
		return "Frame-1 Jump tap must also execute upward jump velocity (%f)" % r.player.velocity.y

	# Pressing Slide before run starts begins run AND holds slide
	r.init_title_screen()
	r._on_hud_slide(true)
	if not r.is_game_started or not r.player.slide_held:
		_destroy_runner(r)
		return "_on_hud_slide(true) when not started must start run and engage slide input"

	_destroy_runner(r)
	return true

func test_tutorial_7_steps_and_no_frame1_auto_jump() -> Variant:
	var r := _create_runner()
	r.hud.select_mode(3)
	r.begin_run()
	r.start_live_tutorial()

	if not is_equal_approx(r.player.position.y, 218.0):
		_destroy_runner(r)
		return "Tutorial start player.position.y must be 218.0 flush with floor, got %.2f" % r.player.position.y

	# Step physics without pressing Jump -> must NOT trigger jump step 0 or advance
	for _i in range(30):
		r.player._physics_process(1.0 / 60.0)
		r._update_live_tutorial(1.0 / 60.0)
	if r._tut_real_jump_triggered or r.tutorial_phase != 0:
		_destroy_runner(r)
		return "Tutorial Step 1 must NOT pass without real jump input"

	# Verify all 7 phases exist (0..6) and spawn expected target types cleanly
	for p_idx in range(7):
		r._setup_tutorial_phase(p_idx)
		if r.tutorial_phase != p_idx:
			_destroy_runner(r)
			return "Failed to setup Tutorial Phase %d" % p_idx

	_destroy_runner(r)
	return true

func test_skills_cap_4_rarity_meters_and_infinite_skill_lab() -> Variant:
	var r := _create_runner()
	r.save_service.set_enabled_map_skills([1, 2, 3, 4, 5, 6], false)
	var capped := r.save_service.get_enabled_map_skills()
	if capped.size() != SaveService.MAX_ENABLED_MAP_SKILLS:
		_destroy_runner(r)
		return "Enabled map skills must cap at %d, got %d" % [SaveService.MAX_ENABLED_MAP_SKILLS, capped.size()]

	var i_com: float = r.get_skill_spawn_interval_m(int(SkillManager.SkillType.BONE_BLADE))
	var i_rare: float = r.get_skill_spawn_interval_m(int(SkillManager.SkillType.BOOMERANG))
	var i_epic: float = r.get_skill_spawn_interval_m(int(SkillManager.SkillType.GROUND_SLAM))
	var i_leg: float = r.get_skill_spawn_interval_m(int(SkillManager.SkillType.PHOENIX_WINGS))
	if not (i_com < i_rare and i_rare < i_epic and i_epic < i_leg):
		_destroy_runner(r)
		return "Expected rarer skills to spawn at strictly larger meter intervals: %.0f / %.0f / %.0f / %.0f" % [i_com, i_rare, i_epic, i_leg]

	# Infinite Skill Lab test arena
	r.hud.select_mode(3)
	r._on_test_skill_requested(int(SkillManager.SkillType.BONE_BLADE))
	if not r.skill_lab_active or not r.player.skill_manager.skill_lab_infinite:
		_destroy_runner(r)
		return "Skill Lab test must activate skill_lab_infinite"
	for _k in range(4):
		r.player.skill_manager.activate_slot(0)
		r.player.skill_manager.update(0.35)
	if r.player.skill_manager.slots.is_empty() or int(r.player.skill_manager.slots[0].get("charges", 0)) < 1:
		_destroy_runner(r)
		return "Skill Lab skill must stay infinite (charges >= 1)"

	# Tips must clear when exiting to title menu
	r.hud.practice_hub.show_adaptive_hint("Test hint", 5.0)
	r.go_to_title_menu()
	if r.hud.practice_hub.hint_banner.visible or r.hud.skill_toast.visible:
		_destroy_runner(r)
		return "Hints and toasts must hide immediately when returning to menu"

	_destroy_runner(r)
	return true

func test_4_traps_debuffs_and_non_repeatable_quests() -> Variant:
	var r := _create_runner()
	r.hud.select_mode(1)
	r.begin_run()

	# Test all 4 trap types
	r.player.apply_trap_debuff(3.0, 1.35, TrapPickupScript.TrapType.HEAVY_GRAVITY)
	if not is_equal_approx(r.player.trap_gravity_mult, 1.55):
		_destroy_runner(r)
		return "Heavy Gravity trap must set trap_gravity_mult=1.55"

	r.player.apply_trap_debuff(3.0, 1.35, TrapPickupScript.TrapType.VISION_GLITCH)
	if r.player.trap_glitch_timer <= 0.0 or not r.hud.glitch_overlay.visible:
		_destroy_runner(r)
		return "Vision Glitch trap must enable trap_glitch_timer and glitch_overlay"

	r.player.skill_manager.equip_skill(SkillManager.SkillType.BONE_BLADE)
	r.player.apply_trap_debuff(3.0, 1.35, TrapPickupScript.TrapType.SKILL_JAM)
	if r.player.skill_manager.can_activate_slot(0):
		_destroy_runner(r)
		return "Skill Jam trap must lock active skill slot activation"

	# Quests non-repeatable guard
	var pts_before: int = r.save_service.get_points()
	var xp_before: int = r.save_service.get_player_xp()
	r.challenge_service.check_run_progress(120.0, 200, 1)
	var pts_mid: int = r.save_service.get_points()
	var xp_mid: int = r.save_service.get_player_xp()
	r.challenge_service.check_run_progress(120.0, 200, 1)
	var pts_after: int = r.save_service.get_points()
	var xp_after: int = r.save_service.get_player_xp()
	_destroy_runner(r)
	if pts_mid <= pts_before or xp_mid <= xp_before:
		return "Expected first quest unlock to grant points and XP"
	if pts_after != pts_mid or xp_after != xp_mid:
		return "Duplicate quest unlock must NOT grant rewards again (%d->%d pts, %d->%d xp)" % [pts_mid, pts_after, xp_mid, xp_after]
	return true

func test_shop_previews_enemies_guide_and_linked_maps() -> Variant:
	var r := _create_runner()
	r.hud.open_skin_shop()
	r.hud._select_shop_category("obstacle")
	var has_preview := false
	for card in r.hud.skins_hbox.get_children():
		if card.find_children("*", "", true, false).any(func(n): return n is HUDScript._CosmeticPreviewCanvas):
			has_preview = true
			break
	if not has_preview:
		_destroy_runner(r)
		return "Obstacle shop cards must render _CosmeticPreviewCanvas graphics"
	r.hud.close_skin_shop()

	# Enemies guide count & animated previews
	var ph := r.hud.practice_hub
	if PracticeHubScript.ENEMIES_GUIDE.size() < 8 or ph.enemies_list_vbox.get_child_count() != PracticeHubScript.ENEMIES_GUIDE.size():
		_destroy_runner(r)
		return "Enemies Encyclopedia must show all enemy/obstacle/trap cards"

	# Gap passability & linked multi-map loading
	var close_gap := PracticeHubScript.compute_gap_status({"type": "cactus", "x": 300.0}, {"type": "cactus", "x": 340.0}, 1)
	var wide_gap := PracticeHubScript.compute_gap_status({"type": "cactus", "x": 300.0}, {"type": "cactus", "x": 520.0}, 1)
	if close_gap["status"] != "BLOCKED" or wide_gap["status"] != "OK":
		_destroy_runner(r)
		return "Gap passability check mismatch: close=%s wide=%s" % [close_gap["status"], wide_gap["status"]]

	var map2 := {
		"id": "map_two",
		"name": "Map Two",
		"world_index": 3,
		"speed_preset": 2,
		"immortal": true,
		"length_px": 2600.0,
		"linked_next_id": "",
		"items": [{"type": "lava", "x": 420.0, "y": 230.0}]
	}
	var map1 := {
		"id": "map_one",
		"name": "Map One",
		"world_index": 0,
		"speed_preset": 1,
		"immortal": true,
		"length_px": 2600.0,
		"linked_next_id": "map_two",
		"items": [{"type": "cactus", "x": 360.0, "y": 230.0}]
	}
	r.save_service.save_custom_map(map2, false)
	r.save_service.save_custom_map(map1, false)
	r.start_custom_map(map1)
	if not r.custom_map_active or r.custom_map_chain.size() != 2 or str(r.custom_map_chain[1].get("id", "")) != "map_two":
		_destroy_runner(r)
		return "start_custom_map must load linked chain [map_one, map_two]"
	_destroy_runner(r)
	return true

func test_ps4_controller_menu_and_gameplay() -> Variant:
	var r := _create_runner()
	r.save_service.set_setting("ps_controller_enabled", true)
	r.hud.apply_control_layout(false)
	if r.hud.jump_button.visible or r.hud.slide_button.visible:
		_destroy_runner(r)
		return "PS4 mode must hide touch Jump & Slide buttons"
	if not r.hud.controls_hint.text.contains("PS4"):
		_destroy_runner(r)
		return "PS4 mode must update controls_hint text"

	# D-Pad Right switches mode 1 -> 2 on Start Menu, Cross starts run
	r.init_title_screen()
	r.hud.select_mode(1)
	if not r.hud._handle_ps_menu_button(JOY_BUTTON_DPAD_RIGHT) or r.hud.current_mode != 2:
		_destroy_runner(r)
		return "PS4 D-Pad Right must cycle Start Menu mode"
	if not r.hud._handle_ps_menu_button(JOY_BUTTON_A) or not r.is_game_started:
		_destroy_runner(r)
		return "PS4 Cross button must start game from Start Menu"

	_destroy_runner(r)
	return true
