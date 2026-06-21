extends Node2D
class_name  Player

var car: Car
var PlayerID:int
#TODO: should be set by game manager
##character id 1-6
var charid:int=2
enum control_type{HUMAN,AI,MULTIPLAYER,RLTRAINING,RL}
var current_control:control_type
##position in the race, int
var current_race_position:int
var alldistance:int
var prop:PropManager
var PropBoxRunTimerId:int=-1
var CanUseProp:bool=false
var IsUsingProp:bool=false
var NowPointId:int
var OrderId:int
var LapsLock:bool
var Laps:int
var distance:int

func _init(id:int,control:control_type) -> void:
	PlayerID=id
	#TODO: manage ordering
	OrderId=id
	current_control=control
	prop=PropManager.new(self)
	

func SetCar(carinst:Car)->void:
	car=carinst
	car.prop_hud.prop_visible.connect(ResetUse)

func IsPlayering()->bool:
	return current_control==control_type.HUMAN

func Update()->void:
	UpdatePoint()
	car.Update()
	prop.run()
	
	
 
	
func UpdatePoint() -> void:
	if !IsPlayering():
		return
	var _loc4_: Vector2
	if NowPointId + 1 < car.map.Points.size():
		_loc4_ = car.map.Points[NowPointId + 1]
	else:
		_loc4_ = car.map.Points[0]

	var tonext: float = _loc4_.distance_to(car.global_position)
	var between: float = car.map.Points[NowPointId].distance_to(_loc4_)
	distance = car.map.Points[NowPointId].distance_to(car.global_position)

	if NowPointId == 0 and !LapsLock:
		alldistance = (Laps + 1) * 10000000 + NowPointId * 10000 + (10000 - distance)
	else:
		alldistance = Laps * 10000000 + NowPointId * 10000 + (10000 - distance)

	WinJudge()  # was in the original — confirm if you meant to drop it

	if tonext + 200 < between || distance < 200:
		NowPointId += 1
		if NowPointId >= car.map.Points.size():
			NowPointId = 0

func WinJudge()->void:
	pass

 

func RunPropBox(x:float,y:float)->void:
	car.sounds.GetProp()
	if not car.prop_hud.itemready:
		car.prop_hud.propmove(x,y)
	if prop.NowPorpId!=0:
		return
	GetProp(GetPropPer())
	car.prop_hud.StartPropBox(1.5,prop.NowPorpId)


			

func GetProp(propid:int)->void:
	prop.NowPorpId=propid

func ClearPropBox(id:int)->void:
	car.prop_hud.PropUsed(id)


func GetPropPer()->int:
	return 9
	var _loc5_:int = randi_range(1,99);
	if(charid == 1 && OrderId == 0 && PlayerID == 0):
		_loc5_ = randi_range(0,89);
	if(charid == 1 && OrderId == 1 && PlayerID == 0):
		_loc5_ = randi_range(0,79);
	var _loc2_:Array[int] = [0,0,0,0,0,0,0,0,0,0,0];
	var _loc6_:Vector2;
	#TODO: is selectlevelid the difficulty?
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
