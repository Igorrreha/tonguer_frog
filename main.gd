extends Node

onready var node_ui = $ParallaxBackground/UI
onready var node_game = $Game
onready var node_checkpoints
onready var node_jump_force_bar = $ParallaxBackground/UI/JumpForceBar
onready var node_input = $ParallaxBackground/UI/Input
onready var node_joystick_aim = $ParallaxBackground/UI/Input/JoystickAim
onready var node_load_game_timer = $LoadGameTimer
onready var node_cutscene_player = $CutscenePlayer

var node_superjump_bar: SuperjumpBar
var cur_lvl = 1


func _ready():
	Global.node_player.connect("cur_jump_force_changed", node_jump_force_bar, "set_value")
	Global.node_player.connect("jump", node_jump_force_bar, "sparkle")
	Global.node_player.connect("superjump", node_jump_force_bar, "sparkle")
	Global.node_player.connect("died", node_load_game_timer, "start")
	
	node_input.connect("touch_start", Global.node_player, "action_touch_start")
	node_input.connect("touch_end", Global.node_player, "action_touch_end")
	node_joystick_aim.connect("output", Global.node_player, "joystick_input")
	
	load_main_data()
	
	load_persist_nodes()
	connect_persist_signals()
	
	node_cutscene_player.intro()
	yield(node_cutscene_player, "animation_completed")
	
	load_level()
	
	node_ui.fade_in()


func load_level():
	# load lvl scene
	var node_lvl = load("res://lvl/Lvl" + str(cur_lvl) + ".tscn").instance()
	var player_spawn_point = node_lvl.get_node("PlayerStartPos")
	
	node_lvl.global_position = Global.node_player.global_position - Vector2(player_spawn_point.position.x, 0)
	add_child(node_lvl)
	
	# connect children signals
	node_checkpoints = node_lvl.get_node("Checkpoints")
	
	for checkpoint in node_checkpoints.get_children():
		checkpoint.connect("activated", self, "save_game")
	
#	# move camera
	node_cutscene_player.node_tween.remove_all()
	var new_cam_pos = player_spawn_point.global_position
	node_cutscene_player.node_tween.interpolate_property(Global.node_cam, "global_position", 
			Global.node_cam.global_position, new_cam_pos, 1.0, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	
	node_cutscene_player.node_tween.start()
	
	# set player on
	Global.node_player.move_vec.x = 0
	Global.node_player.is_paused = false
	yield(node_cutscene_player.node_tween, "tween_all_completed")
	
	Global.node_player.node_cam.offset_h = 0
	Global.node_player.node_cam.offset_v = 0
	Global.node_player.node_cam.current = true
	Global.node_player.inp_locked = false


func load_persist_nodes():
	node_superjump_bar = $ParallaxBackground/UI/SuperjumpPtsBar


func connect_persist_signals():
	Global.node_player.connect("superjump_pts_changed", node_superjump_bar, "set_value")


func _input(event):
	if event.is_action_pressed("save"):
		cur_lvl = 1
		save_main_data()
	
	if event.is_action_pressed("load"):
		load_main_data()
	
	if event.is_action_pressed("restart"):
		get_tree().reload_current_scene()


func save_main_data():
	var save_game = File.new()
	save_game.open("user://savegame.save", File.WRITE)
	
	var main_data = {
		"cur_lvl": cur_lvl
	}
	
	save_game.store_line(to_json(main_data))
	
	save_game.close()


func load_main_data():
	var save_game = File.new()
	if not save_game.file_exists("user://savegame.save"):
		return # Error! We don't have a save to load.
	
	# load the file line by line and process that dictionary to restore
	# the object it represents.
	save_game.open("user://savegame.save", File.READ)
	
	var data = parse_json(save_game.get_line())
	
	prints(cur_lvl, data.cur_lvl)
	cur_lvl = data.cur_lvl


func save_game():
	var save_game = File.new()
	save_game.open("user://savegame_checkpoint.save", File.WRITE)
	
	save_nodes_by_class("Player", save_game)
	save_nodes_by_class("Bird", save_game)
	save_nodes_by_class("Tongue", save_game)
	save_nodes_by_class("Fly", save_game)
	save_nodes_by_class("SuperjumpBar", save_game)
	
	save_game.close()


func save_nodes_by_class(save_class, save_file):
	var save_nodes = get_tree().get_nodes_in_group("Persist")
	for node in save_nodes:
		if node.get_class() == save_class:
			# Check the node is an instanced scene so it can be instanced again during load.
			if node.filename.empty():
				print("persistent node '%s' is not an instanced scene, skipped" % node.name)
				continue
			
			# Check the node has a save function.
			if !node.has_method("save"):
				print("persistent node '%s' is missing a save() function, skipped" % node.name)
				continue
			
			# Call the node's save function.
			var node_data = node.call("save")

			# Store the save dictionary as a new line in the save file.
			save_file.store_line(to_json(node_data))


func load_game():
	var save_game = File.new()
	if not save_game.file_exists("user://savegame_checkpoint.save"):
		return # Error! We don't have a save to load.

	# we need to revert the game state so we're not cloning objects
	# during loading. This will vary wildly depending on the needs of a
	# project, so take care with this step.
	# for our example, we will accomplish this by deleting saveable objects.
	var save_nodes = get_tree().get_nodes_in_group("Persist")
	for i in save_nodes:
		if not i is Player:
			i.free()

	# load the file line by line and process that dictionary to restore
	# the object it represents.
	save_game.open("user://savegame.save", File.READ)
	while save_game.get_position() < save_game.get_len():
		# het the saved dictionary from the next line in the save file
		var data = parse_json(save_game.get_line())
		
		# firstly, we need to create the object and add it to the tree and set its position.
		# load player
		var obj
		if data["filename"] == Global.node_player.get_filename():
			obj = Global.node_player
			
		# load another nodes
		else:
			obj = load(data["filename"]).instance()
			var parent = get_node(data["parent"])
			
			parent.add_child(obj)
		
		if data.has("pos_x"):
			obj.position = Vector2(data["pos_x"], data["pos_y"])
		
		if obj.has_method("load_from_data"):
			obj.load_from_data(data)
	
	node_game.load_game()
	
	save_game.close()
	load_persist_nodes()
	connect_persist_signals()


func _on_LoadGameTimer_timeout():
	load_game()
