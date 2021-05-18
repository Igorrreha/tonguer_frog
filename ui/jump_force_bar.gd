extends ProgressBar

onready var node_tween = $Tween

export var sparkle_dur = 0.4


func sparkle():
	var value_coeff = value / max_value
	var red_coeff = 1 if value_coeff < 0.5 else (1 - value_coeff) * 2
	var green_coeff = value_coeff * 2 if value_coeff < 0.5 else 1
	
	value = 0
	
	node_tween.interpolate_property(self, "modulate", Color(red_coeff, green_coeff, 0), Color(1, 1, 1), sparkle_dur)
	node_tween.start()
