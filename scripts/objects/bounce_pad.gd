class_name BouncePad
extends Area2D

signal launched(body: Node2D, force: float)

enum State {
	IDLE,
	COMPRESSED,
	LAUNCHING,
	COOLDOWN
}

@export var pad_type: String = "mushroom" # "mushroom", "stump", "launchpad", "wind_vent", "branch"
@export var launch_force: float = -520.0
@export var forward_boost: float = 40.0
@export var compress_duration: float = 0.06
@export var cooldown_duration: float = 0.25

var current_state: State = State.IDLE
var state_timer: float = 0.0

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 # Detect Player (layer 1)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if current_state != State.IDLE:
		state_timer += delta
		match current_state:
			State.COMPRESSED:
				if state_timer >= compress_duration:
					_transition_to_launching()
			State.LAUNCHING:
				if state_timer >= 0.12:
					_transition_to_cooldown()
			State.COOLDOWN:
				if state_timer >= cooldown_duration:
					_transition_to_idle()

func _on_body_entered(body: Node2D) -> void:
	if current_state != State.IDLE:
		return
	if body.has_method("bounce_launch"):
		_trigger_launch(body as CharacterBody2D)

func _trigger_launch(body: CharacterBody2D) -> void:
	current_state = State.COMPRESSED
	state_timer = 0.0
	if sprite:
		sprite.scale = Vector2(1.3, 0.6) # Squash on impact
	body.bounce_launch(launch_force, forward_boost)
	launched.emit(body, launch_force)

func _transition_to_launching() -> void:
	current_state = State.LAUNCHING
	state_timer = 0.0
	if sprite:
		sprite.scale = Vector2(0.8, 1.35) # Upward stretch launch

func _transition_to_cooldown() -> void:
	current_state = State.COOLDOWN
	state_timer = 0.0
	if sprite:
		sprite.scale = Vector2(1.05, 0.95)

func _transition_to_idle() -> void:
	current_state = State.IDLE
	state_timer = 0.0
	if sprite:
		sprite.scale = Vector2.ONE
