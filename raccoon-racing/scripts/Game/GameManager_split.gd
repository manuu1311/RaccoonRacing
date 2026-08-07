extends Node2D
class_name GameManager_split

var players: Array[Player]
var cars:Array[Car]
var map: Map
var minimap:SubViewport
@onready var sound_manager: GameSoundManager = $SoundManager
@export var viewport_manager_arr: Array[ViewportManager]
@export var world: Node2D
var IsRaceStarted:bool=false
signal overtake_signal
@export var minimap_canvas: CanvasLayer
var window_instance:PackedScene=preload("res://Assets/Scenes/Screens/experiments/sub_window.tscn")

#preload props
const PROP_SCENES = {
	"prop1": preload("res://Assets/Scenes/Screens/maps/Props/BombInMap.tscn"),
	"prop2": preload("res://Assets/Scenes/Screens/maps/Props/BsInMap.tscn"),
	"prop3": preload("res://scripts/map/Props/furballs_in_map.gd"),
	"prop4": preload("res://Assets/Scenes/Screens/maps/Props/HoneyBombInMap.tscn"),
	"prop5": preload("res://Assets/Scenes/Screens/maps/Props/IceTrail.tscn"),
	"prop6": preload("res://Assets/Scenes/Screens/maps/Props/MissileInMap.tscn"),
	"prop7": preload("res://Assets/Scenes/Screens/maps/Props/Propkn1InMap.tscn"),
	"prop8": preload("res://Assets/Scenes/Screens/maps/Props/ShrinkInMap.tscn"),
}

func _ready() -> void:
	UiOverAnimation.reset_anim_frame()
	Game.PlayersReady.connect(StartSequence)
	LoadMap()
	map.deferredInit()
	CreatePlayers()
	UiLoadingScreen.HideLoading()
	PopulateViewports()
	sound_manager.PlaySound('levelstart')
	for player:Player in GameData.PlayersArr:
		if player.current_control!=Player.control_type.HUMAN:
			continue
		if GameData.IsMultiplayer and not NetworkManager.is_host:
			Game.server_receive_ready.rpc_id(1,player.PlayerID)
		else:
			Game.server_receive_ready(player.PlayerID)


func PopulateViewports()->void:
	AddWindow()
	var viewportid:int=0
	for player:Player in GameData.PlayersArr:
		if player.current_control==Player.control_type.HUMAN or Game.LocalPlayers>2:
			var viewport:ViewportManager=viewport_manager_arr[viewportid]
			if Game.IsSplitScreen:
				@warning_ignore("unsafe_property_access")
				viewport.world_2d=get_viewport().world_2d
			viewport.Setup(map,sound_manager,self)
			viewport.name='Window'+str(viewportid)
			focusCar(player,player.car,viewportid)
			viewportid+=1
	


func AddWindow()->void:
	var main_window :Window= get_window()
	main_window.mode = Window.MODE_FULLSCREEN
	if OS.has_feature("android"):
		main_window.content_scale_size=Vector2(1000,500)
		var touch_controls:CanvasLayer=(load("res://Assets/Scenes/Screens/HUD/TouchControls.tscn")as PackedScene).instantiate() as CanvasLayer
		add_child(touch_controls)
	if not Game.IsSplitScreen:
		$Background.free()
		return
	viewport_manager_arr[0].free()
	viewport_manager_arr.clear()
	if Game.LocalPlayers==2:
		main_window.content_scale_size=Vector2(1010,500)
	else:
		main_window.content_scale_size=Vector2(1010,1010)
	var split_window :ViewportManager=window_instance.instantiate() as ViewportManager
	add_child(split_window)
	viewport_manager_arr.append(split_window)
	@warning_ignore("unsafe_property_access")
	viewport_manager_arr[0].position = Vector2i(0,0)
	split_window=window_instance.instantiate() as ViewportManager
	@warning_ignore("unsafe_property_access")
	split_window.position = Vector2i(510, 0)
	add_child(split_window)
	viewport_manager_arr.append(split_window)
	if Game.LocalPlayers>2:
		split_window=window_instance.instantiate() as ViewportManager
		@warning_ignore("unsafe_property_access")
		split_window.position = Vector2i(0, 510)
		add_child(split_window)
		viewport_manager_arr.append(split_window)
		split_window=window_instance.instantiate() as ViewportManager
		@warning_ignore("unsafe_property_access")
		split_window.position = Vector2i(510, 510)
		add_child(split_window)
		viewport_manager_arr.append(split_window)



func CreatePlayers()->void:
	for i:int in GameData.Ranking.size(): 
		var player:Player=GameData.PlayersArr[GameData.Ranking[i]]
		var carinstance:Car = preload("res://Assets/Scenes/Screens/Car.tscn").instantiate()
		if player.current_control==player.control_type.HUMAN:
			carinstance.setup(map,player.PlayerID,true,player)
			var controller:CarController=HumanCarController.new(player)
			carinstance.add_child(controller)
			carinstance.controller=controller
			carinstance.CharID=player.charid
		elif player.current_control==player.control_type.MULTIPLAYER:
			carinstance.setup(map,player.PlayerID,false,player)
			var controller:CarController=CarController.new(player)
			carinstance.add_child(controller)
			carinstance.controller=controller
			carinstance.CharID=player.charid
		else:
			carinstance.setup(map,player.PlayerID,false,player)
			var controller:CarController=AICarController.new(player)
			carinstance.add_child(controller)
			carinstance.controller=controller
			carinstance.CharID=player.charid
		world.add_child(carinstance)
		#temporary authority swap for car positions
		carinstance.set_multiplayer_authority(multiplayer.get_unique_id())
		carinstance.name="Car"+str(player.PlayerID)
		carinstance.global_position=map.StartPosArr[i].global_position
		carinstance.rotation=map.StartPosArr[i].rotation
		carinstance.call_deferred('set_multiplayer_authority',player.NetworkID)
		player.SetCar(carinstance)
		player.ResetPlayer(i)

func StartSequence(target_tick:int)->void:
	while NetworkTime.tick < target_tick:
		await NetworkTime.after_tick
	for player:Player in GameData.PlayersArr:
		player.Setup()
	CoolEffects()
	
func LoadMap() -> void:
	var map_num: int = GameData.currentMap

	# 1. Format the map path (e.g., "Map01.tscn", "Map02.tscn")
	# %02d pads single digits with a leading zero (1 becomes 01)
	var map_path: String = "res://Assets/Scenes/Screens/maps/Map%02d.tscn" % map_num

	@warning_ignore("unsafe_method_access")
	map = load(map_path).instantiate() as Map
	world.add_child(map)

	# 2. Determine the minimap suffix based on the vehicle type
	var is_car: bool = (GameData.current_vehicle == GameData.VehicleType.CAR)
	var suffix: String = "1" if is_car else "2"

	# 3. Format the minimap path
	# Map 1 uses 01/02, Map 2 uses 11/12, Map 3 uses 21/22, etc.
	var minimap_index: int = map_num - 1
	var minimap_path: String = "res://Assets/Scenes/Screens/maps/Minimap%d%s.tscn" % [minimap_index, suffix]

	# 4. Instantiate and attach the minimap
	@warning_ignore("unsafe_method_access")
	minimap = load(minimap_path).instantiate() as SubViewport
	minimap.name = "Minimap"
	minimap_canvas.add_child(minimap)
	map.minimap=minimap.get_node('View/MapSprite')


func RaceStart()->void:
	for player:Player in GameData.PlayersArr:
		player.StartRace()
	Game.PlayersReady.disconnect(StartSequence)
	Game.PlayersReady.connect(ShowFinishEffect)
	IsRaceStarted=true
	

func focusCar(player:Player,car:Car,id:int)->void:
	viewport_manager_arr[id].FocusPlayer(player,car)
	
func _process(_delta: float) -> void:
	if IsRaceStarted:
		UpdateOrderResult()
		
func CoolEffects()->void:
	#if not multipayer, there is no wait time -> wait for 
	#initial music to finish
	#if not GameData.IsMultiplayer:
		#await get_tree().create_timer(3).timeout
	sound_manager.PlaySound("ready3")
	Play321Anim('3')
	await get_tree().create_timer(1).timeout
	sound_manager.PlaySound("ready2")
	Play321Anim('2')
	await get_tree().create_timer(1).timeout
	sound_manager.PlaySound("ready1")
	Play321Anim('1')
	await get_tree().create_timer(1).timeout
	sound_manager.PlaySound("go")
	Play321Anim('GO')
	await get_tree().create_timer(0.3).timeout
	#lbl321.hide()
	RaceStart()
	MusicPlayer.PlayMusic("map"+str(GameData.currentMap)) 
	
func Play321Anim(msg:String)->void:
	for viewport:ViewportManager in viewport_manager_arr:
		viewport.lbl321.text=msg
		viewport.lbl321player.play('321')
	
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
			overtake_signal.emit(i,old_index)




func ShowFinishEffect(_tick:int)->void:
	#sync everyone's orderinfo
	if NetworkManager.is_host:
		UpdateOrderInfo.rpc(GameData.OrderInfo)
	await get_tree().create_timer(3).timeout
	ClearViewportsAndFocus()
	UiOverAnimation.playanim()
	await UiOverAnimation.animated_sprite_2d.animation_finished
	for player:Player in GameData.PlayersArr:
		if player.current_control==Player.control_type.HUMAN:
			player.Stoprace()
	BackToMain()

@rpc("authority",'reliable','call_remote')
func UpdateOrderInfo(neworder:Array[int])->void:
	GameData.OrderInfo=neworder

func BackToMain()->void:
	Game.PlayersReady.disconnect(ShowFinishEffect)
	get_tree().change_scene_to_file("res://Assets/Scenes/Screens/ui_scores.tscn")
	queue_free()

##clear all viewports and focus on first human player
func ClearViewportsAndFocus()->void:
	var main_window :Window= get_window()
	main_window.content_scale_size=Vector2(500,500)
	if not Game.IsSplitScreen:
		return
	main_window.mode=Window.MODE_MAXIMIZED
	for i in range(len(viewport_manager_arr)):
		(viewport_manager_arr[i]).visible=false
		viewport_manager_arr[i].mode=Window.MODE_MINIMIZED
		viewport_manager_arr[i].queue_free()
	($final_camera as Camera2D).global_position=GameData.PlayersArr[0].car.global_position
	($final_camera as Camera2D).enabled=true
	$Background.free()
