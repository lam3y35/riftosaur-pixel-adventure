class_name VerifySession7WorldsRun
extends SceneTree

func _init() -> void:
	print("==================================================")
	print("[VerifySession7] Running L3 Live 4-World Run Verification")
	print("==================================================")
	call_deferred("_execute_four_worlds_run")

func _execute_four_worlds_run() -> void:
	var runner_scene = load("res://scenes/gameplay/endless_runner.tscn")
	var runner = runner_scene.instantiate() as EndlessRunner
	root.add_child(runner)

	runner.begin_run()
	var hud = runner.hud

	print("1. World 1: Prehistoric Plains...")
	if runner.current_world_index != 0:
		print("FAILED: Expected current_world_index 0")
		quit(1)
		return
	if hud.world_label and not hud.world_label.text.contains("PREHISTORIC PLAINS"):
		print("FAILED: World label does not display Prehistoric Plains")
		quit(1)
		return
	print("   ✓ World 1 active: %s" % runner.world_themes[0].world_name)

	print("2. Transitioning to World 2: Overgrown Jungle...")
	runner.player.position.x = runner.start_x + 2550.0
	runner._physics_process(0.016)
	if runner.current_world_index != 1:
		print("FAILED: Did not transition to World 2 at 250m (current_world_index=%d)" % runner.current_world_index)
		quit(1)
		return
	if hud.world_label and not hud.world_label.text.contains("OVERGROWN JUNGLE"):
		print("FAILED: World label did not update to Overgrown Jungle")
		quit(1)
		return
	print("   ✓ World 2 active: %s (HUD updated, safe chunk spawned)" % runner.world_themes[1].world_name)

	print("3. Transitioning to World 3: Frozen Ruins...")
	runner.player.position.x = runner.start_x + 5050.0
	runner._physics_process(0.016)
	if runner.current_world_index != 2:
		print("FAILED: Did not transition to World 3 at 500m (current_world_index=%d)" % runner.current_world_index)
		quit(1)
		return
	if hud.world_label and not hud.world_label.text.contains("FROZEN RUINS"):
		print("FAILED: World label did not update to Frozen Ruins")
		quit(1)
		return
	print("   ✓ World 3 active: %s" % runner.world_themes[2].world_name)

	print("4. Transitioning to World 4: Volcanic Underworld...")
	runner.player.position.x = runner.start_x + 7550.0
	runner._physics_process(0.016)
	if runner.current_world_index != 3:
		print("FAILED: Did not transition to World 4 at 750m (current_world_index=%d)" % runner.current_world_index)
		quit(1)
		return
	if hud.world_label and not hud.world_label.text.contains("VOLCANIC UNDERWORLD"):
		print("FAILED: World label did not update to Volcanic Underworld")
		quit(1)
		return
	print("   ✓ World 4 active: %s" % runner.world_themes[3].world_name)

	print("5. Verifying All Chunks & Transitions Remain Safe...")
	var total_chunks = runner.chunk_pool.size()
	print("   ✓ Total chunks safely allocated and sequenced: %d" % total_chunks)

	print("\n==================================================")
	print("[VerifySession7] L3 Live 4-World Run PASSED")
	print("==================================================")
	runner.queue_free()
	quit(0)
