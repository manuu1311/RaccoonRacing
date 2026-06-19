extends Node

var players: Array[Player]
var fcsCar:Car

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func register(player:Player)->void:
	players.append(player)

func focusCar(car:Car)->void:
	fcsCar=car
