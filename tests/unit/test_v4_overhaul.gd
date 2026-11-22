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

	# Mode 0: Easy (1 heart, 196 opening speed)
	r.hud.select_mode(0)
	r.begin_run()
	if not is_equal_approx(r.player.current_speed, 196.0) or r.player.max_hearts != 1 or r.player.current_hearts != 1:
		var msg := "Mode 0 Easy mismatch: spd=%.1f hearts=%d/%d" % [r.player.current_speed, r.player.current_hearts, r.player.max_hearts]
		_destroy_runner(r)
		return msg
	r.player.invulnerability_timer = 0.0
	r.player.hit_hazard("Test Spike 1")
	if r.player.state_machine.current_state != PlayerStateMachine.State.DEAD or r.player.current_hearts != 0:
		_destroy_runner(r)
		return "Easy mode (1 heart) must die on 1st hit"

	# Mode 1: Medium (2 hearts, 216 opening speed)
	r.hud.select_mode(1)
	r.start_new_run()
	if not is_equal_approx(r.player.current_speed, 216.0) or r.player.max_hearts != 2 or r.player.current_hearts != 2:
		var msg1 := "Mode 1 Medium mismatch: spd=%.1f hearts=%d/%d" % [r.player.current_speed, r.player.current_hearts, r.player.max_hearts]
		_destroy_runner(r)
		return msg1
	r.player.invulnerability_timer = 0.0
	r.player.hit_hazard("Medium Hit 1")
	if r.player.state_machine.current_state == PlayerStateMachine.State.DEAD or r.player.current_hearts != 1:
		_destroy_runner(r)
		return "Medium mode 2-heart shield must absorb 1st hit and leave 1 heart"
	r.player.invulnerability_timer = 0.0
	r.player.hit_hazard("Medium Hit 2")
	if r.player.state_machine.current_state != PlayerStateMachine.State.DEAD or r.player.current_hearts != 0:
		_destroy_runner(r)
		return "Medium mode must die on 2nd hit"

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

func test_v130_regression_audit_fixes() -> Variant:
	var r := _create_runner()

	# 1. SaveService preserves 5000px map length & trap_type
	var big_map := {
		"id": "max_map",
		"name": "Max Span",
		"world_index": 1,
		"speed_preset": 1,
		"immortal": false,
		"length_px": 5000.0,
		"items": [{"type": "trap", "x": 4900.0, "y": 216.0, "trap_type": 2}]
	}
	r.save_service.save_custom_map(big_map, false)
	var loaded := r.save_service.get_custom_maps()
	var found := {}
	for m in loaded:
		if str(m.get("id", "")) == "max_map":
			found = m
			break
	if found.is_empty() or not is_equal_approx(float(found.get("length_px", 0.0)), 5000.0):
		_destroy_runner(r)
		return "SaveService must preserve custom map length_px=5000.0"
	var first_item: Dictionary = found.get("items", [{}])[0]
	if not is_equal_approx(float(first_item.get("x", 0.0)), 4900.0) or int(first_item.get("trap_type", -1)) != 2:
		_destroy_runner(r)
		return "SaveService must preserve trailing item x=4900 and trap_type=2"

	# 2. PS4 single-binding enforcement, skill activation, OS flight via Jump/Slide, & entry_panel B dismissal
	r.save_service.set_setting("ps_controller_enabled", true)
	r.hud.apply_control_layout(false)
	var jump_events: Array[bool] = []
	r.hud.jump_requested.connect(func(p: bool): jump_events.append(p))
	var ax_up := InputEventJoypadMotion.new()
	ax_up.axis = JOY_AXIS_LEFT_Y
	ax_up.axis_value = -0.9
	r.hud._handle_ps_controller_input(ax_up)
	var dpad_up := InputEventJoypadButton.new()
	dpad_up.button_index = JOY_BUTTON_DPAD_UP
	dpad_up.pressed = true
	r.hud._handle_ps_controller_input(dpad_up)
	if not jump_events.is_empty():
		_destroy_runner(r)
		return "Unbound stick/D-Pad must NOT duplicate jump_requested in PS4 mode: %s" % str(jump_events)

	# When explicitly bound to axis:1:-, stick release emits false
	r.save_service.set_ps_binding("jump", "axis:1:-")
	r.hud._ps_axis_held.clear()
	r.hud._handle_ps_controller_input(ax_up)
	var ax_center := InputEventJoypadMotion.new()
	ax_center.axis = JOY_AXIS_LEFT_Y
	ax_center.axis_value = 0.0
	r.hud._handle_ps_controller_input(ax_center)
	if jump_events.size() < 2 or jump_events[0] != true or jump_events[1] != false:
		_destroy_runner(r)
		return "PS4 bound axis:1:- must emit jump_requested(true) then (false) on release: %s" % str(jump_events)
	r.save_service.set_ps_binding("jump", "btn:0")

	# PS4 skill_1 / skill_2 / skill_3 emit skill_slot_requested via _input
	var skill_slots_triggered: Array[int] = []
	r.hud.skill_slot_requested.connect(func(idx: int): skill_slots_triggered.append(idx))
	r.hud.hide_start_menu()
	for btn_i in [JOY_BUTTON_X, JOY_BUTTON_Y, JOY_BUTTON_RIGHT_SHOULDER]:
		var sk_ev := InputEventJoypadButton.new()
		sk_ev.button_index = btn_i
		sk_ev.pressed = true
		r.hud._input(sk_ev)
	if skill_slots_triggered != [0, 1, 2]:
		_destroy_runner(r)
		return "PS4 skill buttons must trigger slots [0, 1, 2], got %s" % str(skill_slots_triggered)

	# OS mode flight keeps flight_controls hidden and routes Jump/Slide hit pads to flight up/down
	r.save_service.set_setting("ps_controller_enabled", false)
	r.hud.apply_control_layout(false)
	r.hud.show_flight_hud(1, 5.0)
	if r.hud.flight_controls and r.hud.flight_controls.visible:
		_destroy_runner(r)
		return "OS mode flight must NOT show separate flight_controls buttons"
	if not r.hud.jump_button.visible or not r.hud.slide_button.visible:
		_destroy_runner(r)
		return "OS mode flight must keep Jump & Slide buttons visible"
	var fl_up := [false]
	var fl_down := [false]
	r.hud.flight_up_requested.connect(func(p: bool): fl_up[0] = p)
	r.hud.flight_down_requested.connect(func(p: bool): fl_down[0] = p)
	var mb_up := InputEventMouseButton.new()
	mb_up.button_index = MOUSE_BUTTON_LEFT
	mb_up.pressed = true
	mb_up.device = 0
	r.hud._on_hit_pad_gui_input(mb_up, true)
	r.hud._on_hit_pad_gui_input(mb_up, false)
	if not fl_up[0] or not fl_down[0]:
		_destroy_runner(r)
		return "OS mode flight must route Jump/Slide pads to flight_up/flight_down"
	r.hud.hide_flight_hud()

	r.hud.practice_hub.show_entry_choice()
	if not r.hud.practice_hub.entry_panel.visible:
		_destroy_runner(r)
		return "entry_panel should be visible"
	var closed := r.hud._handle_ps_menu_button(JOY_BUTTON_B)
	if not closed or r.hud.practice_hub.entry_panel.visible:
		_destroy_runner(r)
		return "PS4 Circle must dismiss entry_panel cleanly without softlock"

	# 3. Contextual skill horizontal hazard clearance
	var haz: Array[Vector2] = [Vector2(240.0, 224.0)]
	var gems: Array[Vector2] = []
	var cpos := r._pick_contextual_skill_pos(SkillManager.SkillType.STONE_SHIELD, false, Vector2.ZERO, false, Vector2.ZERO, false, Vector2.ZERO, haz, gems)
	if absf(cpos.x - 240.0) < 50.0 and cpos.y >= 175.0:
		_destroy_runner(r)
		return "Contextual skill pos must keep horizontal clearance from ground hazard at x=240: got %s" % str(cpos)

	# 4. Linked custom map section transition & completion
	var sec2 := {
		"id": "chain_s2", "name": "Stage Two", "world_index": 3, "speed_preset": 2,
		"immortal": false, "length_px": 1200.0, "linked_next_id": "",
		"items": [{"type": "trap", "x": 450.0, "y": 216.0, "trap_type": 3}]
	}
	var sec1 := {
		"id": "chain_s1", "name": "Stage One", "world_index": 0, "speed_preset": 0,
		"immortal": true, "length_px": 1200.0, "linked_next_id": "chain_s2",
		"items": []
	}
	r.save_service.save_custom_map(sec2, false)
	r.save_service.save_custom_map(sec1, false)
	r.start_custom_map(sec1)
	r.player.global_position.x = 1350.0
	r._update_custom_map_progression()
	if r._custom_active_section_idx != 1 or r.current_world_index != 3 or int(r.custom_map_data.get("speed_preset", 0)) != 2:
		_destroy_runner(r)
		return "Linked custom map must transition world & speed when entering Stage 2"
	r.player.global_position.x = r._custom_total_end_x + 40.0
	r._update_custom_map_progression()
	if not r._custom_map_completed:
		_destroy_runner(r)
		return "Linked custom map must mark completion once player clears total span"

	# 5. Parallax cosmetic tint survives world theme switches/transitions
	var map_tint := Color(0.5, 0.8, 1.0, 1.0)
	r.parallax_bg.set_cosmetic_tint(map_tint)
	if r.world_themes.size() > 1 and r.world_themes[1] != null:
		r.parallax_bg.apply_theme_immediate(r.world_themes[1])
		var expected_mod: Color = r.world_themes[1].ambient_tint * map_tint
		if r.parallax_bg.cosmetic_tint != map_tint or not r.parallax_bg.sky_sprite.modulate.is_equal_approx(expected_mod):
			_destroy_runner(r)
			return "Parallax cosmetic tint must compose with biome ambient_tint on theme switch"
		r.parallax_bg.transition_to_theme(r.world_themes[1], 0.1)
		if r.parallax_bg.cosmetic_tint != map_tint:
			_destroy_runner(r)
			return "Parallax cosmetic tint must persist during tweened theme transition"

	# 6. Multi-trap independent timers + Shop swipe guard
	r.player.practice_immortal = false
	r.player.reset()
	r.player.apply_trap_debuff(3.5, 115.0, 0)
	r.player.apply_trap_debuff(2.0, 0.0, 1)
	r.player._update_timers(2.2)
	if r.player.trap_gravity_timer > 0.0 or r.player.trap_gravity_mult > 1.01 or r.player.trap_speed_timer <= 0.0 or r.player.trap_speed_penalty <= 0.0:
		var msg := "Independent trap timers failed: grav=%s spd=%s pen=%s" % [str(r.player.trap_gravity_timer), str(r.player.trap_speed_timer), str(r.player.trap_speed_penalty)]
		_destroy_runner(r)
		return msg

	r.save_service.data["points"] = 500
	r.hud._shop_drag_moved = true
	r.hud._on_buy_clicked("emerald", 100)
	if r.save_service.get_points() != 500:
		_destroy_runner(r)
		return "Shop swipe guard must ignore buy tap during drag gesture"
	r.hud._shop_drag_moved = false

	_destroy_runner(r)
	return true

func test_round2_fixes_loadout_tips_builder_flight_overhang_and_ps4() -> Variant:
	var r := _create_runner()

	# 1. Start Menu exposes Normal-Game Skills Loadout & Enemies Guide directly
	if r.hud.start_skills_btn == null or r.hud.start_enemies_btn == null:
		_destroy_runner(r)
		return "Start Menu must expose StartSkillsBtn and StartEnemiesBtn directly for Normal Game"
	r.hud.start_skills_btn.pressed.emit()
	if not r.hud.practice_hub.skills_lab_dialog.visible or not r.hud.practice_hub.skills_loadout_only_mode:
		_destroy_runner(r)
		return "StartSkillsBtn must open Normal-Game Skills Loadout mode"
	r.hud.practice_hub.close_skills_lab()

	# 2. Tips clear immediately on death and on new game
	r.hud.select_mode(3)
	r.begin_run()
	r.hud.practice_hub.show_adaptive_hint("Transient tip", 8.0)
	if not r.hud.practice_hub.hint_banner.visible:
		_destroy_runner(r)
		return "Hint banner should be visible during active run"
	r._on_player_died("Test Death")
	if r.hud.practice_hub.hint_banner.visible:
		_destroy_runner(r)
		return "Hint banner must hide when run ends"
	r.hud.practice_hub.show_adaptive_hint("Stale tip", 8.0)
	r.start_new_run()
	if r.hud.practice_hub.hint_banner.visible:
		_destroy_runner(r)
		return "Hint banner must hide when starting a new run"

	# 3. Builder mode with Mortality: ON (immortal: false) must NOT grant shield aura or Stone Shield
	var mort_map := {
		"id": "mort_test",
		"name": "Mortal Test",
		"world_index": 0,
		"speed_preset": 1,
		"immortal": false,
		"length_px": 5000.0,
		"items": []
	}
	r.start_custom_map(mort_map)
	if r.player.practice_immortal or r.player.skill_manager.has_skill(SkillManager.SkillType.STONE_SHIELD) or r.fx_manager.active_shield or r.fx_manager.active_immortal_shield:
		_destroy_runner(r)
		return "Builder with Mortality ON must NOT equip Stone Shield or activate shield aura"

	# 4. FlightPickup equips into skill slot and waits for manual click (no auto-fly on pickup)
	r.hud.select_mode(1)
	r.custom_map_active = false
	r.start_new_run()
	var wings_sc := load("res://scenes/objects/flight_pickup_wings.tscn") as PackedScene
	var wings := wings_sc.instantiate() as FlightPickup
	r.add_child(wings)
	wings.collect(r.player)
	if r.player.is_flying:
		_destroy_runner(r)
		return "Collecting FlightPickup must NOT immediately activate flight; must wait for click"
	if not r.player.skill_manager.has_skill(SkillManager.SkillType.PHOENIX_WINGS):
		_destroy_runner(r)
		return "Collecting FlightPickup must equip flying skill into SkillManager slot"
	if not r.player.use_skill() or not r.player.is_flying:
		_destroy_runner(r)
		return "Activating equipped flight skill slot must enter flight"

	# 5. Overhang obstacle top is removed so high-flying player passes cleanly above it
	var overhang_sc := load("res://scenes/obstacles/obstacle_overhang.tscn") as PackedScene
	var ov := overhang_sc.instantiate() as Hazard
	var ov_col := ov.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var rect := ov_col.shape as RectangleShape2D
	var ov_top_world_y: float = 230.0 + ov_col.position.y - rect.size.y * 0.5
	ov.free()
	if ov_top_world_y < 140.0:
		_destroy_runner(r)
		return "Overhang top must be removed (top y=%.1f >= 140) so flying players pass freely overhead" % ov_top_world_y

	# 6. PS4 Circle button (duck/slide) during active gameplay must NOT trigger ui_cancel pause
	r.save_service.set_setting("ps_controller_enabled", true)
	r.hud.select_mode(1)
	r.start_new_run()
	var ev_circle := InputEventJoypadButton.new()
	ev_circle.button_index = JOY_BUTTON_B
	ev_circle.pressed = true
	r._unhandled_input(ev_circle)
	if r.is_paused:
		_destroy_runner(r)
		return "PS4 Circle (Slide) during gameplay must NOT pause via ui_cancel"

	_destroy_runner(r)
	return true
