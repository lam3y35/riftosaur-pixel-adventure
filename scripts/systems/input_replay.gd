class_name InputReplaySystem
extends RefCounted

## Replay event schema:
## {
##   "time_ms": int,
##   "action": String,
##   "pressed": bool
## }

var recording: bool = false
var replaying: bool = false
var recorded_events: Array[Dictionary] = []
var playback_index: int = 0
var playback_start_time_ms: int = 0

signal replay_completed()

func start_recording() -> void:
	recording = true
	replaying = false
	recorded_events.clear()

func record_action(action: String, pressed: bool, current_time_ms: int) -> void:
	if not recording:
		return
	recorded_events.append({
		"time_ms": current_time_ms,
		"action": action,
		"pressed": pressed
	})

func stop_recording() -> Array[Dictionary]:
	recording = false
	return recorded_events.duplicate()

func start_replaying(events: Array[Dictionary], start_time_ms: int) -> void:
	recording = false
	replaying = true
	recorded_events = events.duplicate()
	playback_index = 0
	playback_start_time_ms = start_time_ms

func update_playback(current_time_ms: int) -> Array[Dictionary]:
	var triggered: Array[Dictionary] = []
	if not replaying:
		return triggered

	var elapsed: int = current_time_ms - playback_start_time_ms
	while playback_index < recorded_events.size():
		var ev: Dictionary = recorded_events[playback_index]
		if ev["time_ms"] <= elapsed:
			triggered.append(ev)
			playback_index += 1
		else:
			break

	if playback_index >= recorded_events.size():
		replaying = false
		replay_completed.emit()

	return triggered
