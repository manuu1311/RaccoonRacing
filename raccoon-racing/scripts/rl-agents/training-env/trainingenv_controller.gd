extends Node2D
class_name EnvManager 

# TODO: rl agents share props for some reason, they dont have cooldown
# TODO: ai players do not reset pointid after race over

#region export variables
@export_group("General Settings")
##map id, 1-4
@export_range(1, 4) var map_id: int = 1
@export var number_of_laps:int=3
@export var is_hovercraft:bool=false
@export_group("Multi-Agent Settings")
@export_range(1, 4) var number_of_rl_learning: int = 1
@export_range(0, 4) var number_of_ai_learning: int = 1
@export_group("Agent Settings")
@export_range(1, 6) var char_id: int = 1
@export_group("Training Settings")
@export var control_mode: SyncNode.ControlModes = SyncNode.ControlModes.TRAINING
@export_range(1, 10, 1, "or_greater") var action_repeat := 8
@export_range(0, 10, 0.1, "or_greater") var speed_up := 1.0
@export_range(50, 1000, 5, "or_greater") var timer_duration := 600
#endregion

#region class internal variables
var map:Map
signal setup_ready_signal
signal reset_signal
var timer:Timer
var needs_reset:=false
#endregion

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	## TODO: currently disabling ai props
	GameData.AICanUseProp=false
	timer=Timer.new()
	add_child(timer)
	timer.timeout.connect(_handle_reset_sequence)
	SetVars(map_id,number_of_laps,is_hovercraft)
	await LoadMap(GameData.currentMap)
	SetupPlayers()
	setup_ready_signal.emit(GameData.PlayersArr[0].car,map)
	GameStart()
	await get_tree().create_timer(2).timeout
	var sync_node := SyncNode.new()
	sync_node.control_mode = control_mode
	sync_node.action_repeat=action_repeat
	add_child(sync_node)
	if not sync_node.is_node_ready():
		await sync_node.ready
	Engine.physics_ticks_per_second = int(35 * speed_up)
	Engine.time_scale = speed_up
	Engine.max_physics_steps_per_frame = int(35 * speed_up)
	_reset_env()

func _process(_delta: float) -> void:
	# reset env
	if needs_reset:
		_reset_env()
		needs_reset=false
		
func GameStart()->void:
	_start_players()
	NetworkTime.start()
	map.PlayersReadySignalEmit()


func _start_players()->void:
	for player:Player in GameData.PlayersArr:
		player.StartRace()

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
	var idx:=0
	for i in range(number_of_rl_learning):
		var caragent:CarAgent=(load('res://Assets/Scenes/rl-agents/agent/car-agent.tscn') as PackedScene).instantiate()
		var newplayer:Player=RLPlayer.new(0,Player.control_type.RLTRAINING)
		newplayer.charid=char_id
		newplayer.racefinished.connect(_race_over)
		GameData.PlayersArr.append(newplayer)
		caragent.car.setup(map,newplayer.PlayerID,true,newplayer)
		caragent.car.CharID=newplayer.charid
		var controller:CarController=RLCarController.new(newplayer,caragent)
		#var controller:CarController=HumanCarController.new(newplayer)
		caragent.car.add_child(controller)
		caragent.car.controller=controller
		caragent.car.global_position=map.StartPosArr[idx]
		caragent.car.rotation=map.StartPosArrRot[idx]
		# connect signal
		reset_signal.connect(caragent.training_controller._end_episode)
		newplayer.racefinished.connect(caragent.training_controller._end_race)
		newplayer.SetCar(caragent.car)
		newplayer.ResetPlayer(idx)
		map.add_child(caragent)
		idx+=1
	for i in range(number_of_ai_learning):
		var newcar:Car=(load('res://Assets/Scenes/Screens/Car.tscn') as PackedScene).instantiate()
		var newplayer:AIPlayer=AIPlayer.new(1,Player.control_type.AI)
		newplayer.AiReflect=10
		newplayer.charid=char_id
		newplayer.racefinished.connect(_race_over)
		GameData.PlayersArr.append(newplayer)
		newcar.setup(map,newplayer.PlayerID,true,newplayer)
		var controller:CarController=AICarController.new(newplayer)
		newcar.add_child(controller)
		newcar.controller=controller
		newcar.CharID=1
		newcar.global_position=map.StartPosArr[idx]
		newcar.rotation=map.StartPosArrRot[idx]
		newplayer.SetCar(newcar)
		newplayer.ResetPlayer(idx)
		map.add_child(newcar)
		idx+=1
		
	# add tracking info in game data
	GameData.OrderInfo=[]
	for i in range(number_of_ai_learning+number_of_rl_learning):
		GameData.OrderInfo.append(i)
	GameData.Ranking=GameData.OrderInfo

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


# called after each player finishes the race
func _race_over(_id:int)->void:
	var check:=true
	for player in GameData.PlayersArr:
		if player.current_control==Player.control_type.RLTRAINING:
			if player.IsPlayering():
				check=false
				break
	if check:
		_handle_reset_sequence()

func _handle_reset_sequence() -> void:
	reset_signal.emit()
	needs_reset = true

# reset environment after episode ends
func _reset_env()->void:
	# shuffle players
	var temp_players:Array[Player]=GameData.PlayersArr.duplicate()
	temp_players.shuffle()
	# shuffle character ids
	var character_ids:Array[int]=[1,2,3,4,5,6]
	for idx in range(len(temp_players)):
		var player:=temp_players[idx]
		player.car.global_position=map.StartPosArr[idx]
		player.car.rotation=map.StartPosArrRot[idx]
		player.Laps=0
		player.LapsLock=false
		var newcharid:int=character_ids.pick_random()
		character_ids.erase(newcharid)
		player.charid=newcharid
		player.car.CharID=newcharid
	# clear map and player status
	_clear_map()
	# restart cars
	_start_players()
	timer.start(timer_duration)

# remove all props from players and map
func _clear_map()->void:
	# delete player status effects
	for player:Player in GameData.PlayersArr:
		for i in range(10):
			player.prop.del_prop_by_type(i)
		# reset all player variables
		player.RemoveShield()
		player.ClearProps()
		player.ClearPropBox(0)
		player.car.IsUsingProp=false
		player.car.CanUseProp=0
		player.car.NowPorpId=0
	# delete props in map
	for node:Node2D in map.prop_spawn_node.get_children():
		if is_instance_of(node,BsInMap):
			var bs:=node as BsInMap
			# if bs is not permanent (part of the map)
			if bs.lifetimeticks!=0:
				map.DelEventInMap(bs.edface.getId())
		else:
			if is_instance_of(node,BombInMap) or is_instance_of(node,HoneyBombInMap):
				map.DelEventInMap((node as EventInMap).edface.getId())
			else:
				node.queue_free()
