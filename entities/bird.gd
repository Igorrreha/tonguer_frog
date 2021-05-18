extends InteractiveGrabable

class_name Bird


onready var node_anim_player = $AnimationPlayer
onready var node_force_unpin_timer = $TimerForceUnpin

export var force_unpin_time = 2.0

export var move_speed_before_pinned = 200.0
export var move_ang_before_pinned = 0.0
export var fly_before_pinned = false

export var move_speed_pinned = 200.0
export var move_ang_pinned = PI*0.03
export var fly_pinned = true

export var move_speed_after_pinned = 400.0
export var move_ang_after_pinned = -PI*0.3
export var fly_after_pinned = true


func get_class():
	return "Bird"


func _physics_process(delta):
	match cur_state:
		STATES.BEFORE_PINNED:
			if fly_before_pinned:
				fly(move_speed_before_pinned, move_ang_before_pinned, delta)
		STATES.PINNED:
			if fly_pinned:
				fly(move_speed_pinned, move_ang_pinned, delta)
		STATES.AFTER_PINNED:
			if fly_after_pinned:
				fly(move_speed_after_pinned, move_ang_after_pinned, delta)


func on_player_pin():
	if force_unpin_time > 0:
		node_force_unpin_timer.start(force_unpin_time)
	
	cur_state = STATES.PINNED


func fly(speed, ang, delta):
	position += Vector2.RIGHT.rotated(ang) * (speed * delta)
	
	if not node_anim_player.current_animation == "ForceUnpin":
		node_anim_player.play("HardFly" if cur_state == STATES.PINNED else "Fly")


func _on_TimerForceUnpin_timeout():
	if cur_state == STATES.PINNED:
		Global.node_player.release_tongue()
		node_anim_player.play("ForceUnpin")


func save():
	return {
		"filename" : get_filename(),
		"parent" : get_parent().get_path(),
		"pos_x" : position.x,
		"pos_y" : position.y,
		"rotation": rotation,
		
		"force_unpin_time": force_unpin_time,
		
		"move_speed_before_pinned": move_speed_before_pinned,
		"move_ang_before_pinned": move_ang_before_pinned,
		"fly_before_pinned": fly_before_pinned,
		
		"move_speed_pinned": move_speed_pinned,
		"move_ang_pinned": move_ang_pinned,
		"fly_pinned": fly_pinned,
		
		"move_speed_after_pinned": move_speed_after_pinned,
		"move_ang_after_pinned": move_ang_after_pinned,
		"fly_after_pinned": fly_after_pinned,
		
		"cur_state": cur_state,
		"can_be_pinned_once": can_be_pinned_once,
		
		"force_unpin_timer_is_stopped": node_force_unpin_timer.is_stopped(),
		"force_unpin_time_left": node_force_unpin_timer.time_left
	}


func load_from_data(data):
	for key in data:
		if not (key == "filename" 
				or key == "parent" 
				or key == "pos_x" 
				or key == "pos_y"
				or key == "force_unpin_timer_is_stopped"
				or key == "force_unpin_time_left"):
			self[key] = data[key]
	
	if not data.force_unpin_timer_is_stopped:
		node_force_unpin_timer.start(data.force_unpin_time_left)
