extends Node


func get_triangle_area(points_arr):
	var a = (points_arr[0] - points_arr[1]).length()
	var b = (points_arr[1] - points_arr[2]).length()
	var c = (points_arr[2] - points_arr[0]).length()
	
	var p = (a + b + c) / 2
	
	var area = sqrt(p * (p-a) * (p-b) * (p-c))
	
	return area


func get_random_point_on_triangle(points_arr):
	var vec_a = points_arr[1] - points_arr[0]
	var vec_b = points_arr[2] - points_arr[0]
	
	var rand_n1 = randf()
	var rand_n2 = randf()
	
	if (rand_n1 + rand_n2) > 1.0:
		rand_n1 = 1 - rand_n1
		rand_n2 = 1 - rand_n2
	
	var rand_point = vec_a * rand_n1 + vec_b * rand_n2 + points_arr[0]
	
	return rand_point
