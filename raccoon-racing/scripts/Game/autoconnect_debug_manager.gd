extends Node2D

var fcsCar:Car
@onready var map: Map
@onready var hud: HUDManager = $Hud
var MoveSceneCenterSpeed:int = 2;
var MoveSceneAngleSpeed:float = 0.2;
@onready var camera: Camera2D = $Camera2D
var stagesize:Vector2
var scenecenterpos:Vector2
var SceneAngleMoveExpandPos:Vector2
var SceneAngleMoveExpandNowPos:Vector2
@export var MapNum:int=1
@export var mainchar:int=1
@export var IsMultiplayer:bool=true
var personalid:int
signal ClientRegistrationComplete

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	DisableHud()
	await NetworkTime.after_sync
	NetworkSetup()
	LoadMinimap()
	GameData.currentMap=MapNum
	GameData.currentCharacter=mainchar
	stagesize=map.GetMapSize()
	SceneAngleMoveExpandPos = Vector2(150,0)
	SceneAngleMoveExpandNowPos = Vector2.ZERO
	map.deferredInit()
	GameData.PlayersArr=[]
	GameData.OrderInfo=[]
	GameData.Ranking=[]
	if multiplayer.is_server():
		CreatePlayer(GameData.PlayersArr.size(),Player.control_type.HUMAN,GameData.currentCharacter,1)
		CreatePlayer(GameData.PlayersArr.size(),Player.control_type.AI,1,1)
		personalid=0
		if IsMultiplayer:
			ClientRegistrationComplete.connect(RemoteStartRace)
		else:
			RemoteStartRace()
	else:
		RequestRegister()


func _process(_delta: float) -> void:
	if fcsCar!=null:
		camera.zoom=Vector2.ONE*(1 - fcsCar.jumpCurrheight * 0.005)
		SetSceneAngleExpand(fcsCar.global_position,fcsCar.rotation-PI/2)
		SceneCenterMoveToPos()
		if !fcsCar.isLock:
			UpdateOrderResult()



func focusCar(player:Player,car:Car)->void:
	GameData.FocusCar=car
	fcsCar=car
	GameData.FocusPlayer=player

func CreatePlayer(id:int,type:Player.control_type,charid:int,authority:int)->void:
	var player:Player
	if type==Player.control_type.HUMAN:
		player=Player.new(id,type)
	else:
		player=AIPlayer.new(id,type)
	player.charid=charid
	player.NetworkID=authority
	GameData.PlayersArr.append(player)
	GameData.OrderInfo.append(id)
	GameData.Ranking.append(id)

func RemoteStartRace()->void:
	CreateCars.rpc()
	RaceStart.rpc()

@rpc('authority','call_local','reliable')
func CreateCars()->void:
	for player:Player in GameData.PlayersArr:
		RegisterPlayer(player)

func RegisterPlayer(player:Player)->void:
	var carinstance:Car = preload("res://Assets/Scenes/Screens/Car.tscn").instantiate()
	var controller:CarController
	if player.current_control==Player.control_type.HUMAN:
		controller=HumanCarController.new(player)
	else:
		controller=AICarController.new(player)
		
	carinstance.setup(map,player.PlayerID,true,player)
	carinstance.add_child(controller)
	carinstance.controller=controller
	carinstance.CharID=player.charid
	carinstance.name="Car"+str(player.PlayerID)
	carinstance.set_multiplayer_authority(player.NetworkID)
	add_child(carinstance)
	carinstance.global_position=map.StartPosArr[player.PlayerID].global_position
	carinstance.rotation=map.StartPosArr[player.PlayerID].rotation
	player.SetCar(carinstance)
	player.ResetPlayer(player.PlayerID)

@rpc('any_peer','call_remote','reliable')
func EmitClientSignal()->void:
	ClientRegistrationComplete.emit()

func FocusPlayer(player:Player)->void:
	focusCar(player,player.car)
	fcsCar.player.SetHud(hud,fcsCar)
	EnableHud()

@rpc("any_peer",'call_remote','reliable')
func RemoteRegister(type:Player.control_type,charid:int,networkid:int)->void:
	CreatePlayer(GameData.PlayersArr.size(),type,charid,networkid)
	var idarr:Array[int]
	var chararr:Array[int]
	var typearr:Array[Player.control_type]
	for player:Player in (GameData.PlayersArr):
		idarr.append(player.PlayerID)
		chararr.append(player.charid)
		typearr.append(player.current_control)
	ConvalidateRegister.rpc_id(networkid,idarr,typearr,chararr,GameData.PlayersArr.size()-1)

func RequestRegister()->void:
	RemoteRegister.rpc_id(1,Player.control_type.HUMAN,GameData.currentCharacter,multiplayer.get_unique_id())
	
@rpc("any_peer",'call_remote','reliable')
func ConvalidateRegister(playersarr:Array[int],typesarr:Array[Player.control_type],chararrs:Array[int],ownid:int)->void:

	for i:int in range(playersarr.size()):
		var id:int=playersarr[i]
		var charid:int=chararrs[i]
		var control:Player.control_type=typesarr[i]
		if i==ownid:
			CreatePlayer(id,control,charid,multiplayer.get_unique_id())
		else:
			CreatePlayer(id,control,charid,1)
	personalid=ownid
	EmitClientSignal.rpc_id(1)

func DisableHud()->void:
	hud.set_process(false)
	hud.speed_hud.set_process(false)
	hud.char_hud.set_process(false)
	hud.prop_hud.set_process(false)
	
func EnableHud()->void:
	hud.set_process(true)
	hud.speed_hud.set_process(true)
	hud.char_hud.set_process(true)
	hud.prop_hud.set_process(true)


#region Setup

func NetworkSetup()->void:
	GameData.IsMultiplayer=true
	NetworkManager.is_host=multiplayer.is_server()

@rpc("authority","call_local","reliable")
func RaceStart()->void:
	for player:Player in GameData.PlayersArr:
		if player.current_control!=Player.control_type.HUMAN:
			player.car.isSleep=true
		player.StartRace()
	FocusPlayer(GameData.PlayersArr[personalid])


func SceneCenterMoveToPos()->void:
	var distanceToTarget:Vector2 = scenecenterpos - camera.global_position
	camera.global_position += distanceToTarget / 8 * MoveSceneCenterSpeed   
	
	
func SetSceneAngleExpand(nowPos:Vector2, nowCarAngle:float)->void:
	SceneAngleMoveExpandPos.x = 200;
	SceneAngleMoveExpandPos.y = 0;
	SceneAngleMoveExpandPos=SceneAngleMoveExpandPos.rotated(nowCarAngle);
	SceneAngleMoveExpandNowPos.x += (SceneAngleMoveExpandPos.x - SceneAngleMoveExpandNowPos.x) / 8 * MoveSceneAngleSpeed;
	SceneAngleMoveExpandNowPos.y += (SceneAngleMoveExpandPos.y - SceneAngleMoveExpandNowPos.y) / 8 * MoveSceneAngleSpeed;
	nowPos+=SceneAngleMoveExpandNowPos
	SetCenterPos(nowPos);
	
	

func SetCenterPos(nowPos:Vector2)->void:
	scenecenterpos = nowPos;
	if(scenecenterpos.x < map.MapLx):
		scenecenterpos.x = map.MapLx;
	if(scenecenterpos.x > map.MapRx):
		scenecenterpos.x = map.MapRx;
	if(scenecenterpos.y < map.MapTy):
		scenecenterpos.y = map.MapTy;
	if(scenecenterpos.y > map.MapBy):
		scenecenterpos.y = map.MapBy;

func adjust_camera_zoom(target_zoom: Vector2, _delta: float) -> void:
	# Smoothly interpolates the camera zoom
	camera.zoom = camera.zoom.lerp(target_zoom, 0.1)

func UpdateOrderResult() -> void:
	# 1. Sort the players by distance descending
	var sorted_players: Array[Player] = GameData.PlayersArr.duplicate()
	sorted_players.sort_custom(func(a: Player, b: Player) -> bool: 
		if a.alldistance == b.alldistance:
			return a.PlayerID < b.PlayerID
		return a.alldistance > b.alldistance
	)
	
	# 2. Keep a snapshot of the old ID order to check for overtakes
	var old_order: Array = GameData.OrderInfo.duplicate()
	
	# Ensure OrderInfo is resized to fit all players
	GameData.OrderInfo.resize(sorted_players.size())
	
	# 3. Assign new ranks and detect overtakes
	for i in range(sorted_players.size()):
		var player: Player = sorted_players[i]
		player.OrderId = i
		
		# Find where this player used to be in the standings
		var old_index: int = old_order.find(player.PlayerID)
		
		# Store the new order AFTER checking old_index so we don't pollute the check
		GameData.OrderInfo[i] = player.PlayerID
		
		# --- OVERTAKE DETECTION ---
		# If they were in the race before, and their new index is smaller (closer to 0/1st place)
		if old_index != -1 and i < old_index:
			# Trigger HUD animation
			if hud and hud.has_method("play_overtake"):
				hud.play_overtake(i, old_index)

func LoadMinimap()->void:
	map=$Map
	var is_car: bool = (GameData.current_vehicle == GameData.VehicleType.CAR)
	var suffix: String = "1" if is_car else "2"
	var map_num: int = GameData.currentMap
	# 3. Format the minimap path
	# Map 1 uses 01/02, Map 2 uses 11/12, Map 3 uses 21/22, etc.
	var minimap_index: int = map_num - 1
	var minimap_path: String = "res://Assets/Scenes/Screens/maps/Minimap%d%s.tscn" % [minimap_index, suffix]

	# 4. Instantiate and attach the minimap
	var minimap_instance:CanvasLayer = load(minimap_path).instantiate() as CanvasLayer
	minimap_instance.name = "Minimap"
	map.add_child(minimap_instance)
	
#endregion
