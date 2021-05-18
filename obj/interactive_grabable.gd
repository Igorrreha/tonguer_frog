extends Node2D

class_name InteractiveGrabable


export var can_be_pinned_once = true

enum STATES {
	BEFORE_PINNED, PINNED, AFTER_PINNED
}
var cur_state = STATES.BEFORE_PINNED

onready var node_grab_point: GrabPoint = $GrabPoint


func _ready():
	node_grab_point.connect("player_pinned", self, "on_player_pin")
	node_grab_point.connect("player_unpinned", self, "on_player_unpin")


func on_player_pin():
	cur_state = STATES.PINNED


func on_player_unpin():
	if can_be_pinned_once:
		node_grab_point.node_collider.disabled = true
	
	cur_state = STATES.AFTER_PINNED
