extends Node2D
class_name Map

var scaledTimes:float
var glideGratingNum:float = 0.0002
var rollGratingNum:float = 0.02
var grassGratingNum:float = 0.01
#jump wall points
#TODO: are they saved as vec2?
var canBeJumpWall:Array[Vector2]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func getHitFace(point:Vector2)->Vector2:
	return Vector2(NAN,NAN)
	
func getCollisionFace(point:Vector2)->bool:
	return false
	
#TODO: first argument in output of getcollisionface
func GetHitEventStatus(varx,playerid:int)->void:
	pass
