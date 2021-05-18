extends Node

class_name CutscenePlayer


onready var node_cam = $Camera2D
onready var node_tween = $Tween


signal animation_completed


func intro():
	var node_logo = get_node("../Game/Menu/Logo")
	var node_logo_anim_player = get_node("../Game/Menu/Logo/AnimationPlayer")
	var node_tongue = get_node("../Game/Tongue")
	var node_logo_grab_point = get_node("../Game/Menu/Logo/GrabPoint")
	
	var step1_dur = node_logo_anim_player.get_animation("In").length
	var step2_dur = 2.5
	var step3_dur = 0.7
	var step4_dur = 0.2
	
	var step2_cam_delta = Vector2(320, 50)
	var step3_cam_delta = step2_cam_delta * (step3_dur / step2_dur)
	var step4_cam_delta = Vector2(0, 70)
	
	Global.node_player.node_cam.current = false
	Global.node_player.inp_locked = true
	
	
	# 1
	# zoom camera in
	node_tween.remove_all()
	node_tween.interpolate_property(node_cam, "zoom", Vector2(0.5, 0.5), Vector2(0.45, 0.45), step1_dur)
	node_tween.start()
	
	# logo animation In
	node_logo_anim_player.play("In")
	
	yield(node_tween, "tween_all_completed")
	
	
	# 2
	# connect tongue to heart
	Global.node_player.start_tongue_swing(node_logo_grab_point)
	
	# zoom camera out
	node_tween.remove_all()
	node_tween.interpolate_property(node_cam, "zoom", node_cam.zoom, Vector2(1, 1), step2_dur, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	node_tween.interpolate_property(node_cam, "position", node_cam.position, node_cam.position + step2_cam_delta, step2_dur, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	node_tween.interpolate_method(node_tongue, "apply_force", Vector2.LEFT * 20, Vector2.RIGHT.rotated(-PI/4) * 25, step2_dur)
	node_tween.start()
	
	# logo animation Out
	node_logo_anim_player.play("Out")
	
	yield(node_tween, "tween_all_completed")
	
	
	# 3
	Global.node_player.release_tongue()
	Engine.time_scale = 1
	Global.node_player.is_paused = false
	
	node_tween.remove_all()
	node_tween.interpolate_property(Global.node_player, "rotation", Global.node_player.rotation, 0.0, step3_dur, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	node_tween.interpolate_property(node_cam, "position", node_cam.position, node_cam.position + step3_cam_delta, step3_dur)
	node_tween.start()
	
	yield(node_tween, "tween_all_completed")
	
	
	# 4
	# slowmo
	Global.node_player.joystick_inp_vec = Vector2.RIGHT
	
#	node_tween.remove_all()
#	node_tween.interpolate_property(Engine, "time_scale", 1, 0.1, step4_dur)
#	node_tween.interpolate_property(node_cam, "position", node_cam.position, node_cam.position + step4_cam_delta, step4_dur)
#	node_tween.start()
#
#
#	yield(node_tween, "tween_all_completed")
	Global.node_cam = node_cam
#	Global.node_player.is_paused = true
#	Engine.time_scale = 1
	
	emit_signal("animation_completed")
