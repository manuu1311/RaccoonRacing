extends Node2D
class_name  Player

var car: Car
var PlayerID:int
#TODO: should be set by game manager
##character id 1-6
var charid:int=1
enum control_type{HUMAN,AI,MULTIPLAYER,RLTRAINING,RL}
var current_control:control_type
##position in the race, int
var current_race_position:int
var alldistance:int
var prop:PropManager
var PropBoxRunTimerId:int=-1
var timer:Timer
var PropId:int

func _init(id:int,control:control_type) -> void:
	PlayerID=id
	current_control=control
	prop=PropManager.new(self)
	timer=Timer.new()
	PropId=-1
	timer.one_shot=true
	timer.timeout.connect(_on_timer_cycle_finished)
	timer.wait_time=1.5
	timer.paused=true

func SetCar(carinst:Car)->void:
	car=carinst
	car.add_child(timer)

func IsPlayering()->bool:
	return current_control==control_type.HUMAN
	
	
func RunPropBox(x:float,y:float)->void:
	car.sounds.GetProp()
	if not car.prop_hud.itemready:
		car.prop_hud.propmove(x,y)
	if PropId!=-1:
		return
	PropId = GetPropPer();
	if timer.paused:
		timer.paused=false
		timer.start()
	car.prop_hud.StartPropBox(1.5,PropId)


func _on_timer_cycle_finished() -> void:
	timer.stop()
	GetProp()
	timer.paused=true
			

func GetProp()->void:
	pass

func ClearPropBox(id:int=10)->void:
	pass

func GetPropPer()->int:
	return randi_range(0,8)


func UseProp()->void:
	PropId=-1
	car.prop_hud.PropUsed()
