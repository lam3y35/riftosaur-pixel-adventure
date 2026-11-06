class_name LevelPattern
extends Resource

## Data resource representing a hand-authored chunk pattern with metadata
## for procedural generation and fairness verification.

@export var pattern_id: String = ""
@export var chunk_scene_path: String = ""
@export var chunk_width: float = 480.0
@export var world_ids: Array[String] = ["plains", "jungle", "frozen", "volcanic"]
@export_range(1, 5) var difficulty_band: int = 1
@export var speed_range: Vector2 = Vector2(250.0, 520.0) # min_speed, max_speed
@export var required_movement: Array[String] = ["run_and_jump"] # "run_and_jump", "slide", "dive", "bounce", "flight", "none"
@export_enum("safe", "challenging", "optional_reward") var route_class: String = "safe"

# Entry and exit connectors for seamless physical continuity
@export var entry_height: float = 230.0 # Ground y position
@export var entry_surface: String = "solid" # "solid", "air", "platform"
@export var exit_height: float = 230.0 # Ground y position
@export var exit_surface: String = "solid"

# Whether this pattern requires a skill (hard rule: must have skillless alternative)
@export var requires_skill: bool = false
@export var skill_type: String = ""
