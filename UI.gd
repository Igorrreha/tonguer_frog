extends Control


onready var node_tween_fade = $TweenFade
onready var default_modulate = modulate

export var fade_dur = 1.0


func fade_in():
	node_tween_fade.interpolate_property(self, "modulate", Color(modulate.r, modulate.g, modulate.b, 0), modulate, fade_dur)
	node_tween_fade.start()
	
	visible = true
