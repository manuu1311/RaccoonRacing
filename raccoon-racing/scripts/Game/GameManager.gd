extends Node2D
class_name GameManager

var players: Array[Player]
var cars:Array[Car]
var fcsCar:Car
@onready var map: Map
@onready var hud: HUDManager = $Hud
@onready var sound_manager: GameSoundManager = $SoundManager
@onready var lbl321: Label = $"321/321"
@onready var lbl321_player: AnimationPlayer = $"321/321Player"
@onready var finish: AnimatedSprite2D = $"321/Finish"
@onready var camera: Camera2D = $Camera2D
@onready var viewport_manager: ViewportManagerDummy = $ViewportManager
var IsRaceStarted:bool=false
signal overtake_signal
signal players_created_signal
@onready var world: Node2D = $world
var minimap:SubViewport
@onready var minimap_canvas: CanvasLayer = $MinimapCanvas

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
	lbl321.self_modulate=Color.TRANSPARENT
	UiOverAnimation.reset_anim_frame()
	Game.PlayersReady.connect(StartSequence)
	#LoadMap()
	LoadMap()
	map.deferredInit()
	CreatePlayers()
	players_created_signal.emit()
	UiLoadingScreen.HideLoading()
	sound_manager.PlaySound('levelstart')

	
func CreatePlayers()->void:
	var available_ids:Array[int] = [1, 2, 3, 4, 5, 6]
	for i:int in GameData.Ranking.size(): 
		var player:Player=GameData.PlayersArr[GameData.Ranking[i]]
		var carinstance:Car = preload("res://Assets/Scenes/Screens/Car.tscn").instantiate()
		if player.current_control==player.control_type.HUMAN and player.PlayerID==NetworkManager.PlayerID:
			carinstance.setup(map,player.PlayerID,true,player)
			var controller:CarController=HumanCarController.new(player)
			carinstance.add_child(controller)
			carinstance.controller=controller
			carinstance.CharID=GameData.currentCharacter
			player.charid=GameData.currentCharacter
			available_ids.erase(GameData.currentCharacter)
			available_ids.shuffle()
			#carinstance.set_multiplayer_authority(player.NetworkID)
			focusCar(player,carinstance)
		elif player.current_control==player.control_type.HUMAN and GameData.IsMultiplayer:
			carinstance.setup(map,player.PlayerID,false,player)
			var controller:CarController=CarController.new(player)
			carinstance.add_child(controller)
			carinstance.controller=controller
			carinstance.CharID=player.charid
			#player.charid=GameData.currentCharacter
			available_ids.erase(GameData.currentCharacter)
			available_ids.shuffle()
			#carinstance.set_multiplayer_authority(player.NetworkID)
		else:
			carinstance.setup(map,player.PlayerID,false,player)
			var controller:CarController=AICarController.new(player)
			carinstance.add_child(controller)
			carinstance.controller=controller
			var newid:int
			if player.charid==0:
				newid=available_ids.pop_front()
				player.charid=newid
			else:
				newid=player.charid
				available_ids.erase(newid)
			carinstance.CharID=newid
		add_child(carinstance)
		carinstance.name="Car"+str(player.PlayerID)
		carinstance.global_position=map.StartPosArr[i].global_position
		carinstance.rotation=map.StartPosArr[i].rotation
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
	

func focusCar(player:Player,car:Car)->void:
	fcsCar=car
	viewport_manager.Setup(map,self)
	viewport_manager.FocusPlayer(player,car)
	
func _process(_delta: float) -> void:
	if !fcsCar.isLock:
		UpdateOrderResult()
		
func CoolEffects()->void:
	#if not multipayer, there is no wait time -> wait for 
	#initial music to finish
	if not GameData.IsMultiplayer:
		await get_tree().create_timer(3).timeout
	sound_manager.PlaySound("ready3")
	lbl321.text='3'
	lbl321_player.play("321")
	await get_tree().create_timer(1).timeout
	sound_manager.PlaySound("ready2")
	lbl321.text='2'
	lbl321_player.play("321")
	await get_tree().create_timer(1).timeout
	sound_manager.PlaySound("ready1")
	lbl321.text='1'
	lbl321_player.play("321")
	await get_tree().create_timer(1).timeout
	sound_manager.PlaySound("go")
	lbl321.text='GO'
	lbl321_player.play("321")
	await get_tree().create_timer(0.3).timeout
	#lbl321.hide()
	RaceStart()
	MusicPlayer.PlayMusic("map"+str(GameData.currentMap)) 
	
	
	
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
	finish.play()
	#sync everyone's orderinfo
	if NetworkManager.is_host:
		UpdateOrderInfo.rpc(GameData.OrderInfo)
	await get_tree().create_timer(3).timeout
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
