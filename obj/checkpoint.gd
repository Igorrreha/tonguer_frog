extends Area2D

class_name Checkpoint

signal activated

var is_activated = false


func _on_Checkpoint_body_entered(body):
	if not is_activated and body is Player:
		is_activated = true
		
		emit_signal("activated")

