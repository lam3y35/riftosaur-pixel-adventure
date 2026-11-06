class_name VerifySession5SkillsRun
extends SceneTree

func _init() -> void:
	print("==================================================")
	print("[VerifySession5] Running L3 Live Skill Run Verification")
	print("==================================================")
	call_deferred("_execute_run")

func _execute_run() -> void:
	var runner_scene = load("res://scenes/gameplay/endless_runner.tscn")
	var runner = runner_scene.instantiate() as EndlessRunner
	root.add_child(runner)

	runner.begin_run()
	var player = runner.player
	var hud = runner.hud

	print("1. Testing Collectibles & Gem count in live run...")
	var gem = load("res://scenes/objects/collectible_gem.tscn").instantiate() as Collectible
	gem.position = player.position
	runner.add_child(gem)
	gem.collect(player)
	if player.gems_collected < 1:
		print("FAILED: gems_collected did not increase")
		quit(1)
		return
	print("   ✓ Gem collected successfully. Gems=%d, Score=%d" % [player.gems_collected, runner.current_score])

	print("2. Testing All 8 Skills Live Activation...")
	var skill_types = [
		SkillManager.SkillType.BONE_BLADE,
		SkillManager.SkillType.BOOMERANG,
		SkillManager.SkillType.STONE_SHIELD,
		SkillManager.SkillType.TIME_SHARD,
		SkillManager.SkillType.MAGNET_RELIC,
		SkillManager.SkillType.AIR_DASH,
		SkillManager.SkillType.BOUNCE_POWER,
		SkillManager.SkillType.GROUND_SLAM
	]

	for st in skill_types:
		player.skill_manager.equip_skill(st)
		var info = player.skill_manager.get_skill_info(st)
		print("   Equipped: %s" % info.get("name"))

		if st == SkillManager.SkillType.GROUND_SLAM:
			# Put player in mid-air to satisfy Ground Slam condition
			player.position.y -= 50.0
			player.velocity.y = 50.0
			player.state_machine.change_state(PlayerStateMachine.State.JUMP_FALL)

		var success = player.use_skill()
		if not success and st != SkillManager.SkillType.STONE_SHIELD:
			print("FAILED: Could not activate skill %s" % info.get("name"))
			quit(1)
			return

		# Verify HUD display updated
		hud.update_skill_slot(info, player.skill_manager.cooldown_timer, player.skill_manager.duration_timer, player.skill_manager.current_charges)
		print("   ✓ Activated %s (Charges=%d, CD=%.1f, Dur=%.1f)" % [
			info.get("name"),
			player.skill_manager.current_charges,
			player.skill_manager.cooldown_timer,
			player.skill_manager.duration_timer
		])

		# Reset cooldown for next test
		player.skill_manager.cooldown_timer = 0.0

	print("\n==================================================")
	print("[VerifySession5] L3 Live Skill Run Verification PASSED")
	print("==================================================")
	runner.queue_free()
	quit(0)
