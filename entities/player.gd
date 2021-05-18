extends KinematicBody2D

class_name Player

signal cur_jump_force_changed(val)
signal jump
signal pin_tongue(pinObj)
signal release_tongue
signal swing_apply_force(vec)
signal died
signal superjump_pts_changed(cur_val)
signal superjump


onready var node_tween_jump_force = $TweenJumpForce
onready var node_tween_recovery = $TweenRecovery
onready var node_anim_player = $AnimationPlayer
onready var node_tongue_grab_zone = $TongueGrabZone
onready var node_tongue_line = $TongueLine
onready var node_cam = $Camera2D
onready var node_hitbox = $Hitbox
onready var node_tongue_start_point: Position2D = $TongueStartPoint


enum STATES {
	IDLE, JUMP_LOAD, IN_AIR,
	TONGUE_SHOOT_LOAD, TONGUE_SHOOT, 
	TONGUE_SWING, RECOVERY, SUPERJUMP_LOAD, SUPERJUMP
}
export(STATES) var cur_state = STATES.IN_AIR

var move_vec = Vector2()
var move_dec = 50.0

var grav = 1000.0

export var jump_force_curve: Curve
var max_jump_force = 700.0
var min_jump_force = 350.0
var cur_jump_force = 0.0
var jump_ang = -PI*0.41
var jump_load_dur = 0.7

var swing_applied_force = 1000

var default_time_scale = 1

var tongue_shoot_load_slowmo_coef = 0.1
var tongue_shoot_load_sensitivity = 1
onready var default_tongue_line_points = node_tongue_line.points

var recovery_dur = 0.5
var recovery_jump_force = 250.0
var recovery_x_dec_coef = 0.6


var superjump_pts = 0.0
var max_superjump_pts = 7.0

var superjump_force = 1000.0

var joystick_inp_vec := Vector2() 
export var inp_locked = false
export var is_paused = true


func _ready():
	Global.node_player = self
	
	connect("superjump", node_cam, "screen_shake")
	ini_cam_smoothing()


func get_class():
	return "Player"


func _physics_process(delta):
	
	if is_paused:
		return
	
	match cur_state:
		# in air
		STATES.IN_AIR, STATES.TONGUE_SHOOT_LOAD, STATES.TONGUE_SHOOT, STATES.RECOVERY, STATES.SUPERJUMP:
			if cur_state == STATES.IN_AIR or cur_state == STATES.TONGUE_SHOOT_LOAD and not inp_locked:
				rotation = joystick_inp_vec.angle()
			
			if move_vec.x > 0:
				move_vec.x = move_vec.x - move_dec * delta if abs(move_vec.x) > move_dec * delta else 0
			else:
				move_vec.x = move_vec.x + move_dec * delta if abs(move_vec.x) > move_dec * delta else 0
			
			if is_on_floor():
				
				# off slowmo on landing
				Engine.time_scale = default_time_scale
				
				# normal landing after regular jump
				if abs(rotation) < PI/6:
					cur_state = STATES.IDLE
					move_vec.y = grav * delta
					
					rotation = 0
				
				# wierd landing, recovery needed
				else:
					start_normal_pos_recovery()
				
				# clear joystick inp vec
				joystick_inp_vec = Vector2()
				
			else:
				move_vec.y += grav * delta
			
			move_and_slide(move_vec, Vector2.UP)
			
		# on horisontal flat
		STATES.IDLE:
			move_vec.x = 0.0
			move_vec.y = grav * delta
			
			move_and_slide(move_vec, Vector2.UP)
			
			# superjump
			if superjump_pts >= max_superjump_pts:
				for body in node_hitbox.get_overlapping_areas():
					if body is SuperjumpZone:
						start_superjump_load()
			
			node_anim_player.play("Idle")
			
			if not is_on_floor():
				cur_state = STATES.IN_AIR
		
		# on tongue grab
		STATES.TONGUE_SWING:
			# applying swing force 
			if joystick_inp_vec.length() > 0:
				emit_signal("swing_apply_force", joystick_inp_vec.normalized() * swing_applied_force * delta)


func ini_cam_smoothing():
	yield(get_tree().create_timer(0.05), "timeout")
	node_cam.smoothing_enabled = true


func start_jump_load():
	cur_state = STATES.JUMP_LOAD
	
	node_tween_jump_force.interpolate_method(self, "jump_load", 0.0, 1.0, jump_load_dur)
	node_tween_jump_force.start()
	
	node_anim_player.play("JumpLoad")


func jump_load(value):
	cur_jump_force = min_jump_force + (jump_force_curve.interpolate(value) * (max_jump_force - min_jump_force))
	emit_signal("cur_jump_force_changed", ((cur_jump_force - min_jump_force) / (max_jump_force - min_jump_force)) * 100)


func superjump_load(value):
	emit_signal("cur_jump_force_changed", value)


func jump():
	node_tween_jump_force.stop_all()
	emit_signal("jump")
	
	move_vec = Vector2(1, 0).rotated(jump_ang) * cur_jump_force
	
	cur_state = STATES.IN_AIR
	move_and_slide(move_vec, Vector2.UP)
	
	node_anim_player.play("InAir")


func start_superjump_load():
	cur_state = STATES.SUPERJUMP_LOAD
	node_tween_jump_force.interpolate_method(self, "superjump_load", 0.0, 100.0, node_anim_player.get_animation("Superjump").length)
	node_tween_jump_force.start()
	
	node_anim_player.play("Superjump")


func superjump():
	node_tween_jump_force.stop_all()
	move_vec = Vector2(1, 0).rotated(jump_ang) * superjump_force
	
	cur_state = STATES.SUPERJUMP
	move_and_slide(move_vec, Vector2.UP)
	
	node_anim_player.play("InAir")


func start_tongue_shoot_load():
	cur_state = STATES.TONGUE_SHOOT_LOAD
	Engine.time_scale = tongue_shoot_load_slowmo_coef
	
	node_anim_player.play("TongueShootLoad")


func tongue_shoot():
	# get nearest overlapped object
	var nearest_obj
	var dist_to_nearest_obj = INF
	for body in node_tongue_grab_zone.get_overlapping_bodies():
		var dist_to_obj = global_position.distance_to(body.global_position)
		if (nearest_obj == null) or (dist_to_obj < dist_to_nearest_obj):
			nearest_obj = body
			dist_to_nearest_obj = dist_to_obj
	
	for area in node_tongue_grab_zone.get_overlapping_areas():
		var dist_to_obj = global_position.distance_to(area.global_position)
		if (nearest_obj == null) or (dist_to_obj < dist_to_nearest_obj):
			nearest_obj = area
			dist_to_nearest_obj = dist_to_obj
	
	# on miss
	if nearest_obj == null:
		cur_state = STATES.TONGUE_SHOOT
		node_tongue_line.points = default_tongue_line_points
		node_anim_player.play("TongueShoot")
	
	# collect if obj is collectable
	elif nearest_obj is TongueCollectable:
		cur_state = STATES.TONGUE_SHOOT
		node_tongue_line.points = [Vector2(), (nearest_obj.global_position - node_tongue_start_point.global_position).rotated(-global_rotation)]
		node_anim_player.play("TongueShoot")
		
		nearest_obj.collect()
	
	# start swing is obj is grabable
	else:
		start_tongue_swing(nearest_obj)
	
	Engine.time_scale = default_time_scale


func start_tongue_swing(grab_point: GrabPoint):
	cur_state = STATES.TONGUE_SWING
	
	# create tongue-rope between player and GrabPoint
	emit_signal("pin_tongue", grab_point)
	
	node_anim_player.play("TongueSwing")
	joystick_inp_vec = Vector2()


func release_tongue():
	emit_signal("release_tongue")
	cur_state = STATES.IN_AIR
	
	joystick_inp_vec = Vector2.RIGHT.rotated(rotation)
	
	start_tongue_shoot_load()


func start_normal_pos_recovery():
	cur_state = STATES.RECOVERY
	
	node_tween_recovery.interpolate_property(self, "rotation", rotation, 0, recovery_dur)
	node_tween_recovery.start()
	
	move_vec = Vector2(move_vec.x * recovery_x_dec_coef, -recovery_jump_force)
	move_and_slide(move_vec, Vector2.UP)
	
	node_anim_player.play("Idle")


func die():
	emit_signal("died")


func joystick_input(vec):
	if inp_locked or is_paused:
		return
	
	if not vec.length() == 0 or cur_state == STATES.TONGUE_SWING:
		joystick_inp_vec = vec


func action_touch_start():
	if inp_locked or is_paused:
		return
	
	match cur_state:
		STATES.IDLE:
			start_jump_load()
		STATES.IN_AIR:
			start_tongue_shoot_load()
		STATES.TONGUE_SWING:
			release_tongue()


func action_touch_end():
	if inp_locked or is_paused:
		return
	
	match cur_state:
		STATES.JUMP_LOAD:
			jump()
		STATES.TONGUE_SHOOT_LOAD:
			tongue_shoot()


func _on_TweenJumpForce_tween_completed(object, key):
	if cur_state == STATES.JUMP_LOAD:
		start_jump_load()
	
	elif cur_state == STATES.SUPERJUMP_LOAD:
		node_tween_jump_force.interpolate_method(self, "superjump_load", 100.0, 0.0,
				node_anim_player.get_animation("Superjump").length / 4, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		node_tween_jump_force.start()
		
		superjump()
		
		emit_signal("superjump")
		
		superjump_pts = 0.0
		emit_signal("superjump_pts_changed", 0.0)


func _on_Hitbox_area_entered(area):
	if area.is_in_group("Deadly"):
		die()


func add_superjump_pts(pts):
	superjump_pts += pts
	clamp(superjump_pts, 0, max_superjump_pts)
	emit_signal("superjump_pts_changed", superjump_pts / max_superjump_pts * 100)


func _input(event):
	if event.is_action_pressed("player_action"):
		action_touch_start()
	
	if event.is_action_released("player_action"):
		action_touch_end()
	
	if event.is_action_pressed("player_lock_inp"):
		inp_locked = not inp_locked


func save():
	return {
		"filename" : get_filename(),
		"parent" : get_parent().get_path(),
		"pos_x" : position.x,
		"pos_y" : position.y,
		"rotation": rotation,
		"move_vec_x": move_vec.x,
		"move_vec_y": move_vec.y,
		"cur_state": cur_state,
		"superjump_pts": superjump_pts,
		"joystick_inp_vec_x": joystick_inp_vec.x,
		"joystick_inp_vec_y": joystick_inp_vec.y
	}


func load_from_data(data):
	for key in data:
		if not (key == "filename"
				or key == "parent"
				or key == "pos_x"
				or key == "pos_y"
				or key == "move_vec_x"
				or key == "move_vec_y"
				or key == "cur_state"
				or key == "joystick_inp_vec_x"
				or key == "joystick_inp_vec_y"):
			self[key] = data[key]
	
	move_vec = Vector2(data.move_vec_x, data.move_vec_y)
	cur_state = int(data.cur_state)
	
	joystick_inp_vec = Vector2(data.joystick_inp_vec_x, data.joystick_inp_vec_y)
	
	move_and_slide(move_vec, Vector2.UP)
