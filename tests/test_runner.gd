class_name TestRunner
extends SceneTree

var passed: int = 0
var failed: int = 0
var skipped: int = 0
var test_cases: Array = []

func _init() -> void:
	print("==================================================")
	print("[TestRunner] Starting Riftosaur Test Suite")
	print("==================================================")
	call_deferred("_run_all_tests")

func _run_all_tests() -> void:
	# Discover test scripts
	_register_tests()

	for test_instance in test_cases:
		var test_name: String = test_instance.get_test_name()
		print("\n--- Running Test Suite: %s ---" % test_name)
		var methods: Array = test_instance.get_method_list()
		for m in methods:
			var m_name: String = m["name"]
			if m_name.begins_with("test_"):
				_run_single_test(test_instance, m_name)

	print("\n==================================================")
	print("[TestRunner] Test Execution Summary:")
	print("  Total Passed : %d" % passed)
	print("  Total Failed : %d" % failed)
	print("  Total Skipped: %d" % skipped)
	print("==================================================")

	if failed > 0:
		print("[TestRunner] RESULT: FAILED")
		quit(1)
	else:
		print("[TestRunner] RESULT: PASSED (L2 Verified)")
		quit(0)

func _register_tests() -> void:
	var smoke_script = load("res://tests/unit/test_smoke.gd")
	if smoke_script:
		test_cases.append(smoke_script.new())
	var replay_script = load("res://tests/unit/test_replay.gd")
	if replay_script:
		test_cases.append(replay_script.new())
	var movement_script = load("res://tests/unit/test_movement.gd")
	if movement_script:
		test_cases.append(movement_script.new())
	var save_script = load("res://tests/unit/test_save_service.gd")
	if save_script:
		test_cases.append(save_script.new())
	var runner_script = load("res://tests/unit/test_endless_runner.gd")
	if runner_script:
		test_cases.append(runner_script.new())
	var vertical_script = load("res://tests/unit/test_vertical_platforms.gd")
	if vertical_script:
		test_cases.append(vertical_script.new())
	var skills_script = load("res://tests/unit/test_skills_system.gd")
	if skills_script:
		test_cases.append(skills_script.new())
	var flight_script = load("res://tests/unit/test_flight_system.gd")
	if flight_script:
		test_cases.append(flight_script.new())
	var themes_script = load("res://tests/unit/test_world_themes.gd")
	if themes_script:
		test_cases.append(themes_script.new())
	var proc_script = load("res://tests/unit/test_procedural_generation.gd")
	if proc_script:
		test_cases.append(proc_script.new())

func _run_single_test(test_obj: Object, method_name: String) -> void:
	# Check if test object has setup
	if test_obj.has_method("before_each"):
		test_obj.call("before_each")

	var result = test_obj.call(method_name)

	if test_obj.has_method("after_each"):
		test_obj.call("after_each")

	if result == null or (typeof(result) == TYPE_BOOL and result == true):
		passed += 1
		print("  [PASS] %s" % method_name)
	elif typeof(result) == TYPE_STRING and (result as String).begins_with("SKIP:"):
		skipped += 1
		print("  [SKIP] %s (%s)" % [method_name, result])
	else:
		failed += 1
		print("  [FAIL] %s: %s" % [method_name, str(result)])
