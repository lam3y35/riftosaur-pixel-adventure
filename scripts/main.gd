class_name MainScene
extends Node2D

func _ready() -> void:
	print("[Riftosaur] Booting game into EndlessRunner...")
	get_tree().change_scene_to_file("res://scenes/gameplay/endless_runner.tscn")
