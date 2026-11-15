class_name TestV2ImprovementsAndSecurity
extends RefCounted

const RunnerScene = preload("res://scenes/gameplay/endless_runner.tscn")
const BoomerangScript = preload("res://scripts/objects/boomerang_projectile.gd")

func get_test_name() -> String:
	return "V2ImprovementsAndSecurityTest"

func _clean_save_files() -> void:
	for path in [SaveService.SAVE_PATH, SaveService.TEMP_PATH, SaveService.BACKUP_PATH, SaveService.CORRUPT_BACKUP_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)

func test_save_negative_and_zero_point_abuse_blocked() -> Variant:
	_clean_save_files()
	var save = SaveService.new()
	var initial := save.get_points()
	if save.spend_points(-500):
		_clean_save_files()
		return "Negative spend_points must fail"
	if save.spend_points(0):
		_clean_save_files()
		return "Zero spend_points must fail"
	if save.get_points() != initial:
		_clean_save_files()
		return "Points mutated after invalid spend attempt"
	save.add_points(-999)
	if save.get_points() != initial:
		_clean_save_files()
		return "Negative add_points mutated balance"
	_clean_save_files()
	return true

func test_save_canonical_skin_pricing_and_unknown_skin_blocked() -> Variant:
	_clean_save_files()
	var save = SaveService.new()
	if save.purchase_skin("nonexistent_dino"):
		_clean_save_files()
		return "Unknown skin purchase must fail"
	if save.unlock_skin("hacked_skin"):
		_clean_save_files()
		return "Unknown unlock_skin must fail"
	if save.purchase_skin("ruby"):
		_clean_save_files()
		return "Should not buy 250-pt skin with 50 welcome points"
	save.add_points(250) # 50 + 250 = 300
	if not save.purchase_skin("ruby"):
		_clean_save_files()
		return "Expected ruby skin purchase to succeed at 300 pts"
	if save.get_points() != 50 or save.get_equipped_skin() != "ruby":
		_clean_save_files()
		return "Unexpected points (%d) or equipped skin (%s)" % [save.get_points(), save.get_equipped_skin()]
	_clean_save_files()
	return true

func test_save_hmac_envelope_and_tamper_rejection() -> Variant:
	_clean_save_files()
	var save = SaveService.new()
	save.add_points(400)
	var f = FileAccess.open(SaveService.SAVE_PATH, FileAccess.READ)
	if f == null:
		_clean_save_files()
		return "Expected saved file on disk"
	var raw_text = f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(raw_text)
	if typeof(parsed) != TYPE_DICTIONARY or parsed.get("alg", "") != SaveService.SAVE_ENVELOPE_ALG:
		_clean_save_files()
		return "Expected HMAC-SHA256 envelope on disk"

	# Tamper payload without updating HMAC signature
	var tampered_payload: String = str(parsed["payload"]).replace("450", "999999")
	parsed["payload"] = tampered_payload
	var wf = FileAccess.open(SaveService.SAVE_PATH, FileAccess.WRITE)
	wf.store_string(JSON.stringify(parsed))
	wf.close()

	var reloaded = SaveService.new()
	if reloaded.get_points() != 50:
		_clean_save_files()
		return "Tampered save must reset to safe defaults (got %d pts)" % reloaded.get_points()

	# Malformed types inside migrate_data must never crash
	var sanitized = reloaded.migrate_data({
		"version": 1,
		"best_score": ["not", "an", "int"],
		"best_distance": NAN,
		"points": null,
		"settings": "corrupt_string",
		"completed_challenges": ["../evil", "jump_5", 123]
	})
	if int(sanitized["best_score"]) != 0 or float(sanitized["best_distance"]) != 0.0:
		_clean_save_files()
		return "Expected malformed numeric types to sanitize cleanly"
	if not sanitized["completed_challenges"].has("jump_5") or sanitized["completed_challenges"].has("../evil"):
		_clean_save_files()
		return "Expected valid challenge kept and unsafe challenge rejected"
	_clean_save_files()
	return true

func test_input_replay_whitelist_and_monotonic_guard() -> Variant:
	var replay = InputReplaySystem.new()
	replay.start_recording()
	replay.record_action("cheat_win", true, 10)
	replay.record_action("jump", true, 100)
	replay.record_action("slide", true, 50) # Out of order -> ignored
	var recorded := replay.stop_recording()
	if recorded.size() != 1 or recorded[0]["action"] != "jump":
		return "Expected only valid monotonic 'jump' action recorded, got %s" % str(recorded)

	# Mutating returned copy must not mutate internal events
	recorded[0]["action"] = "mutated"
	if replay.recorded_events[0]["action"] != "jump":
		return "stop_recording must return deep copy"

	replay.start_replaying([
		{"time_ms": 10, "action": "bad_action", "pressed": true},
		{"time_ms": -5, "action": "jump", "pressed": true},
		{"time_ms": 20, "action": "jump", "pressed": true},
		{"time_ms": 15, "action": "slide", "pressed": true}
	], 0)
	if replay.recorded_events.size() != 1 or replay.recorded_events[0]["time_ms"] != 20:
		return "start_replaying must filter invalid/non-monotonic events"
	return true

func test_level_generator_mode0_and_flight_filtering() -> Variant:
	var lg = LevelGenerator.new()
	lg.set_seed(424242)
	for _i in range(25):
		var p: LevelPattern = lg.select_next_pattern(150.0, 260.0, "plains", ["jump", "flight", "bounce"], false)
		if p == null:
			return "Mode 0 generator returned null pattern"
		if p.required_movement.has("slide"):
			return "Mode 0 (no slide) must never select slide pattern: %s" % p.pattern_id

	for _i in range(25):
		var pf: LevelPattern = lg.select_next_pattern(450.0, 360.0, "jungle", [], true)
		if pf == null:
			return "Flight generator returned null pattern"
		if pf.required_movement.has("slide") or pf.pattern_id.contains("arch"):
			return "Flight avoidance must exclude overhang/slide patterns: %s" % pf.pattern_id

	# Verify Practice speed (196 px/s) matches multiple obstacle chunks early
	var seen_ids: Dictionary = {}
	for _i in range(25):
		var pp: LevelPattern = lg.select_next_pattern(50.0, 196.0, "plains", [], false)
		if pp != null:
			seen_ids[pp.pattern_id] = true
	if seen_ids.size() < 2:
		return "Expected varied patterns at Practice speed 196 px/s, got %s" % str(seen_ids.keys())
	return true

func test_boomerang_targets_hazards_and_tracks_player() -> Variant:
	var tree = Engine.get_main_loop() as SceneTree
	var dummy_player = Node2D.new()
	dummy_player.position = Vector2(100.0, 200.0)
	tree.root.add_child(dummy_player)

	var boom = BoomerangScript.new()
	boom.position = Vector2(115.0, 190.0)
	boom.origin_player = dummy_player
	tree.root.add_child(boom)

	if boom.collision_layer != 0 or boom.collision_mask != 4:
		dummy_player.free()
		boom.free()
		return "Boomerang must have layer=0 mask=4 (Hazards), got layer=%d mask=%d" % [boom.collision_layer, boom.collision_mask]

	for _step in range(18):
		dummy_player.position.x += 520.0 * 0.05
		boom._physics_process(0.05)

	if not boom.returning:
		dummy_player.free()
		boom.free()
		return "Expected boomerang to reach apex and enter returning phase relative to moving player"

	dummy_player.free()
	if is_instance_valid(boom):
		boom.free()
	return true

func test_hud_skill_button_single_emit_and_practice_mode() -> Variant:
	var tree = Engine.get_main_loop() as SceneTree
	var runner = RunnerScene.instantiate() as EndlessRunner
	tree.root.add_child(runner)

	var hits := [0]
	runner.hud.skill_requested.connect(func(): hits[0] += 1)
	if runner.hud.skill_button:
		runner.hud.skill_button.button_down.emit()
		runner.hud.skill_button.pressed.emit()
	if hits[0] != 1:
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Skill button should emit once per press, got %d" % hits[0]

	runner.hud.select_mode(3)
	if not runner.hud.mode_desc_label.text.contains("Practice"):
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Practice mode description missing"
	if not runner.hud.slide_button.visible:
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Practice mode should keep slide button visible"

	runner.get_parent().remove_child(runner)
	runner.free()
	return true

func test_gameplay_near_miss_combo_fever_and_biome_modifiers() -> Variant:
	var tree = Engine.get_main_loop() as SceneTree
	var runner = RunnerScene.instantiate() as EndlessRunner
	tree.root.add_child(runner)
	runner.begin_run()

	if runner.fx_manager == null:
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Expected fx_manager to be initialized"

	var fake_haz = Hazard.new()
	fake_haz.add_to_group("hazards")
	fake_haz.position = runner.player.global_position - Vector2(24.0, 0.0)
	runner.add_child(fake_haz)
	runner.player.invulnerability_timer = 0.0

	runner._check_near_misses()
	if runner.near_misses_this_run != 1 or runner.combo_count != 1:
		var m: int = int(runner.near_misses_this_run)
		var c: int = int(runner.combo_count)
		var px: float = float(runner.player.global_position.x)
		var py: float = float(runner.player.global_position.y)
		var hx: float = float(fake_haz.global_position.x)
		var hy: float = float(fake_haz.global_position.y)
		var inv: float = float(runner.player.invulnerability_timer)
		var st: int = int(runner.player.state_machine.current_state)
		var hcnt: int = runner.get_tree().get_nodes_in_group("hazards").size()
		var nma: bool = bool(fake_haz._near_miss_awarded)
		fake_haz.free()
		runner.get_parent().remove_child(runner)
		runner.free()
		return "misses=%d combo=%d px=%.1f py=%.1f hx=%.1f hy=%.1f inv=%.2f st=%d hcnt=%d nma=%s" % [m, c, px, py, hx, hy, inv, st, hcnt, str(nma)]

	for _i in range(14):
		runner._bump_combo(runner.player.global_position)

	if not runner.is_fever_active or runner.combo_multiplier != 5:
		fake_haz.free()
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Expected 15-hit combo to activate FEVER x5 (got combo=%d fever=%s mult=%d)" % [runner.combo_count, str(runner.is_fever_active), runner.combo_multiplier]

	runner.current_world_index = 2
	runner._apply_biome_modifier()
	var ice_boost: float = runner.player.icy_slide_boost

	fake_haz.free()
	runner.get_parent().remove_child(runner)
	runner.free()

	if ice_boost <= 1.0:
		return "Expected SLIPPERY_SURFACES in Ice Cave to boost icy_slide_boost > 1.0, got %.2f" % ice_boost
	return true

func test_skill_manager_guards_and_passive_shield() -> Variant:
	var tree = Engine.get_main_loop() as SceneTree
	var runner = RunnerScene.instantiate() as EndlessRunner
	tree.root.add_child(runner)

	var sm = runner.player.skill_manager
	sm.equip_skill(SkillManager.SkillType.STONE_SHIELD)
	if sm.can_activate():
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Passive STONE_SHIELD must not be manually activated/wasted on tap"

	sm.equip_skill(SkillManager.SkillType.BONE_BLADE)
	runner.player.is_flying = true
	if sm.can_activate():
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Skills must not activate while flying"

	runner.player.is_flying = false
	if not sm.activate():
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Expected BONE_BLADE activation to succeed when grounded"
	if sm.current_charges != 0:
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Expected BONE_BLADE 1 charge spent, got %d" % sm.current_charges

	# Step cooldown to completion -> should auto-clear NONE
	for _i in range(40):
		sm.update(0.05)
	if sm.current_skill != SkillManager.SkillType.NONE:
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Expected spent single-charge skill to auto-clear to NONE after cooldown"

	runner.get_parent().remove_child(runner)
	runner.free()
	return true

# End of V2 & Security tests

func test_flight_floor_tap_and_hold_cleanup() -> Variant:
	var tree = Engine.get_main_loop() as SceneTree
	var runner = RunnerScene.instantiate() as EndlessRunner
	tree.root.add_child(runner)
	runner.begin_run()

	runner.player.jump_held = true
	runner.player.is_jump_holding = true
	runner.player.start_flight(1, 5.0)
	if runner.player.jump_held or runner.player.slide_held:
		runner.get_parent().remove_child(runner)
		runner.free()
		return "start_flight must clear jump_held and slide_held"

	# Simulate floor contact during flight + touch/jump input
	runner.hud.show_flight_hud(1, 5.0)
	runner.hud._handle_touch_down(0, Vector2(300.0, 180.0))
	runner._on_hud_jump(true)
	var valid_state: bool = bool(runner.player.is_flying) and runner.player.state_machine.current_state == PlayerStateMachine.State.FLIGHT
	runner.get_parent().remove_child(runner)
	runner.free()
	if not valid_state:
		return "Touch or jump input during flight must not corrupt FLIGHT state"
	return true

func test_hud_combo_non_overlap_and_dev_overlay_toggle() -> Variant:
	var tree = Engine.get_main_loop() as SceneTree
	var runner = RunnerScene.instantiate() as EndlessRunner
	tree.root.add_child(runner)
	runner.begin_run()

	runner.hud.update_combo(5, 2, false, 0.8)
	runner.hud.show_flight_hud(1, 5.0)
	var combo_r: Rect2 = runner.hud.combo_panel.get_rect()
	var flight_r: Rect2 = runner.hud.flight_timer_bar.get_rect()
	runner.hud.hide_flight_hud()
	var blockers: Array = [
		runner.hud.pause_button,
		runner.hud.skill_slot,
		runner.hud.world_label,
		runner.hud.distance_label,
		runner.hud.score_label,
		runner.hud.best_label,
		runner.hud.points_label,
		runner.hud.gems_label,
		runner.hud.seed_label,
		runner.hud.flight_timer_bar
	]
	for ctrl in blockers:
		if ctrl and combo_r.intersects(ctrl.get_rect()):
			var bname: String = str(ctrl.name)
			var brect: Rect2 = ctrl.get_rect()
			runner.get_parent().remove_child(runner)
			runner.free()
			return "ComboPanel %s must not overlap %s %s" % [str(combo_r), bname, str(brect)]

	var flight_blockers: Array = [
		runner.hud.skill_slot,
		runner.hud.world_label,
		runner.hud.distance_label,
		runner.hud.seed_label,
		runner.hud.skill_toast,
		runner.hud.dev_overlay
	]
	for ctrl in flight_blockers:
		if ctrl and flight_r.intersects(ctrl.get_rect()):
			var bname: String = str(ctrl.name)
			var brect: Rect2 = ctrl.get_rect()
			runner.get_parent().remove_child(runner)
			runner.free()
			return "FlightTimerBar %s must not overlap %s %s" % [str(flight_r), bname, str(brect)]

	runner.hud.select_mode(0)
	var hint_spicy: String = runner.hud.controls_hint.text if runner.hud.controls_hint else ""
	runner.hud.select_mode(1)
	runner.hud.apply_control_layout(true)
	var hint_lh: String = runner.hud.controls_hint.text if runner.hud.controls_hint else ""
	runner.hud.apply_control_layout(false)
	var has_settings_scroll: bool = runner.hud.settings_scroll != null and runner.hud.settings_music_btn != null
	var combo_right_anchored: bool = is_equal_approx(runner.hud.combo_panel.anchor_left, 1.0) and is_equal_approx(runner.hud.combo_panel.anchor_right, 1.0)
	var has_subground: bool = runner.parallax_bg != null and runner.parallax_bg._subground_fill != null

	runner.save_service.set_setting("dev_overlay", true)
	runner.hud.refresh_accessibility_visuals()
	var dev_vis: bool = runner.hud.dev_overlay.visible
	var dev_r: Rect2 = runner.hud.dev_overlay.get_rect()
	var toast_r: Rect2 = runner.hud.skill_toast.get_rect()
	runner.save_service.set_setting("dev_overlay", false)
	runner.hud.refresh_accessibility_visuals()

	runner.get_parent().remove_child(runner)
	runner.free()
	if not dev_vis:
		return "Enabling dev_overlay setting must make hud.dev_overlay visible"
	if dev_r.intersects(toast_r):
		return "DevOverlay %s must not overlap SkillToast %s" % [str(dev_r), str(toast_r)]
	if not has_settings_scroll:
		return "Expected SettingsScroll and dynamic volume buttons inside SettingsDialog"
	if not combo_right_anchored:
		return "ComboPanel must anchor to right edge (1.0) for ultrawide displays"
	if not has_subground:
		return "ParallaxController must initialize SubGroundFill for 4:3 displays"
	if not hint_spicy.contains("NO SLIDE") or (not hint_lh.contains("SLIDE")):
		return "Expected ControlsHint to dynamically update for Spicy ('%s') and Mode 1 ('%s')" % [hint_spicy, hint_lh]
	return true

func test_career_mastery_summary_matches_unlocked() -> Variant:
	_clean_save_files()
	var tree = Engine.get_main_loop() as SceneTree
	var runner = RunnerScene.instantiate() as EndlessRunner
	tree.root.add_child(runner)
	runner.save_service.data = runner.save_service.get_default_data()
	runner.save_service.complete_mastery_challenge("mastery_combo_10", 75)
	runner.save_service.complete_mastery_challenge("mastery_world_4", 150)
	runner.hud.open_challenges()
	var txt: String = runner.hud.career_summary_label.text if runner.hud.career_summary_label else ""
	runner.hud.close_challenges()
	runner.get_parent().remove_child(runner)
	runner.free()
	_clean_save_files()
	if not txt.contains("MASTERY: 2/4"):
		return "Expected CareerSummaryLabel to show MASTERY: 2/4, got '%s'" % txt
	return true

func test_practice_speed_950m_never_starves_to_breather() -> Variant:
	var lg = LevelGenerator.new()
	lg.set_seed(777111)
	var non_breather_count := 0
	for _i in range(25):
		var p: LevelPattern = lg.select_next_pattern(950.0, 320.0, "plains", [], false)
		if p == null:
			return "Practice generator at 950m returned null"
		if p.pattern_id != "p01_safe_breather":
			non_breather_count += 1
	if non_breather_count < 10:
		return "Practice mode (320 px/s) at 950m starved into safe breathers (%d/25 non-breather)" % non_breather_count
	return true

func test_parallax_tween_cancelled_on_immediate_reset() -> Variant:
	var tree = Engine.get_main_loop() as SceneTree
	var runner = RunnerScene.instantiate() as EndlessRunner
	tree.root.add_child(runner)
	var bg = runner.parallax_bg
	var theme0 = runner.world_themes[0]
	var theme1 = runner.world_themes[1]
	bg.transition_to_theme(theme1, 1.5)
	var had_tween: bool = bg._transition_tween != null
	bg.apply_theme_immediate(theme0)
	var after_tween = bg._transition_tween
	runner.get_parent().remove_child(runner)
	runner.free()
	if not had_tween or after_tween != null:
		return "Expected transition_to_theme to track tween and apply_theme_immediate to cancel it"
	return true

func test_type_confusion_version_null_and_replay_time_null() -> Variant:
	_clean_save_files()
	var save = SaveService.new()
	var migrated = save.migrate_data({"version": null, "best_score": 0})
	if int(migrated["version"]) != SaveService.CURRENT_VERSION:
		_clean_save_files()
		return "migrate_data failed to recover when version is null"

	var replay = InputReplaySystem.new()
	replay.start_replaying([
		{"time_ms": null, "action": "jump", "pressed": true},
		{"time_ms": ["bad"], "action": "slide", "pressed": true},
		{"time_ms": 50, "action": "jump", "pressed": true}
	], 0)
	if replay.recorded_events.size() != 1 or replay.recorded_events[0]["time_ms"] != 50:
		_clean_save_files()
		return "Expected null/array time_ms entries rejected safely"
	_clean_save_files()
	return true

func test_lava_pit_and_biome_exclusive_chunks() -> Variant:
	var lava_scene = load("res://scenes/obstacles/hazard_lava_pit.tscn") as PackedScene
	if lava_scene == null:
		return "Failed to load hazard_lava_pit.tscn"
	var lava = lava_scene.instantiate() as Hazard
	if lava == null or lava.category != Hazard.Category.ENVIRONMENTAL:
		if lava:
			lava.free()
		return "Expected hazard_lava_pit to be an ENVIRONMENTAL Hazard"
	lava.free()

	var lg = LevelGenerator.new()
	lg.set_seed(12345)
	for wid in ["plains", "jungle", "frozen", "volcanic"]:
		var found_exclusive := false
		for pat in lg.patterns:
			if pat.world_ids.size() == 1 and pat.world_ids[0] == wid:
				found_exclusive = true
				break
		if not found_exclusive:
			return "Missing biome-exclusive LevelPattern for world '%s'" % wid
	return true

func test_safe_area_swipe_slide_overhang_near_miss_and_strata() -> Variant:
	var tree = Engine.get_main_loop() as SceneTree
	var runner = RunnerScene.instantiate() as EndlessRunner
	tree.root.add_child(runner)
	runner.begin_run()

	var insets: Dictionary = runner.hud._get_safe_area_insets()
	if not (insets.has("left") and insets.has("top") and insets.has("right") and insets.has("bottom")):
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Safe-area insets dictionary missing required keys"

	var has_strata: bool = runner.parallax_bg != null and runner.parallax_bg._subground_strata != null
	if not has_strata:
		runner.get_parent().remove_child(runner)
		runner.free()
		return "ParallaxController must initialize textured _subground_strata for tall/4:3 displays"

	# Touch swipe-down on jump finger must release jump and initiate slide
	var slide_emitted := [false]
	runner.hud.slide_requested.connect(func(p: bool): if p: slide_emitted[0] = true)
	runner.hud._handle_touch_down(0, Vector2(360.0, 150.0))
	runner.hud._handle_touch_drag(0, Vector2(360.0, 190.0))
	if not slide_emitted[0] or runner.hud.jump_touch_index != -1 or runner.hud.slide_touch_index != 0:
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Swipe down from jump touch did not transition cleanly into slide"

	# Sliding under Cave Overhang Barrier must award near-miss + combo
	var overhang_scene = load("res://scenes/obstacles/obstacle_overhang.tscn") as PackedScene
	var overhang = overhang_scene.instantiate() as Hazard
	runner.add_child(overhang)
	overhang.global_position = Vector2(runner.player.global_position.x - 10.0, runner.player.global_position.y)
	runner.player.invulnerability_timer = 0.0
	runner.player.state_machine.change_state(PlayerStateMachine.State.SLIDE)
	runner._check_near_misses()
	var nm_count: int = runner.near_misses_this_run
	overhang.free()

	runner.get_parent().remove_child(runner)
	runner.free()
	if nm_count != 1:
		return "Expected 1 overhang slide near-miss bonus, got %d" % nm_count
	return true

func test_round5_parallax_full_fade_practice_shield_skill_btn_and_audio_unmute() -> Variant:
	var tree = Engine.get_main_loop() as SceneTree
	var runner = RunnerScene.instantiate() as EndlessRunner
	tree.root.add_child(runner)

	# 1. Practice mode Stone Shield must save from SOLID obstacle without dying and grant invulnerability
	runner.hud.select_mode(3)
	runner.current_mode = 3
	runner.begin_run()
	if not runner.player.practice_shield_enabled or not runner.player.skill_manager.has_shield:
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Practice mode did not enable forgiving practice shield"
	# Passive STONE_SHIELD should show SHIELD slot badge and hide active tap SkillButton
	if not runner.hud.skill_slot.visible or runner.hud.skill_label.text != "SHIELD":
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Practice Stone Shield HUD slot should display 'SHIELD'"
	if runner.hud.skill_button and runner.hud.skill_button.visible:
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Passive/empty SkillButton should stay hidden until an active skill is equipped"

	var cactus_scene = load("res://scenes/obstacles/obstacle_ground_low.tscn") as PackedScene
	var cactus = cactus_scene.instantiate() as Hazard
	if cactus == null or cactus.category != Hazard.Category.SOLID:
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Failed to instantiate SOLID obstacle_ground_low.tscn for Practice shield test"
	runner.player.invulnerability_timer = 0.0
	runner.player.hit_hazard("Cactus test", false, cactus)
	var survived_practice_solid: bool = runner.player.state_machine.current_state != PlayerStateMachine.State.DEAD and not runner.player.skill_manager.has_shield and runner.player.invulnerability_timer > 0.0
	if is_instance_valid(cactus):
		cactus.free()
	if not survived_practice_solid:
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Practice mode Shielded Start failed to absorb SOLID cactus hit cleanly"
	if runner.hud.skill_slot.visible:
		runner.get_parent().remove_child(runner)
		runner.free()
		return "SkillSlot should hide automatically once Stone Shield breaks"

	# Active skill equips SkillButton visibly
	runner.player.skill_manager.equip_skill(SkillManager.SkillType.AIR_DASH)
	if runner.hud.skill_button == null or not runner.hud.skill_button.visible:
		runner.get_parent().remove_child(runner)
		runner.free()
		return "SkillButton should become visible when active skill (AIR_DASH) is equipped"

	# 2. Parallax transition_to_theme must NOT kill itself at midpoint callback; must reach target tint & alpha=1.0
	var jungle_theme = load("res://resources/themes/theme_02_jungle.tres") as WorldTheme
	runner.parallax_bg.transition_to_theme(jungle_theme, 0.2)
	var tw: Tween = runner.parallax_bg._transition_tween
	if tw == null or not tw.is_valid():
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Parallax transition tween failed to initialize"
	tw.custom_step(0.09) # Crosses midpoint callback
	if not tw.is_valid() and (runner.parallax_bg.sky_sprite.modulate != jungle_theme.ambient_tint):
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Parallax transition killed itself during midpoint callback!"
	tw.custom_step(0.25) # Finishes phase 2 fade-in
	var final_sky: Color = runner.parallax_bg.sky_sprite.modulate
	var final_mtn_a: float = runner.parallax_bg.mountains_sprite.modulate.a
	if absf(final_sky.r - jungle_theme.ambient_tint.r) > 0.02 or absf(final_sky.g - jungle_theme.ambient_tint.g) > 0.02 or absf(final_sky.a - 1.0) > 0.01 or absf(final_mtn_a - jungle_theme.ambient_tint.a) > 0.02:
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Parallax transition failed to restore sky tint/alpha cleanly after fade: sky=%s mtn_a=%.2f" % [str(final_sky), final_mtn_a]

	# 3. Unmuting music mid-run must resume/start playback in refresh_volumes()
	runner.save_service.set_setting("sound_enabled", false)
	runner.audio_manager.stop_music()
	runner.audio_manager.play_music("run")
	runner.save_service.set_setting("sound_enabled", true)
	runner.audio_manager.refresh_volumes()
	var music_playing: bool = runner.audio_manager.bgm_player != null and runner.audio_manager.bgm_player.playing
	runner.audio_manager.stop_music()

	runner.get_parent().remove_child(runner)
	runner.free()
	if not music_playing:
		return "AudioManager.refresh_volumes() did not start BGM playback when unmuted mid-run"
	return true
