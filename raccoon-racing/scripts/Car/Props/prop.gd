extends Node
class_name Prop


var player:Player;
var proptype:int
var tick_end:int
var use_time:int

func _init(playerinst:Player)->void:
	player = playerinst;

func run_tick() -> void:
	pass

func run()->void:
	pass

func del()->void:
	pass
