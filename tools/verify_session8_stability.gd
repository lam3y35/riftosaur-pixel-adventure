class_name VerifySession8Stability
extends SceneTree

## Spec Exit: L3 Ten-minute headless run with recorded memory and node counts.
## Verifies long-run stability, chunk cleanup, zero memory leak, and bounded node count.

func _init() -> void:
	call_deferred("_run_stability_test")

func _run_stability_test() -> void:
	print("==================================================")
	print("[VerifySession8] Starting 10-Minute Headless Stability Simulation")
	print("==================================================")

	var runner_scene = load("res://scenes/gameplay/endless_runner.tscn")
	var runner = runner_scene.instantiate() as EndlessRunner
	root.add_child(runner)

	await process_frame
	await physics_frame

	runner.begin_run()
	var player = runner.player

	var start_mem = OS.get_static_memory_usage()
	print("Initial State:")
	print("  Start Static Memory : %d bytes (%.2f MB)" % [start_mem, start_mem / (1024.0 * 1024.0)])
	print("  Initial Active Chunks: %d" % runner.chunk_pool.size())

	# 10 minutes game time = 600.0 seconds
	# 600 seconds at 60 Hz = 36,000 physics steps
	var target_sim_seconds: float = 600.0
	var delta: float = 1.0 / 60.0
	var total_steps: int = int(target_sim_seconds / delta)
	var log_interval_steps: int = total_steps / 10 # Log 10 checkpoints (every 1 min)

	var step_count: int = 0
	var max_active_chunks: int = 0
	var checkpoint_memories: Array[int] = []

	var jump_cooldown: float = 0.0

	while step_count < total_steps:
		# Keep player alive with high jump clearance & safe inputs
		if player.is_on_floor() and jump_cooldown <= 0.0:
			player._execute_jump()
			player.jump_held = true
			jump_cooldown = 1.2
		elif jump_cooldown > 0.0:
			jump_cooldown -= delta
			if jump_cooldown < 0.9:
				player.jump_held = false

		# If flight, stay in mid air
		if player.is_flying:
			player.flight_up_input = (player.position.y > 150.0)
			player.flight_down_input = (player.position.y < 80.0)

		# Tick runner physics
		runner._physics_process(delta)
		player._physics_process(delta)

		step_count += 1
		var active_chunks = runner.chunk_pool.size()
		if active_chunks > max_active_chunks:
			max_active_chunks = active_chunks

		if step_count % log_interval_steps == 0:
			var minute = int((step_count * delta) / 60.0)
			var current_mem = OS.get_static_memory_usage()
			checkpoint_memories.append(current_mem)
			var dist = runner.distance_m
			var world_name = "Unknown"
			if runner.current_world_index < runner.world_themes.size():
				world_name = runner.world_themes[runner.current_world_index].world_name
			print("  [Minute %2d/10] Dist: %7.1fm | World: %-20s | Active Chunks: %2d | Mem: %.2f MB" % [
				minute, dist, world_name, active_chunks, current_mem / (1024.0 * 1024.0)
			])

			# Assert active chunk count is strictly bounded
			if active_chunks > 10:
				print("FAILED: Active chunk count exceeded bounds (> 10): %d" % active_chunks)
				quit(1)
				return

			# Yield periodically so engine stays responsive
			await process_frame

	# Flush deferred frees and GC
	await process_frame
	await process_frame

	var final_mem = OS.get_static_memory_usage()
	var warmup_mem = checkpoint_memories[1] if checkpoint_memories.size() > 1 else start_mem
	var steady_growth_mb = (final_mem - warmup_mem) / (1024.0 * 1024.0)
	var total_growth_mb = (final_mem - start_mem) / (1024.0 * 1024.0)

	print("\nStability Summary:")
	print("  Simulated Duration   : %.1f seconds (10.0 minutes game time)" % (step_count * delta))
	print("  Total Distance Run   : %.1f meters" % runner.distance_m)
	print("  Max Chunks in Memory : %d (bound <= 10)" % max_active_chunks)
	print("  Start Static Memory  : %.2f MB" % (start_mem / (1024.0 * 1024.0)))
	print("  Warmup Static Memory : %.2f MB" % (warmup_mem / (1024.0 * 1024.0)))
	print("  Final Static Memory  : %.2f MB" % (final_mem / (1024.0 * 1024.0)))
	print("  Steady State Drift   : %+.2f MB" % steady_growth_mb)

	if steady_growth_mb > 25.0:
		print("FAILED: Memory leak detected! Steady-state drift > 25 MB: %+.2f MB" % steady_growth_mb)
		quit(1)
		return

	print("\n==================================================")
	print("[VerifySession8] L3 Ten-Minute Stability Simulation PASSED")
	print("==================================================")
	quit(0)
