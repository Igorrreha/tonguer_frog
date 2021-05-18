extends EditorScript

tool


var tscn_tongue_segment = load("res://TongueSegment.tscn")
var tscn_tongue_joint = load("res://TongueJoint.tscn")
var segments_count = 10


func _run():
	var root = get_scene()
	
	# remove all childs
	for child in root.get_children():
		child.free()
	
	# add main joint
	var first_joint = tscn_tongue_joint.instance()
	root.add_child(first_joint)
	first_joint.set_owner(root.get_tree().get_edited_scene_root())
	
	var cur_joint = first_joint
	
	# add and connect segments
	for i in range(0, segments_count):
		var segment = tscn_tongue_segment.instance()
		root.add_child(segment)
		segment.set_owner(root.get_tree().get_edited_scene_root())
		
		cur_joint.node_b = cur_joint.get_path_to(segment)
		
		cur_joint = segment.get_child(1)
		cur_joint.node_a = cur_joint.get_path_to(segment)
	
	var remote_transform = RemoteTransform2D.new()
	root.add_child(remote_transform)
	remote_transform.set_owner(root.get_tree().get_edited_scene_root())
	
	remote_transform.update_position = false
	remote_transform.update_rotation = false
	remote_transform.update_scale = false
	
	cur_joint.node_b = cur_joint.get_path_to(remote_transform)
