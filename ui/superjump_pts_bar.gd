extends TextureProgress

class_name SuperjumpBar


onready var node_tween = $Tween

export var change_value_dur = 0.2


func get_class():
	return "SuperjumpBar"


func set_value(val):
	node_tween.remove_all()
	node_tween.interpolate_property(self, "value", value, val, change_value_dur, Tween.TRANS_LINEAR, Tween.EASE_OUT) 
	
	node_tween.start()


func save():
	return {
		"filename" : get_filename(),
		"parent" : get_parent().get_path(),
		"change_value_dur": change_value_dur,
		"value": value
	}


func load_from_data(data):
	for key in data:
		if not (key == "filename"
				or key == "parent"):
			self[key] = data[key]
