class_name InputReplaySystem
extends RefCounted

## Replay event schema:
## {
##   "time_ms": int,
##   "action": String,
##   "pressed": bool
## }

const VALID_ACTIONS: PackedStringArray = ["jump", "slide", "skill", "pause", "steer_left", "steer_right"]
const MAX_RECORDED_EVENTS: int = 20000

var recording: bool = false
var replaying: bool = false
var recorded_events: Array[Dictionary] = []
var playback_index: int = 0
var playback_start_time_ms: int = 0
var _last_recorded_time_ms: int = -1

signal replay_completed()

func start_recording() -> void:
	recording = true
	replaying = false
	recorded_events.clear()
	_last_recorded_time_ms = -1

func record_action(action: String, pressed: bool, current_time_ms: int) -> void:
	if not recording:
		return
	if not VALID_ACTIONS.has(action):
		return
	if current_time_ms < 0 or current_time_ms < _last_recorded_time_ms:
		return
	if recorded_events.size() >= MAX_RECORDED_EVENTS:
		return
	_last_recorded_time_ms = current_time_ms
	recorded_events.append({
		"time_ms": current_time_ms,
		"action": action,
		"pressed": pressed
	})

func stop_recording() -> Array[Dictionary]:
	recording = false
	var copy: Array[Dictionary] = []
	for ev in recorded_events:
		copy.append(ev.duplicate(true))
	return copy

func start_replaying(events: Array[Dictionary], start_time_ms: int) -> void:
	recording = false
	recorded_events.clear()
	var prev_time: int = -1
	for ev in events:
		if typeof(ev) != TYPE_DICTIONARY:
			continue
		var action = str(ev.get("action", ""))
		var raw_t = ev.get("time_ms", -1)
		if typeof(raw_t) != TYPE_INT and typeof(raw_t) != TYPE_FLOAT:
			continue
		var time_ms = int(raw_t)
		if not VALID_ACTIONS.has(action) or time_ms < 0 or time_ms < prev_time:
			continue
		prev_time = time_ms
		recorded_events.append({
			"time_ms": time_ms,
			"action": action,
			"pressed": bool(ev.get("pressed", false))
		})
		if recorded_events.size() >= MAX_RECORDED_EVENTS:
			break
	replaying = not recorded_events.is_empty()
	playback_index = 0
	playback_start_time_ms = maxi(0, start_time_ms)

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
