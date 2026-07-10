extends Node2D
class_name GameManager

#TODO:save reference ofplayer or car?
var players: Array[Player]
var cars:Array[Car]
var fcsCar:Car
#TODO: should be created
@onready var map: Map
@onready var hud: HUDManager = $Hud
@onready var sound_manager: GameSoundManager = $SoundManager
@onready var lbl321: Label = $"321/321"
@onready var lbl321_player: AnimationPlayer = $"321/321Player"
@onready var finish: AnimatedSprite2D = $"321/Finish"
var MoveSceneCenterSpeed:int = 2;
var MoveSceneAngleSpeed:float = 0.2;
@onready var camera: Camera2D = $Camera2D
var stagesize:Vector2
var scenecenterpos:Vector2
var SceneAngleMoveExpandPos:Vector2
var SceneAngleMoveExpandNowPos:Vector2


func _ready() -> void:
	UiOverAnimation.reset_anim_frame()
	LoadMap()
	lbl321.self_modulate=Color.TRANSPARENT
	stagesize=map.GetMapSize()
	SceneAngleMoveExpandPos = Vector2(150,0)
	SceneAngleMoveExpandNowPos = Vector2.ZERO
	map.deferredInit()
	var available_ids:Array[int] = [1, 2, 3, 4, 5, 6]
	for i:int in GameData.Ranking.size(): 
		var player:Player=GameData.PlayersArr[GameData.Ranking[i]]
		player.ResetPlayer(i)
		var carinstance:Car = preload("res://Assets/Scenes/Screens/Car.tscn").instantiate()
		if player.current_control==player.control_type.HUMAN:
			carinstance.setup(map,player.PlayerID,true,player)
			carinstance.add_child(HumanCarController.new(player))
			focusCar(player,carinstance)
			carinstance.CharID=GameData.currentCharacter
			player.charid=GameData.currentCharacter
			available_ids.erase(GameData.currentCharacter)
			available_ids.shuffle()
			player.racefinished.connect(Racestop)
		else:
			carinstance.setup(map,player.PlayerID,false,player)
			carinstance.add_child(AICarController.new(player))
			var newid:int
			if player.charid==0:
				newid=available_ids.pop_front()
				player.charid=newid
			else:
				newid=player.charid
				available_ids.erase(newid)
			carinstance.CharID=newid
		add_child(carinstance)
		carinstance.global_position=map.StartPosArr[i].global_position
		carinstance.rotation=map.StartPosArr[i].rotation
		player.SetCar(carinstance)
	CoolEffects()
	fcsCar.player.SetHud(hud,fcsCar)

	
	
func LoadMap()->void:
	var minimap_instance:CanvasLayer
	if GameData.currentMap==1:
		map=load("res://Assets/Scenes/Screens/maps/Map01.tscn").instantiate() as Map
		add_child(map)
		if GameData.current_vehicle==GameData.VehicleType.CAR:
			minimap_instance = load("res://Assets/Scenes/Screens/maps/Minimap01.tscn").instantiate()
		else:
			minimap_instance = load("res://Assets/Scenes/Screens/maps/Minimap02.tscn").instantiate()
	elif GameData.currentMap==2:
		map=load("res://Assets/Scenes/Screens/maps/Map02.tscn").instantiate() as Map
		add_child(map)
		if GameData.current_vehicle==GameData.VehicleType.CAR:
			minimap_instance = load("res://Assets/Scenes/Screens/maps/Minimap11.tscn").instantiate()
		else:
			minimap_instance = load("res://Assets/Scenes/Screens/maps/Minimap12.tscn").instantiate()
	elif GameData.currentMap==3:
		map=load("res://Assets/Scenes/Screens/maps/Map03.tscn").instantiate() as Map
		add_child(map)
		if GameData.current_vehicle==GameData.VehicleType.CAR:
			minimap_instance = load("res://Assets/Scenes/Screens/maps/Minimap21.tscn").instantiate()
		else:
			minimap_instance = load("res://Assets/Scenes/Screens/maps/Minimap22.tscn").instantiate()
	elif GameData.currentMap==4:
		map=load("res://Assets/Scenes/Screens/maps/Map04.tscn").instantiate() as Map
		add_child(map)
		if GameData.current_vehicle==GameData.VehicleType.CAR:
			minimap_instance = load("res://Assets/Scenes/Screens/maps/Minimap31.tscn").instantiate()
		else:
			minimap_instance = load("res://Assets/Scenes/Screens/maps/Minimap32.tscn").instantiate()
	minimap_instance.name = "Minimap"
	map.add_child(minimap_instance)

func RaceStart()->void:
	for player:Player in GameData.PlayersArr:
		player.StartRace()
	
	
func register(player:Player)->void:
	players.append(player)

func focusCar(player:Player,car:Car)->void:
	GameData.FocusCar=car
	fcsCar=car
	GameData.FocusPlayer=player
	
func _process(_delta: float) -> void:
	if fcsCar!=null:
		camera.zoom=Vector2.ONE*(1 - fcsCar.jumpCurrheight * 0.005)
		SetSceneAngleExpand(fcsCar.global_position,fcsCar.rotation-PI/2)
		SceneCenterMoveToPos()
		if !fcsCar.isLock:
			UpdateOrderResult()
	if Input.is_action_just_released("Debug"):
		GameData.FocusPlayer.Stoprace()
		GameData.FocusPlayer.car.playering=false
		
func CoolEffects()->void:
	sound_manager.PlaySound('levelstart')
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

func adjust_camera_zoom(target_zoom: Vector2, delta: float) -> void:
	# Smoothly interpolates the camera zoom
	camera.zoom = camera.zoom.lerp(target_zoom, 0.1)

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


func Racestop()->void:
	hud.StopRecord()
	MusicPlayer.FadeOutAndStop(3)
	if(fcsCar.player.OrderId == 0):
		sound_manager.PlaySound("finish",0.0)
	else:
		sound_manager.PlaySound("failed",0.0)
	ShowFinishEffect();



func ShowFinishEffect()->void:
	finish.play()
	await get_tree().create_timer(3).timeout
	UiOverAnimation.playanim()
	await UiOverAnimation.animated_sprite_2d.animation_finished
	for player:Player in GameData.PlayersArr:
		if player!=GameData.FocusPlayer:
			player.Stoprace()
	BackToMain()


func BackToMain()->void:
	GameData.FocusCar.player.racefinished.disconnect(Racestop)
	get_tree().change_scene_to_file("res://Assets/Scenes/Screens/ui_scores.tscn")
	queue_free()
