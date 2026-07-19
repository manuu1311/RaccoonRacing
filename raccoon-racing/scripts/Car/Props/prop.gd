extends Node
class_name Prop


var player:Player;
var proptype:int

func _init(playerinst:Player)->void:
	player = playerinst;

func run_tick(_tick: int, _is_fresh: bool) -> void:
	pass

func run()->void:
	pass

func del()->void:
	pass
