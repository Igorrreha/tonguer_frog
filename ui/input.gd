extends Control

signal touch_start
signal touch_end


func _input(event):
	if event is InputEventScreenTouch:
		var childs = get_children()
		
		if event.is_pressed():
			for child in childs:
				# return if touch is in active joystick zone 
				if child is Joystick:
					if child.is_pressed and child.touch_idx == event.index:
						return
						
			for child in childs:
				if child is Joystick:
					# set joystick pressed
					if event.position.distance_to(child.rect_global_position) < child.stick_length * child.rect_scale.x:
						child.set_pressed(true, event.index, event.position)
						return
			
			emit_signal("touch_start")
		
		else:
			for child in childs:
				if child is Joystick:
					if child.is_pressed and child.touch_idx == event.index:
						child.set_pressed(false, event.index)
						return
			
			emit_signal("touch_end")
		
	
