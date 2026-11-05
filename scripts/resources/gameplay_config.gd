class_name GameplayConfig
extends Resource

# --- Speed & Pacing ---
@export_group("Pacing")
@export var opening_speed: float = 290.0 # logical px/s (~80% classic speed)
@export var speed_cap: float = 464.0 # 1.6x opening speed
@export var acceleration_rate: float = 2.5 # px/s^2 increase over distance

# --- Movement & Gravity ---
@export_group("Jump & Gravity")
@export var gravity: float = 1050.0 # Standard downward acceleration (px/s^2)
@export var fall_gravity_multiplier: float = 1.35 # Slightly heavier falling for responsive game feel
@export var initial_jump_velocity: float = 250.0 # Immediate upward impulse (px/s)
@export var jump_hold_force: float = 800.0 # Upward sustained acceleration while holding jump (px/s^2)
@export var max_jump_hold_time: float = 0.35 # Maximum jump hold duration in seconds
@export var early_jump_release_multiplier: float = 0.45 # Factor applied to upward velocity on early release
@export var max_jump_height: float = 84.0 # Max height ceiling reference
@export var tap_jump_height: float = 30.0 # Min tap height reference

# --- Timing Windows (in physics time) ---
@export_group("Timing Windows")
@export var coyote_time: float = 0.11 # Seconds allowed to jump after leaving ground (0.10 - 0.12s)
@export var jump_buffer_time: float = 0.12 # Seconds input is buffered before landing

# --- Slide & Dive ---
@export_group("Slide & Dive")
@export var slide_duration: float = 0.50 # Duration of ground slide before auto-recovering
@export var dive_velocity: float = 520.0 # Fast downward velocity when diving in air

# --- Collision Shapes ---
@export_group("Collision")
@export var standing_extents: Vector2 = Vector2(10, 12) # Half-extents for standing/running (20x24)
@export var sliding_extents: Vector2 = Vector2(12, 6) # Half-extents for sliding (24x12)
@export var standing_offset: Vector2 = Vector2(0, 0)
@export var sliding_offset: Vector2 = Vector2(0, 6) # Lower center of mass during slide

# --- Visual Feel ---
@export_group("Juice & Feedback")
@export var squash_duration: float = 0.12
@export var stretch_duration: float = 0.15
@export var landing_squash_scale: Vector2 = Vector2(1.25, 0.75)
@export var takeoff_stretch_scale: Vector2 = Vector2(0.80, 1.25)
