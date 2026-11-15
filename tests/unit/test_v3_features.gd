class_name TestV3Features
extends RefCounted

const RunnerScene = preload("res://scenes/gameplay/endless_runner.tscn")
const SaveService = preload("res://scripts/systems/save_service.gd")
const ChallengeService = preload("res://scripts/systems/challenge_service.gd")

func get_test_name() -> String:
	return "V3MultiSkillSkinsAndLevelingTest"

func test_multi_skill_3_slots_and_hud_buttons() -> Variant:
	var tree = Engine.get_main_loop() as SceneTree
	var runner = RunnerScene.instantiate() as EndlessRunner
	tree.root.add_child(runner)
	runner.start_new_run()
	runner.is_game_started = true

	var sm: SkillManager = runner.player.skill_manager
	sm.equip_skill(SkillManager.SkillType.BONE_BLADE)
	sm.equip_skill(SkillManager.SkillType.STONE_SHIELD)
	sm.equip_skill(SkillManager.SkillType.MAGNET_RELIC)

	if sm.get_equipped_count() != 3:
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Expected 3 simultaneous skills equipped, got %d" % sm.get_equipped_count()

	for i in range(3):
		if i >= runner.hud.skill_slot_buttons.size() or not runner.hud.skill_slot_buttons[i].visible:
			runner.get_parent().remove_child(runner)
			runner.free()
			return "Expected HUD skill button %d to be visible when 3 skills are equipped" % i

	# Activate slot 2 (Magnet Relic) independently while slot 0 (Bone Blade) stays ready
	runner.hud.skill_slot_requested.emit(2)
	if not runner.player.is_magnet_active:
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Expected clicking slot 2 to activate Magnet Relic"
	if not sm.has_skill(SkillManager.SkillType.BONE_BLADE):
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Expected Bone Blade in slot 0 to remain equipped after activating slot 2"

	# Absorb airborne hit with Stone Shield in slot 1 -> only shield is removed
	var fake_haz := Hazard.new()
	fake_haz.category = Hazard.Category.AIRBORNE
	var absorbed: bool = sm.absorb_shield_hit(fake_haz, false)
	fake_haz.free()
	if not absorbed:
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Expected Stone Shield in slot 1 to absorb airborne hit"
	if sm.has_skill(SkillManager.SkillType.STONE_SHIELD):
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Expected Stone Shield to be consumed after absorbing hit"
	if not sm.has_skill(SkillManager.SkillType.BONE_BLADE) or not sm.has_skill(SkillManager.SkillType.MAGNET_RELIC):
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Expected remaining 2 skills to stay equipped after shield broke"

	runner.get_parent().remove_child(runner)
	runner.free()
	return true

func test_expanded_skins_cosmetics_and_perks() -> Variant:
	if SaveService.SKIN_CATALOG.size() < 16:
		return "Expected at least 16 dino skins in SKIN_CATALOG, got %d" % SaveService.SKIN_CATALOG.size()
	if GameHUD.SKINS.size() != SaveService.SKIN_CATALOG.size():
		return "HUD SKINS count (%d) does not match SaveService.SKIN_CATALOG (%d)" % [GameHUD.SKINS.size(), SaveService.SKIN_CATALOG.size()]

	for s in GameHUD.SKINS:
		var sid: String = s["id"]
		if not ResourceLoader.exists(Player.SKIN_TEXTURES.get(sid, "")):
			return "Missing dinosaur sprite sheet for skin: %s" % sid
		if not ResourceLoader.exists(s["icon"]):
			return "Missing skin icon for skin: %s" % sid

	var tree = Engine.get_main_loop() as SceneTree
	var runner = RunnerScene.instantiate() as EndlessRunner
	tree.root.add_child(runner)

	# Grant diamonds and buy top-tier skin + obstacle/map/trail cosmetics
	runner.save_service.data["points"] = 100000
	if not runner.save_service.purchase_skin("chromatic_god"):
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Failed to purchase chromatic_god skin"
	if not runner.save_service.purchase_cosmetic("obs_shadow_void"):
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Failed to purchase obs_shadow_void cosmetic"
	if not runner.save_service.purchase_cosmetic("map_golden_kingdom"):
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Failed to purchase map_golden_kingdom cosmetic"
	if not runner.save_service.purchase_cosmetic("trail_rainbow"):
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Failed to purchase trail_rainbow cosmetic"

	runner.start_new_run()
	if not runner.player.passive_magnet or not runner.player.is_magnet_active:
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Expected chromatic_god skin perk to enable passive_magnet"
	if not runner.player.skill_manager.has_shield:
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Expected chromatic_god skin perk to grant starting Stone Shield"
	if runner.player.gems_collected < 5:
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Expected chromatic_god skin perk to grant 5 starting gems"

	# Verify shop tabs switch cleanly
	runner.hud.open_skin_shop()
	runner.hud._select_shop_category("obstacle")
	runner.hud._select_shop_category("map")
	runner.hud._select_shop_category("trail")
	runner.hud.close_skin_shop()

	runner.get_parent().remove_child(runner)
	runner.free()
	return true

func test_harder_quests_and_level_up_diamonds() -> Variant:
	if ChallengeService.CHALLENGES.size() < 25:
		return "Expected at least 25 quests in ChallengeService.CHALLENGES, got %d" % ChallengeService.CHALLENGES.size()

	var save := SaveService.new()
	save.data = save.get_default_data()
	var cs := ChallengeService.new(save)

	var lv_events := [0, 0]
	cs.level_up.connect(func(nl, bonus):
		lv_events[0] = nl
		lv_events[1] += bonus
	)

	var start_pts := save.get_points()
	# Complete several quests to earn >= 100 XP and trigger level up
	cs.record_gem(40)
	cs.record_skill_used()
	cs.record_skill_used()
	cs.record_skill_used()
	cs.record_skill_used()
	cs.record_combo(12)
	cs.check_run_progress(1000.0, 1000, 1)

	if save.get_player_level() < 2 or lv_events[0] < 2:
		return "Expected completing multiple quests to level up player from Lv1 to Lv2+"
	if save.get_points() <= start_pts + lv_events[1]:
		return "Expected both quest rewards and level-up diamond bonus to be added to points"

	# Verify persistence via save/load
	save.save_game()
	var reloaded := SaveService.new()
	if reloaded.get_player_level() != save.get_player_level():
		return "Player level did not persist across save/load"

	return true

func test_controls_slide_hold_air_left_stomp_trap_and_ps4() -> Variant:
	var tree = Engine.get_main_loop() as SceneTree
	var runner = RunnerScene.instantiate() as EndlessRunner
	tree.root.add_child(runner)
	runner.start_new_run()
	runner.is_game_started = true

	# 1. Jump & Slide buttons are hidden; bottom dock is on opposite side of Jump
	if runner.hud.jump_button.visible or runner.hud.slide_button.visible:
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Jump and Slide buttons should be visually hidden"

	runner.hud.apply_control_layout(false) # Right-handed: Jump Right -> Steer/Skills Left
	if runner.hud.steer_left_btn.anchor_left != 0.0:
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Right-handed mode should place steer/skills dock on Left"

	runner.hud.apply_control_layout(true) # Left-handed: Jump Left -> Steer/Skills Right
	if runner.hud.steer_left_btn.anchor_left != 1.0:
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Left-handed mode should place steer/skills dock on Right"

	# 2. Left move only works while jumping/airborne; Right move works on ground
	var p: Player = runner.player
	p.is_steer_enabled = true
	for _i in range(15):
		p._physics_process(0.016)
	p.steer_input = -1.0
	p._physics_process(0.016)
	if p.velocity.x < p.current_speed - 1.0:
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Left move should NOT slow/move player left while on the ground"

	p.steer_input = 1.0
	p._physics_process(0.016)
	if p.velocity.x <= p.current_speed + 10.0:
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Right move should work on the ground"

	# Verify left move DOES work while airborne/jumping
	p._execute_jump()
	p.steer_input = -1.0
	for _i in range(3):
		p._physics_process(0.016)
	if p.velocity.x >= p.current_speed - 10.0:
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Left move should work while jumping/airborne"
	# Land back on ground for slide test
	p.steer_input = 0.0
	for _i in range(50):
		p._physics_process(0.016)

	# 3. Slide hold stays sliding past config.slide_duration until released
	p.steer_input = 0.0
	p.slide_held = true
	p._enter_slide()
	for _i in range(80): # > 1.2s (longer than config.slide_duration)
		p._physics_process(0.016)
	if p.state_machine.current_state != PlayerStateMachine.State.SLIDE:
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Holding slide should stay in SLIDE state until released"
	p.slide_held = false
	p._physics_process(0.016)
	if p.state_machine.current_state == PlayerStateMachine.State.SLIDE:
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Releasing slide should exit SLIDE state"

	# 4. Stomping a crawler from above / diving kills it and awards +1 gem
	var crawler_scene = load("res://scenes/obstacles/obstacle_crawler.tscn") as PackedScene
	var crawler = crawler_scene.instantiate() as Hazard
	runner.add_child(crawler)
	crawler.global_position = p.global_position + Vector2(0.0, 20.0)
	var gems_before := p.gems_collected
	p.state_machine.change_state(PlayerStateMachine.State.DIVE)
	p.velocity.y = 300.0
	crawler._on_body_entered(p)
	if not crawler.is_destroyed or p.gems_collected != gems_before + 1:
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Stomping crawler should destroy it and award +1 diamond"

	# 5. TrapPickup applies speed surge debuff
	var trap_scene = load("res://scenes/objects/trap_pickup.tscn") as PackedScene
	var trap = trap_scene.instantiate()
	runner.add_child(trap)
	p.practice_immortal = false
	trap.trigger(p)
	if p.trap_debuff_timer <= 0.0:
		runner.get_parent().remove_child(runner)
		runner.free()
		return "TrapPickup should apply trap_debuff_timer on player"

	# 6. PS4 controller mode hides all on-screen buttons and supports custom remapping
	runner.save_service.set_setting("ps_controller_enabled", true)
	runner.save_service.set_ps_binding("jump", "btn:2") # Remap Jump to Square
	runner.hud.apply_control_layout(false)
	if runner.hud.steer_left_btn.visible or runner.hud.steer_right_btn.visible:
		runner.get_parent().remove_child(runner)
		runner.free()
		return "PS4 Controller mode must hide all on-screen buttons"

	var ps_jumped := [false]
	runner.hud.jump_requested.connect(func(pr: bool): if pr: ps_jumped[0] = true)
	var jb := InputEventJoypadButton.new()
	jb.button_index = JOY_BUTTON_X # 2 = Square
	jb.pressed = true
	runner.hud._handle_ps_controller_input(jb)
	if not ps_jumped[0]:
		runner.get_parent().remove_child(runner)
		runner.free()
		return "PS4 custom remapped button should trigger jump_requested"

	runner.get_parent().remove_child(runner)
	runner.free()
	return true

func test_polish_skills_camera_parallax_settings() -> Variant:
	# 1. All 12 skills have clear tag, hint, and color; SkillPickup builds badge
	for st in SkillManager.get_all_skill_types():
		var info: Dictionary = SkillManager.SKILL_DATA.get(st, {})
		if str(info.get("short_tag", "")).is_empty() or str(info.get("when_hint", "")).is_empty():
			return "Skill %s missing short_tag or when_hint" % str(st)
		if not (info.get("color", null) is Color):
			return "Skill %s missing Color" % str(st)

	var runner_scene = load("res://scenes/gameplay/endless_runner.tscn") as PackedScene
	var runner = runner_scene.instantiate()
	var st_tree = Engine.get_main_loop() as SceneTree
	st_tree.root.add_child(runner)

	var pickup_scene = load("res://scenes/objects/skill_pickup.tscn") as PackedScene
	var pickup = pickup_scene.instantiate() as SkillPickup
	pickup.skill_type = SkillManager.SkillType.PHOENIX_WINGS
	runner.add_child(pickup)
	if pickup.get_node_or_null("SkillTagBadge") == null:
		runner.get_parent().remove_child(runner)
		runner.free()
		return "SkillPickup must attach SkillTagBadge for clear identification"

	# 2. High-jump camera keeps ground (y=230) visible on screen
	runner.player.position = Vector2(200.0, 20.0)
	for _i in range(90):
		runner.camera._physics_process(1.0 / 60.0)
	var visible_bottom: float = float(runner.camera.global_position.y) + (135.0 / float(runner.camera.zoom.y))
	if visible_bottom < 230.0:
		runner.get_parent().remove_child(runner)
		runner.free()
		return "High-jump camera cut off ground (visible_bottom=%.1f < 230.0)" % visible_bottom

	# 3. Parallax has SkyBackdrop and 1440px tiled layers
	if runner.parallax_bg.get_node_or_null("SkyBackdropLayer") == null:
		runner.get_parent().remove_child(runner)
		runner.free()
		return "ParallaxBackground missing SkyBackdropLayer"
	var sky_layer := runner.parallax_bg.get_node_or_null("SkyLayer") as ParallaxLayer
	if sky_layer == null or sky_layer.motion_mirroring.x < 1440.0:
		runner.get_parent().remove_child(runner)
		runner.free()
		return "SkyLayer must mirror >= 1440px to prevent wide-screen blue gap"

	# 4. Settings buttons have clear descriptions
	var s_list = runner.hud.settings_dialog.get_node_or_null("Panel/VBox/SettingsScroll/SettingsList")
	if s_list == null or s_list.get_node_or_null("MotionToggleBtnDesc") == null or s_list.get_node_or_null("ContrastToggleBtnDesc") == null:
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Settings dialog missing clear description labels under setting buttons"

	# 5. Smooth rendering & physics interpolation enabled
	if not bool(ProjectSettings.get_setting("physics/common/physics_interpolation")):
		runner.get_parent().remove_child(runner)
		runner.free()
		return "Physics interpolation should be enabled for smooth high-FPS motion"
	if bool(ProjectSettings.get_setting("rendering/2d/snap/snap_2d_transforms_to_pixel")):
		runner.get_parent().remove_child(runner)
		runner.free()
		return "snap_2d_transforms_to_pixel should be false to avoid 480p jitter"

	runner.get_parent().remove_child(runner)
	runner.free()
	return true
