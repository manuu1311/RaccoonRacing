extends Node2D

@export var camera:Camera2D
@export var game_manager:EnvManager

var fcsCar:Car
var map:Map
var SceneAngleMoveExpandPos : Vector2
var SceneAngleMoveExpandNowPos : Vector2
var scenecenterpos:Vector2
var MoveSceneCenterSpeed:int = 2;
var MoveSceneAngleSpeed:float = 0.2;


func _ready() -> void:
	set_process(false)
	game_manager.setup_ready_signal.connect(setup)

func setup(carinst:Car,mapinst:Map) -> void:
	fcsCar=carinst
	map=mapinst
	set_process(true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if fcsCar!=null:
		camera.zoom=Vector2.ONE*(1 - fcsCar.jumpCurrheight * 0.005)
		SetSceneAngleExpand(fcsCar.global_position,fcsCar.rotation-PI/2)
		SceneCenterMoveToPos()


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
