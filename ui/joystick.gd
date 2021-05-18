extends Control

class_name Joystick

signal output(output)

onready var node_stick = $Stick
onready var node_tween = $TweenActivity
onready var stick_length = rect_size.x

onready var active_modulate = modulate
onready var unactive_modulate = Color(active_modulate.r, active_modulate.g, active_modulate.b, 0.3) 

var is_pressed = false
var touch_idx = -1
var output = Vector2()

var fade_out_dur = 0.5


func _ready():
	modulate = unactive_modulate


func _input(event):
	if event is InputEventScreenDrag:
		if is_pressed and event.index == touch_idx:
			node_stick.position = (event.position - rect_global_position).clamped(stick_length)
			
			output = node_stick.position / stick_length
			
			emit_signal("output", output)


func get_class():
	return "Joystick"


func set_pressed(_is_pressed, _idx, _pos = Vector2()):
	is_pressed = _is_pressed
	if is_pressed:
		touch_idx = _idx
		node_stick.position = _pos - rect_position
		
		fade_in()
	else:
		touch_idx = -1
		node_stick.position = Vector2()
		
		fade_out()
	
	output = node_stick.position / stick_length
	emit_signal("output", output)


func fade_in():
	node_tween.remove_all()
	modulate = active_modulate


func fade_out():
	node_tween.remove_all()
	
	node_tween.interpolate_property(self, "modulate", active_modulate, unactive_modulate, fade_out_dur)
	node_tween.start()
