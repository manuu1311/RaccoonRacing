extends Node2D

var players: Array[Player]
var fcsCar:Car
#TODO: should be created
@onready var map: Node2D = $Map

func _ready() -> void:
	#TODO: also select maps accordingly
	var minimap_instance:CanvasLayer
	if GameData.current_vehicle==GameData.VehicleType.CAR:
		minimap_instance = preload("res://Assets/Scenes/Screens/maps/Minimap01.tscn").instantiate()
	else:
		minimap_instance = preload("res://Assets/Scenes/Screens/maps/Minimap02.tscn").instantiate()
	minimap_instance.name = "Minimap"
	map.add_child(minimap_instance)
	
func register(player:Player):
	players.append(player)

func focusCar(car:Car):
	fcsCar=car
