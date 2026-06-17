extends Node2D
class_name GameManager

#TODO:save reference ofplayer or car?
var players: Array[Player]
var cars:Array[Car]
var fcsCar:Car
#TODO: should be created
@onready var map: Map = $Map

func _ready() -> void:
	#TODO: also select maps accordingly
	var minimap_instance:CanvasLayer
	if GameData.current_vehicle==GameData.VehicleType.CAR:
		minimap_instance = preload("res://Assets/Scenes/Screens/maps/Minimap01.tscn").instantiate()
	else:
		minimap_instance = preload("res://Assets/Scenes/Screens/maps/Minimap02.tscn").instantiate()
	minimap_instance.name = "Minimap"
	map.add_child(minimap_instance)
	map.deferredInit()
	#TODO: where is it actually implemented? what are the references like?
	for i:int in GameData.OrderInfo: 
		var player:Player=GameData.PlayersArr[i]
		var carinstance:Car = preload("res://Assets/Scenes/Screens/Car.tscn").instantiate()
		if player.IsPlayering():
			carinstance.setup(map,player.PlayerID,true)
			carinstance.add_child(HumanCarController.new(player))
			Game.fcsCar=carinstance
		else:
			carinstance.setup(map,player.PlayerID,false)
			carinstance.add_child(AICarController.new(player))
		add_child(carinstance)
		carinstance.global_position=map.StartPosArr[i].global_position
		player.SetCar(carinstance)

	
	
	
func register(player:Player):
	players.append(player)

func focusCar(car:Car):
	fcsCar=car
