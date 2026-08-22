extends Node2D

#region export variables
@export_group("General Settings")
##map id, 1-4
@export_range(1, 4) var map_id: int = 1
@export var number_of_laps:int=3
@export var is_hovercraft:bool=false
#endregion

#region class internal variables
#endregion
var map:Map

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SetVars(map_id,number_of_laps,is_hovercraft)
	LoadMap(GameData.currentMap)


## Set global GameData variables
func SetVars(mapid:int,numlaps:int,ishovercraft:bool)->void:
	GameData.currentMap=mapid
	GameData.currentLaps=numlaps
	if ishovercraft:
		GameData.current_vehicle=GameData.VehicleType.HOVERCRAFT
	else:
		GameData.current_vehicle=GameData.VehicleType.CAR

func LoadMap(map_num:int) -> void:
	var map_path: String = "res://Assets/Scenes/Screens/maps/Map%02d.tscn" % map_num

	if ResourceLoader.load_threaded_get_status(map_path) == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		ResourceLoader.load_threaded_request(map_path)
	while ResourceLoader.load_threaded_get_status(map_path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame

	var packedmap:PackedScene = ResourceLoader.load_threaded_get(map_path) as PackedScene
	map=packedmap.instantiate()
	add_child(map)
