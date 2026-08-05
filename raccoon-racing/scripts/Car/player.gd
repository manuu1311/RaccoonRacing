extends Node2D
class_name  Player

var car: Car
var PlayerID:int
##character id 1-6
var charid:int=0
enum control_type{HUMAN,AI,MULTIPLAYER,RLTRAINING,RL}
var current_control:control_type
var alldistance:int=0
var prop:PropManager
var OrderId:int
var LapsLock:bool=true
var Laps:int=1
var distance:int
var hud:HUDManager
var AiReflect:int
var ScorePoints:int=0
##multiplayer name
var OnlineName:String=''
var NetworkID:int=1
signal racefinished
var rng :RandomNumberGenerator= RandomNumberGenerator.new()
var PropValidated:bool=false
##device mapping
var input_device_type: String = ""
var input_device_id: int = -1
var input_device_key: String = "" 

'''
1:become invincible
2:sleep other players
3:shield
4:deploy mine
5:missile to first player
6:missile to next player
7:banana
8:turbo
9:character signature:
	1:double turbo
	2:bombs
	3:double mine
	4:ice trail
	5:rotating bones
	6:laser shrink ray
'''
const POSITION_PROBABILITIES: Dictionary = {
	0: [0,  0, 30, 30,  0,  0, 30,  0, 10], # 1st Place
	1: [5,  0, 15, 20, 5, 15, 15, 15, 10], # 2nd Place
	2: [10, 10, 5,  5, 15, 20, 5, 20, 10], # 3rd Place
	3: [15, 20, 0,  0, 20, 15,  0, 20, 10]  # 4th Place
}

func _init(id:int,control:control_type) -> void:
	PlayerID=id
	OrderId=id
	current_control=control
	prop=PropManager.new(self)
	

func SetCar(carinst:Car)->void:
	car=carinst
	
func SetHud(hudinst:HUDManager,carinst:Car)->void:
	hud=hudinst
	hud.setup()
	hud.SetCar(carinst)
	
	
func Setup()->void:
	if GameData.IsMultiplayer:
		car.StateSyncSetup()
	car.set_multiplayer_authority(NetworkID)


func IsPlayering()->bool:
	return car.playering

func Update()->void:
	car.sounds.Loopsounds()
	prop.run()
	UpdatePoint()

func AuthorityUpdate()->void:
	car.Update()
	
func StartRace()->void:
	car.playering = true;
	car.isLock = false
	#car.StateSyncSetup()
	if(car.speed.length() > 2):
		car.speed=Vector2.ZERO;
	elif(car.speed.length() > 0.5):
		PropValidated=true
		car.StartBoost()
	
func UpdatePoint() -> void:
	if !IsPlayering():
		return
		
	var _loc4_: Vector2
	if car.NowPointId + 1 < car.map.Points.size():
		_loc4_ = car.map.Points[car.NowPointId + 1]
	else:
		_loc4_ = car.map.Points[0]

	# _loc6_ in flash: distance from car to NEXT waypoint
	var tonext: float = _loc4_.distance_to(car.global_position)
	# _loc5_ in flash: total distance between current waypoint and next waypoint
	var between: float = car.map.Points[car.NowPointId].distance_to(_loc4_)
	
	@warning_ignore("narrowing_conversion")
	distance = car.map.Points[car.NowPointId].distance_to(car.global_position)

	if car.NowPointId == 0 and !LapsLock:
		alldistance = (Laps + 1) * 10000000 + car.NowPointId * 10000 + (10000 - distance)
	else:
		alldistance = Laps * 10000000 + car.NowPointId * 10000 + (10000 - distance)

	WinJudge()

	# Waypoint progression logic
	if tonext + 200 < between or distance < 200:
		car.NowPointId += 1
		if car.NowPointId >= car.map.Points.size():
			car.NowPointId = 0

func WinJudge() -> void:
	if car.NowPointId == 1:
		LapsLock = false
		
	if car.NowPointId == 0 and !LapsLock:
		var win_pos: Vector2 = car.map.WinPosition # Assuming map has this method
		var win_to_point_0: float = win_pos.distance_to(car.map.Points[0])
		
		# distance is the car's distance to Points[0] (the next waypoint)
		if distance < win_to_point_0:
			if Laps == GameData.currentLaps:
				FinishRace()
				return
				
			Laps += 1
			# If this is the main player (ID 0)
			if hud!=null:
				hud.updatelap()
				if Laps == GameData.currentLaps:
					# Replace with your actual UI/Notification system call
					hud.ShowMessage("FINAL LAP")
				else:
					# Replace with your actual formatted string/localization system call
					var lap_text:String = "LAP %d/%d" % [Laps, GameData.currentLaps]
					hud.ShowMessage(lap_text)
			
			LapsLock = true


func ResetPlayer(order:int)->void:
	car.CanUseProp=false
	car.IsUsingProp=false
	LapsLock=true
	Laps=1
	car.NowPorpId=0
	car.NowPointId=0
	OrderId=order
	alldistance=-OrderId
	
func FinishRace()->void:
	alldistance = 100000000 * (GameData.PlayersArr.size() - OrderId);
	Stoprace();

func Stoprace()->void:
	car.playering = false;
	for propinst:Prop in prop.propArr:
		propinst.del()
	prop.propArr.clear()
	racefinished.emit(PlayerID)

func ValidatePropBox(x:float,y:float)->void:
	if not GameData.IsMultiplayer or NetworkManager.is_host:
		RunPropBox(x,y)
	elif hud!=null:
		if not hud.IsPropHudVisible():
			RunPropBox(x,y)
	PropValidated=true

func RunPropBox(x:float,y:float)->void:
	if not car.playering:
		return
	if hud!=null:
		car.sounds.GetProp()
		if not hud.PropItemReady():
			hud.propmove(x,y)
	if car.NowPorpId!=0:
		return
	GetProp(GetPropPer())
	car.CanUseProp=true
	if hud!=null and car:
		hud.StartPropBox(1.5,car.NowPorpId)



func GetProp(propid:int)->void:
	if is_instance_valid(car):
		car.NowPorpId=propid

func ClearPropBox(id:int)->void:
	if hud!=null:
		hud.PropUsed(id)

func GetPropPer()->int:
	# Clamp OrderId to ensure it doesn't break if index goes out of bounds
	var orderposition: int = clampi(OrderId, 0, 3)
	
	# Fetch the weights for the current position
	var weights: Array = POSITION_PROBABILITIES[orderposition]
	
	# Roll a number between 0 and 99 (Total weight = 100)
	rng.seed = NetworkTime.tick + PlayerID
	var roll: int = rng.randi_range(0, 99)
	
	var running_total: int = 0
	
	# Iterate through the weights to find where the roll lands
	for i in range(weights.size()):
		running_total += weights[i]
		if roll < running_total:
			return i + 1 # Item IDs start at 1, arrays start at 0
			
	return 7

func RemoveShield()->void:
	car.IsUseShield=false
	car.prop_effector.RemoveShield()
func AddShield()->void:
	car.IsUseShield=true
	car.prop_effector.AddShield()

func ResetUse()->void:
	car.CanUseProp=true

func UseProp()->void:
	if(IsPlayering() && not car.isSleep and car.CanUseProp and !car.IsUsingProp):
		if not GameData.IsMultiplayer or NetworkManager.is_host:
			car.RequestProp(NetworkID,PlayerID,car.position,car.rotation,car.NowPorpId)
		else:
			car.RequestProp.rpc_id(1,NetworkID,PlayerID,car.position,car.rotation,car.NowPorpId)
		prop.UseProp()
		car.CanUseProp=false
		PropValidated=false
