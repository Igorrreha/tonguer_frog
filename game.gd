extends Node

var node_tongue: Tongue


func _ready():
	load_persist_nodes()
	connect_persist_signals()


func load_persist_nodes():
	node_tongue = $Tongue


func connect_persist_signals():
	Global.node_player.connect("pin_tongue", node_tongue, "player_pin")
	Global.node_player.connect("release_tongue", node_tongue, "player_unpin")
	Global.node_player.connect("swing_apply_force", node_tongue, "apply_force")


func load_game():
	load_persist_nodes()
	sort_persist_children()
	connect_persist_signals()


func sort_persist_children():
	move_child(node_tongue, 0)
	move_child(Global.node_player, 2)


