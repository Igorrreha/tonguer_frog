extends Node2D

class_name Tongue


var segments_count = 7
var is_active = false

var segments = []
var node_last_segment: TongueSegment
var node_anchor: GrabPoint
#var node_remote_transform: RemoteTransform2D
var node_line: Line2D


func get_class():
	return "Tongue"


func _physics_process(delta):
	if is_active:
		# remote rotation
#		var preprev_seg = segments[segments.size()-2]
#		node_remote_transform.rotation = node_anchor.global_position.angle_to_point(node_remote_transform.global_position) - preprev_seg.rotation
		
		update_player_pos_and_rot()
		draw_tongue_line()


func update_player_pos_and_rot():
	# update rotation
	var pre_last_seg = segments[segments.size()-2]
	Global.node_player.rotation = pre_last_seg.global_position.angle_to_point(Global.node_player.node_tongue_start_point.global_position)
	
	# update position
	Global.node_player.global_position = node_last_segment.global_position - (Global.node_player.node_tongue_start_point.global_position - Global.node_player.global_position)
	


# make tongue visible
func draw_tongue_line():
	var segm_points = []
	# get points from segments
	for segment in get_children():
		if segment is TongueSegment:
			segm_points.append(segment.global_position)
	
	# get mid points
	var mid_points = []
	for i in range(1, segm_points.size()):
		mid_points.append(((segm_points[i] - segm_points[i-1]) / 2) + segm_points[i-1])
	
	var points = [node_anchor.global_position, segm_points[0]]
	points.append_array(mid_points)
	points.append(Global.node_player.node_tongue_start_point.global_position)
	
	node_line.points = points


func player_pin(target_obj: GrabPoint):
	node_anchor = target_obj
	
	var vec_from_target_to_player = Global.node_player.node_tongue_start_point.global_position - node_anchor.global_position
	
	# add main joint
	var first_joint = Global.tscn_tongue_joint.instance()
	first_joint.global_position = node_anchor.global_position
	add_child(first_joint)
	first_joint.node_a = first_joint.get_path_to(node_anchor)
	
	var cur_joint = first_joint
	
	# add and connect segments
	var pos_step = vec_from_target_to_player.length() / segments_count
	for i in range(0, segments_count):
		var pos = vec_from_target_to_player.normalized() * (pos_step * i + pos_step) 
		
		var segment = Global.tscn_tongue_segment.instance()
		segment.global_position = node_anchor.global_position + pos
		add_child(segment)
		segments.append(segment)
		
		cur_joint.node_b = cur_joint.get_path_to(segment)
		
		cur_joint = segment.get_child(1)
		cur_joint.node_a = cur_joint.get_path_to(segment)
		
		node_last_segment = segment
	
	
	# create and connect remote transform node in last segment
#	var remote_transform = RemoteTransform2D.new()
#	remote_transform.update_position = true
#	remote_transform.update_rotation = true
#	remote_transform.update_scale = false
#	node_last_segment.add_child(remote_transform)
#
#	node_remote_transform = remote_transform
	
	# add more mass to last segment
	node_last_segment.mass = 3
	# apply impulse to last segment
	node_last_segment.apply_central_impulse(Global.node_player.move_vec)
	
#	node_remote_transform.remote_path = node_remote_transform.get_path_to(Global.node_player)
	
#	cur_joint.node_b = cur_joint.get_path_to(node_remote_transform)
	
	is_active = true
	
	
	# add tongue line
	var line = Global.tscn_tongue_line.instance()
	add_child(line)
	
	node_line = line
	
	
	# exec anchor func
	node_anchor.on_player_pin()


func player_unpin():
	# apply velocity to player
	Global.node_player.move_vec = node_last_segment.linear_velocity
	
	# exec anchor func
	node_anchor.on_player_unpin()
	
	# clear vars
	segments = []
	node_anchor = null
	node_last_segment = null
#	node_remote_transform = null
	node_line = null
	
	# remove Tongue parts
	for child in get_children():
		child.queue_free()
	
	# set unactive
	is_active = false


func apply_force(vec):
	if is_active:
		node_last_segment.apply_central_impulse(vec)


func save():
	var data = {
		"filename" : get_filename(),
		"parent" : get_parent().get_path(),
		"pos_x" : position.x,
		"pos_y" : position.y,
		"node_anchor_is_null": node_anchor == null
	}
	
	if not node_anchor == null:
		data.node_anchor_path = node_anchor.get_path()
	
	return data


func load_from_data(data):
	if not data.node_anchor_is_null:
		node_anchor = get_node(data.node_anchor_path)
		player_pin(node_anchor)
