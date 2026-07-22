extends Node
class_name CarController

var player:Player
var forward:bool
var brake:bool
var left:bool
var right:bool
var special:bool
var special_buffered:bool

func _init(playerinst:Player) -> void:
	player=playerinst
	
func _process(_delta: float) -> void:
	if is_multiplayer_authority():
		handle_input()
		special=special_buffered
		special_buffered=false

func handle_input()->void:
	pass
