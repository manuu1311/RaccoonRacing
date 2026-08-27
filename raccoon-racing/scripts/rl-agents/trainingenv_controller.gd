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
	await LoadMap(GameData.currentMap)
	SetupPlayers()


##setup players for training env
func SetupPlayers()->void:
	'''
	carinstance.setup(map,player.PlayerID,true,player)
	var controller:CarController=HumanCarController.new(player)
	carinstance.add_child(controller)
	carinstance.controller=controller
	carinstance.CharID=player.charid
	carinstance.global_position=map.StartPosArr[i].global_position
	carinstance.rotation=map.StartPosArr[i].rotation
	player.SetCar(carinstance)
	player.ResetPlayer(i)
	'''
	var caragent:CarAgent=(load('res://Assets/Scenes/rl-agents/car-agent.tscn') as PackedScene).instantiate()
	var newplayer:Player=Player.new(0,Player.control_type.RLTRAINING)
	newplayer.charid=2
	GameData.PlayersArr.append(newplayer)
	caragent.car.setup(map,newplayer.PlayerID,true,newplayer)
	var controller:CarController=HumanCarController.new(newplayer)
	caragent.car.add_child(controller)
	caragent.car.controller=controller
	caragent.car.CharID=newplayer.charid
	caragent.car.global_position=map.StartPosArr[0].global_position
	caragent.car.rotation=map.StartPosArr[0].rotation
	newplayer.SetCar(caragent.car)
	newplayer.ResetPlayer(0)
	map.add_child(caragent)

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
	# 2. Determine the minimap suffix based on the vehicle type
	var is_car: bool = (GameData.current_vehicle == GameData.VehicleType.CAR)
	var suffix: String = "1" if is_car else "2"

	# 3. Format the minimap path
	# Map 1 uses 01/02, Map 2 uses 11/12, Map 3 uses 21/22, etc.
	var minimap_index: int = map_num - 1
	var minimap_path: String = "res://Assets/Scenes/Screens/maps/Minimap%d%s.tscn" % [minimap_index, suffix]

	# 4. Instantiate and attach the minimap
	@warning_ignore("unsafe_method_access")
	var minimap: SubViewport = load(minimap_path).instantiate() as SubViewport
	minimap.name = "Minimap"
	#minimap_canvas.add_child(minimap)
	add_child(minimap)
	map.minimap=minimap.get_node('View/MapSprite')
