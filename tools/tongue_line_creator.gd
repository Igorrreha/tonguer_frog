extends EditorScript

tool


func _run():
	var root = get_scene()
	
	var node_line = root.get_node("TongueLine")
	var node_mid_line = root.get_node("TongueMidLine")
	var node_end_line = root.get_node("TongueEndLine")
	
	var points = []
	# append points from segment
	for segment in root.get_children():
		if segment is TongueSegment:
			points.append(segment.global_position)
	
	node_line.points = points
	
	# get mid points
	var mid_points = []
	for i in range(1, points.size()):
		mid_points.append(((points[i] - points[i-1]) / 2) + points[i-1])
	
	node_mid_line.points = mid_points
	
	var end_points = [points[0]]
	end_points.append_array(mid_points)
	end_points.append(points[points.size()-1])
	
	node_end_line.points = end_points
