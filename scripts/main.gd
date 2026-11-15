class_name MainScene
extends Node2D

func _ready() -> void:
	Engine.max_fps = 60
	Engine.physics_ticks_per_second = 60
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	print("[Riftosaur] Booting game into EndlessRunner...")
	get_tree().change_scene_to_file("res://scenes/gameplay/endless_runner.tscn")
