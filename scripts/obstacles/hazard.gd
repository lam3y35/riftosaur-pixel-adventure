class_name Hazard
extends Area2D

@export var hazard_name: String = "Cactus Rock"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.hit_hazard("Hit by %s" % hazard_name)
