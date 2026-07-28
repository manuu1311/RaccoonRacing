extends Node
class_name CarController

var player:Player
var forward:bool
var brake:bool
var left:bool
var right:bool
var special:bool
var cancelturn:bool

func _init(playerinst:Player) -> void:
	player=playerinst
	
func GetInput() -> void:
	if is_multiplayer_authority():
		handle_input()

func handle_input()->void:
	pass
