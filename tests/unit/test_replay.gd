class_name TestReplay
extends RefCounted

const InputReplaySystem = preload("res://scripts/systems/input_replay.gd")

func get_test_name() -> String:
	return "InputReplayTest"

func test_input_recording_and_playback() -> Variant:
	var system = InputReplaySystem.new()
	system.start_recording()
	system.record_action("jump", true, 100)
	system.record_action("jump", false, 250)
	system.record_action("slide", true, 400)
	var events = system.stop_recording()

	if events.size() != 3:
		return "Expected 3 recorded events, got %d" % events.size()

	# Start playback
	system.start_replaying(events, 1000)

	var fired_1 = system.update_playback(1050) # elapsed 50 ms -> nothing
	if not fired_1.is_empty():
		return "Expected 0 events at 50ms, got %d" % fired_1.size()

	var fired_2 = system.update_playback(1150) # elapsed 150 ms -> 1st event ("jump", true, 100)
	if fired_2.size() != 1 or fired_2[0]["action"] != "jump" or fired_2[0]["pressed"] != true:
		return "Expected 1 jump press event, got %s" % str(fired_2)

	var fired_3 = system.update_playback(1500) # elapsed 500 ms -> remaining 2 events
	if fired_3.size() != 2:
		return "Expected 2 remaining events, got %d" % fired_3.size()

	return true
