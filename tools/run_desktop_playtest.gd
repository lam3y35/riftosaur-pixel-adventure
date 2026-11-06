class_name DesktopPlaytestRunner
extends SceneTree

const DURATION_SECONDS: float = 120.0
var elapsed: float = 0.0
var second_accum: float = 0.0
var track: TestTrack
var log_lines: Array[String] = []

func _init() -> void:
	print("==================================================")
	print("[PlaytestRunner] Starting 120-Second L3 Desktop Playtest")
	print("==================================================")
	call_deferred("_start_playtest")

func _start_playtest() -> void:
	Engine.time_scale = 4.0 # 4x fast-forward: 120s simulated in 30 real seconds
	var track_scene = preload("res://scenes/gameplay/flat_test_track.tscn")
	track = track_scene.instantiate() as TestTrack
	track.autonomous_bot = true
	root.add_child(track)
	current_scene = track

func _process(delta: float) -> bool:
	if track == null or not is_instance_valid(track.player):
		return false

	var player = track.player
	elapsed += delta
	second_accum += delta

	# Log every 1.0 simulated second
	if second_accum >= 1.0:
		second_accum -= 1.0
		var mem_mb = OS.get_static_memory_usage() / (1024.0 * 1024.0)
		var line = "[Time: %3.0fs / %3.0fs] Speed: %5.1f px/s | Dist: %6.0f px | State: %-10s | Mem: %.2f MB | FPS: %d" % [
			elapsed,
			DURATION_SECONDS,
			player.current_speed,
			player.global_position.x,
			player.state_machine.get_state_name(),
			mem_mb,
			Engine.get_frames_per_second()
		]
		print(line)
		log_lines.append(line)

		# Every 15 seconds monitor engine integrity
		if int(elapsed) % 15 == 0:
			var orphans = Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
			var node_count = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
			var obj_count = Performance.get_monitor(Performance.OBJECT_COUNT)
			var perf_line = "  -> Health Check: Orphans = %d, Nodes = %d, Objects = %d" % [
				orphans, node_count, obj_count
			]
			print(perf_line)
			log_lines.append(perf_line)

	if elapsed >= DURATION_SECONDS:
		_finish_playtest()

	return false

func _finish_playtest() -> void:
	print("\n==================================================")
	print("[PlaytestRunner] 2-Minute Desktop Run Finished Successfully!")
	print("  Total Time Covered : %.1f seconds (120s goal reached)" % elapsed)
	print("  Final Speed        : %.1f px/s (Speed cap: %.1f)" % [track.player.current_speed, track.player.config.speed_cap])
	print("  Final Distance     : %.0f logical pixels" % track.player.global_position.x)
	print("  Orphan Nodes       : %d" % Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	print("==================================================")

	# Save log to docs/evidence/desktop_run_2min.log
	var f = FileAccess.open("res://docs/evidence/desktop_run_2min.log", FileAccess.WRITE)
	if f:
		for l in log_lines:
			f.store_line(l)
		f.close()
		print("[PlaytestRunner] Evidence log written to docs/evidence/desktop_run_2min.log")

	quit(0)
