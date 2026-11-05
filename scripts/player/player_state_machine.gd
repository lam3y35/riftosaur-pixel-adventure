class_name PlayerStateMachine
extends RefCounted

enum State {
	IDLE,
	RUN,
	JUMP_RISE,
	JUMP_APEX,
	JUMP_FALL,
	LAND,
	SLIDE,
	DIVE,
	DROP_THROUGH,
	AIR_DASH,
	FLIGHT,
	HURT,
	DEAD,
	RESPAWN
}

var current_state: State = State.IDLE
var previous_state: State = State.IDLE
var time_in_state: float = 0.0

signal state_changed(old_state: State, new_state: State)

func change_state(new_state: State) -> bool:
	if current_state == new_state:
		return false

	# Enforce state validity: dead state is terminal until explicit respawn
	if current_state == State.DEAD and new_state != State.RESPAWN:
		return false

	previous_state = current_state
	current_state = new_state
	time_in_state = 0.0
	state_changed.emit(previous_state, current_state)
	return true

func update(delta: float) -> void:
	time_in_state += delta

func is_in(state: State) -> bool:
	return current_state == state

func get_state_name(state: State = current_state) -> String:
	match state:
		State.IDLE: return "IDLE"
		State.RUN: return "RUN"
		State.JUMP_RISE: return "JUMP_RISE"
		State.JUMP_APEX: return "JUMP_APEX"
		State.JUMP_FALL: return "JUMP_FALL"
		State.LAND: return "LAND"
		State.SLIDE: return "SLIDE"
		State.DIVE: return "DIVE"
		State.DROP_THROUGH: return "DROP_THROUGH"
		State.AIR_DASH: return "AIR_DASH"
		State.FLIGHT: return "FLIGHT"
		State.HURT: return "HURT"
		State.DEAD: return "DEAD"
		State.RESPAWN: return "RESPAWN"
		_: return "UNKNOWN"
