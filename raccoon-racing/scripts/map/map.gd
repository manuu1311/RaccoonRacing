extends Node2D
class_name Map

var AddspeedNum: int
var BsNum:int
#TODO: what is it? looks like array of linewidth
var CanBeJumpWall
var GrassNum:int
var GroupGrassGroupNum:int
var GroupGrassNum:int
var JumpNum:int
var JumpWallGroupNum:int
var JumpWallNum:int
var LapsTotal:int
#TODO: array of lines i guess?
var LinePointArr:Array[int]
var PointNum:int
#TODO: maybe take markers from the scene
var Points;
#TODO: same as above
var PropPointArr;
var PropboxNum:int
#changed from original one
var IsHovercraft:bool
var WallGroupNum:int
var WallNum:int
var WanPointArr:Array[int]
var ScaledTimes:float
#TODO: int or float?
var TileWidth:int= 0
var TileHeight:int = 0
var TileNum:int = 0
var CupMapi:int = 0
var CupMapj = 0
var MapBy:int = 10000
var MapTy:int = -10000
var MapLx:int = -10000
var MapRx:int = 10000
var MoO:int = 10
@onready var top2: Node2D = $Visuals/Ground/Top2
#jump wall points
#TODO: are they saved as vec2?
var canBeJumpWall:Array[Vector2]
# Called when the node enters the scene tree for the first time.
#offsets useful for minimap
var offsethc: Vector2
var offsetcar:Vector2

func _ready() -> void:
	if GameData.current_vehicle==GameData.VehicleType.CAR:
		#hide top2
		top2.hide()


func getHitFace(point:Vector2)->Vector2:
	return Vector2(NAN,NAN)
	
func getCollisionFace(point:Vector2)->bool:
	return false
	
#TODO: first argument in output of getcollisionface
func GetHitEventStatus(varx,playerid:int)->void:
	pass
