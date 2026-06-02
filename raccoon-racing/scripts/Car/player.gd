extends Node2D
class_name  Player

var playerID:int=0
var isResetting:bool=false
@onready var sounds: CarSounds = $"../Sounds"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#TODO: register only playering player
	Game.register(self)
