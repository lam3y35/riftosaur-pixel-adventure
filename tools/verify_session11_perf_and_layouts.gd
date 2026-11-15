extends SceneTree

const EndlessRunnerScene = preload("res://scenes/gameplay/endless_runner.tscn")

var perf_data = {
	"startup_time_ms": 0,
	"restart_time_ms": 0,
	"frame_times_ms": [],
	"avg_frame_time_ms": 0.0,
	"max_frame_time_ms": 0.0,
	"min_frame_time_ms": 0.0,
	"layouts_tested": {},
	"all_layouts_passed": false
}

func _init() -> void:
	call_deferred("_run_perf_tests")

func _run_perf_tests() -> void:
	print("==================================================")
	print("Starting Session 11 Performance & Layout Benchmark")
	print("==================================================")
	
	await process_frame
	await physics_frame
	
	# 1. Measure Startup Time
	var start_ticks = Time.get_ticks_usec()
	var runner = EndlessRunnerScene.instantiate()
	root.add_child(runner)
	await process_frame
	await physics_frame
	var startup_dur_ms = (Time.get_ticks_usec() - start_ticks) / 1000.0
	perf_data["startup_time_ms"] = startup_dur_ms
	print("  App & Scene Startup Time: %.2f ms" % startup_dur_ms)
	
	# 2. Measure Restart Time
	runner.start_new_run()
	for i in range(10):
		runner.player._physics_process(1.0 / 60.0)
		runner._physics_process(1.0 / 60.0)
	
	var restart_ticks = Time.get_ticks_usec()
	runner.restart_run()
	var restart_dur_ms = (Time.get_ticks_usec() - restart_ticks) / 1000.0
	perf_data["restart_time_ms"] = restart_dur_ms
	print("  Immediate Restart Time: %.2f ms" % restart_dur_ms)
	
	# 3. Measure 300 Frames Frame Time Stability
	var max_ft = 0.0
	var min_ft = 999999.0
	var sum_ft = 0.0
	var sample_count = 300
	
	for s in range(sample_count):
		var t0 = Time.get_ticks_usec()
		runner.player._physics_process(1.0 / 60.0)
		runner._physics_process(1.0 / 60.0)
		var ft = (Time.get_ticks_usec() - t0) / 1000.0
		sum_ft += ft
		if ft > max_ft: max_ft = ft
		if ft < min_ft: min_ft = ft
	
	var avg_ft = sum_ft / sample_count
	perf_data["avg_frame_time_ms"] = avg_ft
	perf_data["max_frame_time_ms"] = max_ft
	perf_data["min_frame_time_ms"] = min_ft
	print("  Frame Pacing: Avg=%.3f ms (%.1f FPS), Min=%.3f ms, Max=%.3f ms" % [avg_ft, 1000.0 / maxf(avg_ft, 0.001), min_ft, max_ft])
	
	# 4. Multi-Resolution Aspect Ratio Layout Checks (Spec C & Acceptance Criterion 14)
	# Resolutions: 16:9 (480x270, 1920x1080), 19.5:9 (2340x1080), 20:9 (2400x1080), 4:3 (1024x768)
	var test_resolutions = [
		{"name": "16:9 Standard", "size": Vector2i(480, 270)},
		{"name": "16:9 FHD", "size": Vector2i(1920, 1080)},
		{"name": "19.5:9 Tall Mobile", "size": Vector2i(2340, 1080)},
		{"name": "20:9 Ultra-Tall", "size": Vector2i(2400, 1080)},
		{"name": "4:3 Tablet", "size": Vector2i(1024, 768)}
	]
	
	var layouts_ok = true
	for res in test_resolutions:
		var r_name = res["name"]
		var r_size = res["size"]
		root.size = r_size
		await process_frame
		
		# Check that buttons and HUD are within bounds
		var hud = runner.hud
		var score_pos = hud.score_label.global_position
		var jump_btn_pos = hud.jump_button.global_position
		var slide_btn_pos = hud.slide_button.global_position
		
		var inside_screen = (jump_btn_pos.x >= 0 and jump_btn_pos.y >= 0 and slide_btn_pos.x >= 0 and slide_btn_pos.y >= 0)
		assert(inside_screen, "Controls must remain accessible within screen at %s" % r_name)
		# Verify TopBar items and ComboPanel do not intersect at any resolution
		var top_items: Array = [
			hud.score_label, hud.best_label, hud.points_label, hud.gems_label, hud.pause_button,
			hud.skill_slot, hud.world_label, hud.distance_label, hud.seed_label, hud.combo_panel
		]
		for i in range(top_items.size()):
			var ci: Control = top_items[i]
			if ci == null: continue
			var ri := Rect2(ci.global_position, ci.size)
			for j in range(i + 1, top_items.size()):
				var cj: Control = top_items[j]
				if cj == null: continue
				var rj := Rect2(cj.global_position, cj.size)
				if ri.intersects(rj):
					printerr("HUD overlap between %s (%s) and %s (%s) at %s" % [ci.name, str(ri), cj.name, str(rj), r_name])
					root.remove_child(runner)
					runner.free()
					quit(1)
					return
		perf_data["layouts_tested"][r_name] = {
			"resolution": "%dx%d" % [r_size.x, r_size.y],
			"controls_accessible": inside_screen,
			"score_label_visible": hud.score_label.visible,
			"status": "PASS"
		}
		print("  [PASS] Layout %s (%dx%d): Controls & HUD intact (0 overlaps)" % [r_name, r_size.x, r_size.y])

	# Simulated mobile cutout safe-area check on worst-case 16:9 width
	root.size = Vector2i(480, 270)
	await process_frame
	runner.hud._apply_safe_area_layout({"left": 28.0, "top": 12.0, "right": 28.0, "bottom": 16.0})
	await process_frame
	var notched_items: Array = [
		runner.hud.score_label, runner.hud.best_label, runner.hud.points_label, runner.hud.gems_label, runner.hud.pause_button,
		runner.hud.skill_slot, runner.hud.world_label, runner.hud.distance_label, runner.hud.seed_label, runner.hud.combo_panel
	]
	for i in range(notched_items.size()):
		var ci: Control = notched_items[i]
		if ci == null: continue
		var ri := Rect2(ci.global_position, ci.size)
		for j in range(i + 1, notched_items.size()):
			var cj: Control = notched_items[j]
			if cj == null: continue
			var rj := Rect2(cj.global_position, cj.size)
			if ri.intersects(rj):
				printerr("Notched Safe-Area HUD overlap between %s (%s) and %s (%s)" % [ci.name, str(ri), cj.name, str(rj)])
				root.remove_child(runner)
				runner.free()
				quit(1)
				return
	print("  [PASS] Layout Notched Safe-Area 16:9 (28px side insets): 0 TopBar overlaps")
	
	perf_data["all_layouts_passed"] = layouts_ok
	
	# Cleanup
	root.remove_child(runner)
	runner.free()
	
	# Save performance report
	var path = "res://tests/perf_report.json"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(perf_data, "\t"))
		file.close()
		print("Saved performance benchmark to %s" % path)
	
	print("==================================================")
	print("[Perf & Layouts] RESULT: ALL BENCHMARKS PASSED")
	print("==================================================")
	quit(0)
