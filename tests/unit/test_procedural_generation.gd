class_name TestProceduralGeneration
extends RefCounted

## Unit test suite for Session 8: Procedural generation, deterministic seeds,
## connectors, difficulty bands, and fairness constraints.

const LevelGenerator = preload("res://scripts/world/level_generator.gd")
const LevelPattern = preload("res://scripts/world/level_pattern.gd")

func get_test_name() -> String:
	return "ProceduralGenerationAndFairnessTest"

func test_deterministic_seed_reproducibility() -> void:
	var gen1 = LevelGenerator.new(428951)
	var gen2 = LevelGenerator.new(428951)

	var sequence1: Array[String] = []
	var sequence2: Array[String] = []

	for i in range(15):
		var p1 = gen1.select_next_pattern(float(i * 100), 300.0 + float(i * 10), "plains")
		var p2 = gen2.select_next_pattern(float(i * 100), 300.0 + float(i * 10), "plains")
		sequence1.append(p1.pattern_id)
		sequence2.append(p2.pattern_id)

	assert(sequence1.size() == sequence2.size(), "Sequences must have equal length")
	for i in range(sequence1.size()):
		assert(sequence1[i] == sequence2[i], "Mismatch at step %d: %s != %s" % [i, sequence1[i], sequence2[i]])

func test_different_seeds_produce_different_sequences() -> void:
	var gen1 = LevelGenerator.new(111111)
	var gen2 = LevelGenerator.new(999999)

	var sequence1: Array[String] = []
	var sequence2: Array[String] = []

	for i in range(20):
		var p1 = gen1.select_next_pattern(float(i * 50), 320.0, "plains")
		var p2 = gen2.select_next_pattern(float(i * 50), 320.0, "plains")
		sequence1.append(p1.pattern_id)
		sequence2.append(p2.pattern_id)

	var has_difference = false
	for i in range(sequence1.size()):
		if sequence1[i] != sequence2[i]:
			has_difference = true
			break
	assert(has_difference, "Different seeds must produce different sequences")

func test_connector_continuity() -> void:
	var gen = LevelGenerator.new(55555)
	var prev_exit_h = 230.0
	var prev_exit_s = "solid"

	for i in range(25):
		var pat = gen.select_next_pattern(float(i * 80), 350.0, "plains")
		assert(pat != null, "Pattern must not be null")
		assert(absf(pat.entry_height - prev_exit_h) <= 1.0, "Connector height mismatch at step %d: entry %.1f vs prev exit %.1f" % [i, pat.entry_height, prev_exit_h])
		assert(pat.entry_surface == prev_exit_s, "Connector surface mismatch at step %d: %s vs %s" % [i, pat.entry_surface, prev_exit_s])
		prev_exit_h = pat.exit_height
		prev_exit_s = pat.exit_surface

func test_difficulty_bands_progression() -> void:
	var gen = LevelGenerator.new(12345)
	assert(gen.get_difficulty_band(50.0) == 1, "Band 1 under 150m (Teaching band)")
	assert(gen.get_difficulty_band(149.0) == 1, "Band 1 under 150m")
	assert(gen.get_difficulty_band(200.0) == 2, "Band 2 between 150m and 350m")
	assert(gen.get_difficulty_band(450.0) == 3, "Band 3 between 350m and 600m")
	assert(gen.get_difficulty_band(750.0) == 4, "Band 4 between 600m and 900m")
	assert(gen.get_difficulty_band(1200.0) == 5, "Band 5 over 900m")

func test_hard_rules_no_consecutive_challenging_patterns() -> void:
	var gen = LevelGenerator.new(77777)
	var prev_was_challenging = false

	for i in range(40):
		var pat = gen.select_next_pattern(float(i * 50), 400.0, "plains")
		if prev_was_challenging:
			assert(pat.route_class != "challenging", "Hard rule violation: two consecutive challenging patterns without breathing room (%s after challenging)" % pat.pattern_id)
		prev_was_challenging = (pat.route_class == "challenging")

func test_chunk_cleanup_keeps_pool_bounded() -> void:
	var runner_scene = load("res://scenes/gameplay/endless_runner.tscn")
	var runner = runner_scene.instantiate() as EndlessRunner
	Engine.get_main_loop().root.add_child(runner)

	runner.begin_run()
	# Spawn 20 chunks ahead
	for i in range(20):
		runner._spawn_next_procedural_chunk()

	assert(runner.chunk_pool.size() > 5, "Pool should have spawned chunks")

	# Move player forward 9000px and clean up behind
	runner.player.position.x = 9000.0
	runner._cleanup_chunks_behind(runner.player.position.x - 600.0)

	assert(runner.chunk_pool.size() <= 6, "Chunk pool must be strictly pruned behind player (actual: %d)" % runner.chunk_pool.size())
	runner.queue_free()
