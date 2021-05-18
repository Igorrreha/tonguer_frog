extends EditorScript

tool


var ground_color = Color("#0e1511")


func _run():
	var root = get_scene()
	
	var walls_cont = root.get_node("StaticBodies")
	
	# remove all childs
	for child in walls_cont.get_children():
		if child is CollisionPolygon2D:
			
			var new_poly = Polygon2D.new()
			
			new_poly.polygon = child.polygon
			walls_cont.add_child(new_poly)
			new_poly.set_owner(walls_cont.get_tree().get_edited_scene_root())
			
			new_poly.color = ground_color
			
		else:
			child.free()
