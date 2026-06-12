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
    #TODO: where is it actually implemented? what are the references like?
    for i in range(len(map.StartPosArr)):
        var carinstance:Car = preload("res://Assets/Scenes/Screens/Car.tscn").instantiate()
        add_child(carinstance)
        carinstance.global_position=map.StartPosArr[i].global_position
        if i==0:
            carinstance.playering=true
        else:
            carinstance.playering=false
    
    
    
func register(player:Player):
    players.append(player)

func focusCar(car:Car):
    fcsCar=car
