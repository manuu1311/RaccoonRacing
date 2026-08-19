extends Node
class_name ViewportManager

@onready var camera: Camera2D = $Camera2D

@onready var hud: HUDManager = $HUD/Hud
var lbl321: Label
var lbl321player: AnimationPlayer
@onready var finish: AnimatedSprite2D = $HUD/FinishEffect/Control/Finish
var sound_manager: GameSoundManager
var game_manager: GameManager_split

var stagesize:Vector2
var SceneAngleMoveExpandPos : Vector2
var SceneAngleMoveExpandNowPos : Vector2
var scenecenterpos:Vector2
var MoveSceneCenterSpeed:int = 2;
var MoveSceneAngleSpeed:float = 0.2;
var FcsPlayer:Player
var fcsCar:Car
var map: Map
var container:SubViewportContainer



func _ready() -> void:
	finish.frame=0
	SceneAngleMoveExpandPos = Vector2(150,0)
	SceneAngleMoveExpandNowPos = Vector2.ZERO
	lbl321player=hud.lbl321_player
	lbl321=hud.lbl321
	lbl321.self_modulate=Color.TRANSPARENT


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if fcsCar!=null:
		camera.zoom=Vector2.ONE*(1 - fcsCar.jumpCurrheight * 0.005)
		SetSceneAngleExpand(fcsCar.global_position,fcsCar.rotation-PI/2)
		SceneCenterMoveToPos()


func Setup(mapinst:Map,soundmanager:GameSoundManager,gamemanager:GameManager_split)->void:
	map=mapinst
	stagesize=map.GetMapSize()
	SetupCameraBoundaries()
	sound_manager=soundmanager
	game_manager=gamemanager
	game_manager.overtake_signal.connect(hud.play_overtake)
	hud.minimap.texture=gamemanager.minimap.get_texture()


func SetupCameraBoundaries()->void:
	camera.limit_left=map.boundaries[0]
	camera.limit_top=map.boundaries[1]
	camera.limit_right=map.boundaries[2]
	camera.limit_bottom=map.boundaries[3]

func FocusPlayer(player:Player,carinstance:Car)->void:
	FcsPlayer=player
	fcsCar=carinstance
	player.racefinished.connect(Racestop)
	var vibhandler:VibrationHandler=fcsCar.get_node('VibrationHandler') as VibrationHandler
	vibhandler.RegisterCar(fcsCar)
	SetHud()

func SetHud()->void:
	FcsPlayer.SetHud(hud,fcsCar)


func Racestop(id:int)->void:
	if fcsCar.playerID==id:
		hud.StopRecord()
		MusicPlayer.FadeOutAndStop(3)
		if(fcsCar.player.OrderId == 0):
			sound_manager.PlaySound("finish",0.0)
		else:
			sound_manager.PlaySound("failed",0.0)
		finish.play()
	if GameData.IsMultiplayer and not NetworkManager.is_host:
		Game.server_receive_ready.rpc_id(1,fcsCar.playerID)
	else:
		Game.server_receive_ready(fcsCar.playerID)

#region Map Movement

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
#endregion
