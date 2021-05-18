extends Node2D

class_name Fly


onready var node_collectable = $Collectable
onready var node_move_zone_poly = $Polygon2D
onready var node_wait_timer = $TimerWait
onready var node_tween_move = $TweenMove

export var move_dur = 0.2
export var wait_dur = 0.5

var poly_triangles = []
var poly_triangles_weights = []


func _ready():
	node_collectable.connect("collected", self, "collect")
	
	ini_move_zone()
	
	move()


func get_class():
	return "Fly"


func ini_move_zone():
	# fill poly triangles
	var triangulated_poly = Geometry.triangulate_polygon(node_move_zone_poly.polygon)
	for i in range(triangulated_poly.size()/3):
		
		var point_a = node_move_zone_poly.polygon[triangulated_poly[i * 3]]
		var point_b = node_move_zone_poly.polygon[triangulated_poly[i * 3 + 1]]
		var point_c = node_move_zone_poly.polygon[triangulated_poly[i * 3 + 2]]
		
		poly_triangles.append([point_a, point_b, point_c])
	
	# fill poly triangles weights
	var areas = []
	var total_area = 0.0
	
	for triangle in poly_triangles:
		var area = Math.get_triangle_area(triangle)
		areas.append(area)
		
		total_area += area
	
	var total_weigth = 0.0
	for area in areas:
		var area_coeff = area / total_area
		total_weigth += area_coeff
		poly_triangles_weights.append(total_weigth)


func get_random_move_zone_point():
	randomize()
	
	# get random triangle by weight
	var rand_float = randf()
	
	for i in range(poly_triangles_weights.size()):
		if rand_float <= poly_triangles_weights[i]:
			
			# get random point on triangle
			return Math.get_random_point_on_triangle(poly_triangles[i])
	
	print("error")


func move():
	var new_pos = get_random_move_zone_point()
	
	node_tween_move.remove_all()
	node_tween_move.interpolate_property(node_collectable, "position", node_collectable.position, new_pos, move_dur)
	node_tween_move.start()


func wait():
	node_wait_timer.start(wait_dur)


func collect():
	Global.node_player.add_superjump_pts(1)
	queue_free()


func _on_TweenMove_tween_all_completed():
	wait()


func _on_TimerWait_timeout():
	move()


func save():
	return {
		"filename" : get_filename(),
		"parent" : get_parent().get_path(),
		"pos_x" : position.x,
		"pos_y" : position.y,
		"rotation": rotation,
		"wait_dur": wait_dur,
		"move_dur": move_dur,
	}


func load_from_data(data):
	for key in data:
		if not (key == "filename"
				or key == "parent"
				or key == "pos_x"
				or key == "pos_y"):
			self[key] = data[key]
