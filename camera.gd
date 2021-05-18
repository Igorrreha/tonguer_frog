extends Camera2D


onready var node_anim_player = $AnimationPlayer


func screen_shake():
	node_anim_player.play("Shake")
