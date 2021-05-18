extends StaticBody2D

class_name GrabPoint


signal player_pinned
signal player_unpinned

onready var node_collider = $CollisionShape2D


func on_player_pin():
	emit_signal("player_pinned")


func on_player_unpin():
	emit_signal("player_unpinned")
