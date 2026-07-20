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
var CanUseProp:bool=false
var IsUsingProp:bool=false
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
	

func IsPlayering()->bool:
	return car.playering

func Update(tick:int, is_fresh:bool)->void:
	UpdatePoint()
	car.Update(is_fresh)
	prop.run(tick, is_fresh)
	
	
func StartRace(starttick:int)->void:
	car.playering = true;
	car.isLock = false;
	car.StartTick=starttick
	if(car.speed.length() > 2):
		car.speed=Vector2.ZERO;
	elif(car.speed.length() > 0.5):
		CanUseProp=true
		car.NowPorpId = 8;
		UseProp();
	
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
	CanUseProp=false
	IsUsingProp=false
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
	racefinished.emit()

func RunPropBox(x:float,y:float)->void:
	if not car.playering:
		return
	car.sounds.GetProp()
	if not hud.PropItemReady():
		hud.propmove(x,y)
	if car.NowPorpId!=0:
		return
	GetProp(GetPropPer())
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
	var roll: int = randi_range(0, 99)
	
	var running_total: int = 0
	
	# Iterate through the weights to find where the roll lands
	for i in range(weights.size()):
		running_total += weights[i]
		if roll < running_total:
			return i + 1 # Item IDs start at 1, arrays start at 0
			
	return 7

func GetPropPer_LEGACY()->int:
	var _loc5_:int = randi_range(0,99);
	if(charid == 1 && OrderId == 0 && PlayerID == 0):
		_loc5_ = randi_range(0,89);
	if(charid == 1 && OrderId == 1 && PlayerID == 0):
		_loc5_ = randi_range(0,79);
	var _loc2_:Array[int] = [0,0,0,0,0,0,0,0,0,0,0];
	var _loc6_:Vector2;
	if(PlayerID == 0 || GameData.currentDifficulty < 2):
		if(OrderId == 0):
			_loc2_[1] = 0;
			_loc2_[2] = 0;
			_loc2_[3] = 30;
			_loc2_[4] = 30;
			_loc2_[5] = 0;
			_loc2_[6] = 0;
			_loc2_[7] = 30;
			_loc2_[8] = 0;
			_loc2_[9] = 10;
		elif(OrderId == 1):
			_loc2_[1] = 5;
			_loc2_[2] = 0;
			_loc2_[3] = 20;
			_loc2_[4] = 10;
			_loc2_[5] = 5;
			_loc2_[6] = 20;
			_loc2_[7] = 10;
			_loc2_[8] = 10;
			_loc2_[9] = 20;
		elif(OrderId == 2):
			_loc2_[1] = 10;
			_loc2_[2] = 5;
			_loc2_[3] = 0;
			_loc2_[4] = 0;
			_loc2_[5] = 10;
			_loc2_[6] = 25;
			_loc2_[7] = 0;
			_loc2_[8] = 30;
			_loc2_[9] = 20;
		else:
			_loc2_[1] = 10;
			_loc2_[2] = 5;
			_loc2_[3] = 0;
			_loc2_[4] = 0;
			_loc2_[5] = 10;
			_loc2_[6] = 25;
			_loc2_[7] = 0;
			_loc2_[8] = 30;
			_loc2_[9] = 20;
	elif(OrderId == 0):
		_loc6_=GameData.PlayersArr[0].car.global_position-car.global_position
		if(_loc6_.length() < 300):
			_loc2_[1] = 30;
			_loc2_[2] = 0;
			_loc2_[3] = 10;
			_loc2_[4] = 20;
			_loc2_[5] = 0;
			_loc2_[6] = 0;
			_loc2_[7] = 20;
			_loc2_[8] = 10;
			_loc2_[9] = 10;
		else:
			_loc2_[1] = 0;
			_loc2_[2] = 0;
			_loc2_[3] = 30;
			_loc2_[4] = 30;
			_loc2_[5] = 0;
			_loc2_[6] = 0;
			_loc2_[7] = 30;
			_loc2_[8] = 0;
			_loc2_[9] = 10;
	elif(OrderId == 1):
		_loc6_=GameData.PlayersArr[0].car.global_position-car.global_position
		if(_loc6_.length() < 300):
			if(GameData.PlayersArr[0].OrderId == 0):
				_loc2_[1] = 40;
				_loc2_[2] = 0;
				_loc2_[3] = 0;
				_loc2_[4] = 0;
				_loc2_[5] = 5;
				_loc2_[6] = 5;
				_loc2_[7] = 0;
				_loc2_[8] = 30;
				_loc2_[9] = 20;
			else:
				_loc2_[1] = 30;
				_loc2_[2] = 0;
				_loc2_[3] = 10;
				_loc2_[4] = 15;
				_loc2_[5] = 0;
				_loc2_[6] = 0;
				_loc2_[7] = 15;
				_loc2_[8] = 10;
				_loc2_[9] = 20;
		elif(GameData.PlayersArr[0].OrderId == 0):
			_loc2_[1] = 0;
			_loc2_[2] = 0;
			_loc2_[3] = 0;
			_loc2_[4] = 0;
			_loc2_[5] = 10;
			_loc2_[6] = 30;
			_loc2_[7] = 0;
			_loc2_[8] = 40;
			_loc2_[9] = 20;
		else:
			_loc2_[1] = 0;
			_loc2_[2] = 0;
			_loc2_[3] = 20;
			_loc2_[4] = 25;
			_loc2_[5] = 0;
			_loc2_[6] = 0;
			_loc2_[7] = 25;
			_loc2_[8] = 10;
			_loc2_[9] = 20;
	elif(OrderId == 2):
		_loc6_=GameData.PlayersArr[0].car.global_position-car.global_position
		if(_loc6_.length() < 300):
			if(GameData.PlayersArr[0].OrderId < 2):
				_loc2_[1] = 40;
				_loc2_[2] = 0;
				_loc2_[3] = 0;
				_loc2_[4] = 0;
				_loc2_[5] = 5;
				_loc2_[6] = 15;
				_loc2_[7] = 0;
				_loc2_[8] = 20;
				_loc2_[9] = 20;
			else:
				_loc2_[1] = 0;
				_loc2_[2] = 0;
				_loc2_[3] = 10;
				_loc2_[4] = 30;
				_loc2_[5] = 0;
				_loc2_[6] = 0;
				_loc2_[7] = 30;
				_loc2_[8] = 10;
				_loc2_[9] = 20;

		elif(GameData.PlayersArr[0].OrderId == 0):
			_loc2_[1] = 0;
			_loc2_[2] = 5;
			_loc2_[3] = 0;
			_loc2_[4] = 0;
			_loc2_[5] = 20;
			_loc2_[6] = 15;
			_loc2_[7] = 0;
			_loc2_[8] = 30;
			_loc2_[9] = 30;
		elif(GameData.PlayersArr[0].OrderId == 1):
			_loc2_[1] = 0;
			_loc2_[2] = 5;
			_loc2_[3] = 0;
			_loc2_[4] = 0;
			_loc2_[5] = 10;
			_loc2_[6] = 15;
			_loc2_[7] = 0;
			_loc2_[8] = 40;
			_loc2_[9] = 30;
		else:
			_loc2_[1] = 0;
			_loc2_[2] = 0;
			_loc2_[3] = 10;
			_loc2_[4] = 30;
			_loc2_[5] = 0;
			_loc2_[6] = 0;
			_loc2_[7] = 30;
			_loc2_[8] = 10;
			_loc2_[9] = 20;
	else:
		_loc6_=GameData.PlayersArr[0].car.global_position-car.global_position
		if(_loc6_.length() < 300):
			_loc2_[1] = 30;
			_loc2_[2] = 0;
			_loc2_[3] = 0;
			_loc2_[4] = 0;
			_loc2_[5] = 5;
			_loc2_[6] = 15;
			_loc2_[7] = 0;
			_loc2_[8] = 30;
			_loc2_[9] = 20;
		elif(GameData.PlayersArr[0].OrderId == 0):
			_loc2_[1] = 0;
			_loc2_[2] = 5;
			_loc2_[3] = 0;
			_loc2_[4] = 0;
			_loc2_[5] = 30;
			_loc2_[6] = 5;
			_loc2_[7] = 0;
			_loc2_[8] = 30;
			_loc2_[9] = 30;
		else:
			_loc2_[1] = 0;
			_loc2_[2] = 10;
			_loc2_[3] = 0;
			_loc2_[4] = 0;
			_loc2_[5] = 10;
			_loc2_[6] = 10;
			_loc2_[7] = 0;
			_loc2_[8] = 40;
			_loc2_[9] = 30;
	var _loc3_:int = 1;
	var _loc4_:int = 0;
	while(_loc3_ < _loc2_.size()):
		_loc4_ += _loc2_[_loc3_];
		if(_loc5_ < _loc4_):
			return _loc3_;
		_loc3_ = _loc3_ + 1;
	return 7
	#return randi_range(0,8)

func ResetUse()->void:
	CanUseProp=true

func UseProp()->void:
	if(IsPlayering() && not car.isSleep and CanUseProp and !IsUsingProp):
		prop.UseProp()
		CanUseProp=false
