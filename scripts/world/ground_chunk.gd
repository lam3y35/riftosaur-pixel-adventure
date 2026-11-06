class_name GroundChunk
extends Node2D

@export var pattern_name: String = "empty"
@export var difficulty: int = 1
@export var chunk_width: float = 480.0

# Connectors for procedural generation matching
@export var entry_height: float = 230.0
@export var entry_surface: String = "solid"
@export var exit_height: float = 230.0
@export var exit_surface: String = "solid"

# Route class & movement metadata
@export_enum("safe", "challenging", "optional_reward") var route_class: String = "safe"
@export_range(1, 5) var difficulty_band: int = 1
@export var required_movement: Array[String] = ["run_and_jump"]
@export var allowed_worlds: Array[String] = ["plains", "jungle", "frozen", "volcanic"]

const GROUND_Y: float = 230.0
