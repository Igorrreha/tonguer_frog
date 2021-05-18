extends Area2D

class_name TongueCollectable


signal collected


func collect():
	emit_signal("collected")
	queue_free()
