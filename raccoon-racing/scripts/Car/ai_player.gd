extends Player
class_name AIPlayer

var AiPlayering:bool=false
var AiUsePropReflect:int=150
var ResetTimer:Timer
var AiResetTime:int=10
var AiLastCheckPoint:int
var IsOnlyAttPlayer:bool=false

func RunPropBox(x:float,y:float)->void:
	if hud==null:
		car.HasProp=true
		car.CanUseProp=true
		var id:int=GetPropPer()
		await car.get_tree().create_timer(1.5).timeout
		GetProp(id)
		return
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
		



func Update()->void:
	if(AiPlayering && car.playering):
		#AutoPlay()
		#AutoUseProp();
		AutoReSetCar();
	UpdatePoint()
	prop.run()
	
##return forward,brake,left,right
func AutoInput()->Array[bool]:
	var inputArr:Array[bool]=[0,0,0,0,0]
	inputArr[0]=true
	if(car.AiNowPushButtonTimeNow < car.AiNowPushButtonTime):
		inputArr[car.AiNowPushButton]=true
		car.AiNowPushButtonTimeNow = car.AiNowPushButtonTimeNow + 1;
	else:
		car.AiNowPushButtonTimeNow = 0;
		var angle_rad: float = atan2(
			car.map.Points[car.NowPointId].y - car.global_position.y,
			car.map.Points[car.NowPointId].x - car.global_position.x
		)
		var angle_diff: float = rad_to_deg(angle_rad-car.rotation+PI/2)
		angle_diff=wrapf(angle_diff, -180.0, 180.0)
		if angle_diff > 5 and angle_diff < 180:
			car.AiNowPushButton = 3
			car.AiNowPushButtonTime = angle_diff / AiReflect
		elif angle_diff < -5 and angle_diff > -180:
			car.AiNowPushButton = 2
			car.AiNowPushButtonTime = abs(angle_diff) / 45 + AiReflect
		else:
			car.AiNowPushButtonTime = AiReflect
			car.AiNowPushButton = 4
	return inputArr

func AutoPlay()->void:
	ActionCar(0);
	car.IsAccelerating=true
	if(car.AiNowPushButtonTimeNow < car.AiNowPushButtonTime):
		ActionCar(car.AiNowPushButton);
		car.AiNowPushButtonTimeNow = car.AiNowPushButtonTimeNow + 1;
	else:
		car.AiNowPushButtonTimeNow = 0;
		var angle_rad: float = atan2(
			car.map.Points[car.NowPointId].y - car.global_position.y,
			car.map.Points[car.NowPointId].x - car.global_position.x
		)
		var angle_diff: float = rad_to_deg(angle_rad-car.rotation+PI/2)
		angle_diff=wrapf(angle_diff, -180.0, 180.0)
		if angle_diff > 5 and angle_diff < 180:
			car.CurrentState=Car.turnstate.RIGHT
			car.AiNowPushButton = 3
			car.AiNowPushButtonTime = angle_diff / AiReflect
		elif angle_diff < -5 and angle_diff > -180:
			car.CurrentState=Car.turnstate.LEFT
			car.AiNowPushButton = 2
			car.AiNowPushButtonTime = abs(angle_diff) / 45 + AiReflect
		else:
			car.CurrentState=Car.turnstate.FORWARD
			car.AiNowPushButtonTime = AiReflect
			car.AiNowPushButton = 4


func ResetPlayer(order:int)->void:
	AiPlayering=false
	car.HasProp=false
	car.AiUsePropTime=0
	super(order)
  
func AutoUseProp() -> bool:
	car.AiUsePropTime += 1
	if car.AiUsePropTime <= AiUsePropReflect:
		return false

	car.AiUsePropTime = 0
	car.HasProp = false

	if car.map.IsPropPoint(car.NowPointId) and car.NowPorpId != 5:
		return true  # dump current prop to free the slot for a new pickup

	match car.NowPorpId:
		0:
			return false

		1: # Proximity Bomb/Obstacle
			for other in GameData.PlayersArr:
				if other.PlayerID != self.PlayerID:
					if other.prop.IsHavePropType(5) or other.prop.IsHavePropType(6) \
					or (other.prop.IsHavePropType(9)):
						return true
					if car.global_position.distance_to(other.car.global_position) < 300:
						return true
			for event_item in car.map.Events:
				if event_item.is_class("BombInMap") or event_item.is_class("BsInMap") or event_item.is_class("HoneyBombInMap"):
					if car.global_position.distance_to(event_item.global_position) < 300:
						return true

		2:
			return true

		3: # Shield vs incoming hazards
			for other in GameData.PlayersArr:
				if other.PlayerID != self.PlayerID:
					if other.prop.IsHavePropType(5) or other.prop.IsHavePropType(6) \
					or (other.prop.IsHavePropType(9) and other.car.CharID==2):
						return true

		4, 7: # Offensive targeting
			for other in GameData.PlayersArr:
				if other.PlayerID != self.PlayerID and not other.car.isInvincible:
					if car.global_position.distance_to(other.car.global_position) < 300:
						var point_delta: int = car.NowPointId - other.car.NowPointId
						if point_delta > 0 or point_delta < -10 or (point_delta == 0 and distance < other.distance):
							return true
			if car.map.IsWanPoint(car.NowPointId):
				return true

		5: # Shield / Boost
			if OrderId != 0:
				return true

		6: # Homing Missile
			return true

		8: # Speed Pad / Nitro Line
			if car.map.IsLinePoint(car.NowPointId):
				return true

		9:
			return _handle_prop_type_nine()

		_:
			push_error("Error UseProp Id")

	car.HasProp = false
	return false

func _handle_prop_type_nine() -> bool:
	match car.CharID:
		3,4:
			for other in GameData.PlayersArr:
				if not (IsOnlyAttPlayer and other.PlayerID != 0) and not other.car.isInvincible and other.PlayerID != self.PlayerID:
					if car.global_position.distance_to(other.car.global_position) < 300:
						var point_delta:int = car.NowPointId - other.car.NowPointId
						if point_delta > 0 or point_delta < -10 or (point_delta == 0 and distance < other.distance):
							return true
			if car.map.IsWanPoint(car.NowPointId):
				if IsOnlyAttPlayer:
					if OrderId >= GameData.PlayersArr.size() - 1:
						if GameData.OrderInfo[0] != 0: 
							return false
					elif GameData.OrderInfo[OrderId + 1] != 0: 
						return false
				return true
		1:
			if car.map.IsLinePoint(car.NowPointId):
				return true
		2:
			for other in GameData.PlayersArr:
				if other.PlayerID != self.PlayerID and not (IsOnlyAttPlayer and other.PlayerID != 0):
					if not other.car.isInvincible and not other.car.IsUseShield:
						if car.global_position.distance_to(other.car.global_position) < 300:
							return true
		5:
			for other in GameData.PlayersArr:
				if other.PlayerID != self.PlayerID and not (IsOnlyAttPlayer and other.PlayerID != 0):
					if not other.car.isInvincible and car.global_position.distance_to(other.car.global_position) < 300:
						return true
		6:
			for other in GameData.PlayersArr:
				if not (IsOnlyAttPlayer and other.PlayerID != 0) and other.PlayerID != self.PlayerID:
					if not other.car.isInvincible and not other.car.isResetting:
						if other.alldistance >= self.alldistance:
							# Original Flash calculation checked squared distance (< 100000)
							# 100000 squared distance equals ~316.2 pixels distance vector length.
							if car.global_position.distance_squared_to(other.car.global_position) < 100000:
								return true
	return false


func AutoReSetCar()->void:
	if(AiLastCheckPoint != car.NowPointId):
		ResetTimer.start()
		AiLastCheckPoint = car.NowPointId;

func ActionCar(action:int)->void:
	if(car.playering && not car.isSleep):
		DoAction(action);

func DoAction(action:int)->void:
	if car.jumpCurrheight<1:
		match(action):
			-1:
				car.Clearward()
			0:
				car.Forward()
			1:
				car.Backward()
			2:
				car.TurnLeft();
			3:
				car.TurnLRight();
			4:
				car.CancelTurn()
			_:
				car.CancelTurn()
			
func Stoprace()->void:
	AiPlayering = false;
	car.playering = false;
	ResetTimer.stop()
	for propinst:Prop in prop.propArr:
		prop.Delprop(propinst)
	prop.propArr=[]
	car.NowPointId=0

func Reset()->void:
	car.playering = false;
	car.isResetting = true;
	var newpos:Vector2 = car.map.Points[car.NowPointId - 1];
	var anglediff:float=(car.map.Points[car.NowPointId]-newpos).angle()
	car.Reset(newpos,anglediff)
	car.speed=Vector2(0,0)
	await car.get_tree().create_timer(1).timeout
	if is_instance_valid(car):
		RestartRace()

func RestartRace()->void:
	car.isResetting = false;
	car.playering = true;
	ResetTimer.start()
	
func StartRace()->void:
	AiPlayering=true
	car.playering = true;
	car.isLock = false;
	car.speed=Vector2.ZERO
	ResetTimer=Timer.new()
	car.add_child(ResetTimer)
	ResetTimer.one_shot=true
	ResetTimer.wait_time=AiResetTime
	ResetTimer.start()
	ResetTimer.timeout.connect(Reset)
	# 75% chance for fast AI (reflect_time = 10)
	var best_chance:float = 0.75
	# 5% chance for slow AI (reflect_time = 25)
	var worst_chance:float = 0.05 

	# Calculate dynamic success chance using remap()
	var success_chance:float = remap(AiReflect, 10, 22, best_chance, worst_chance)

	# Clamp to keep values strictly within range if ai_reflect ever goes outside 10..22
	success_chance = clamp(success_chance, worst_chance, best_chance)
	if randf() < success_chance:
		car.CanUseProp=true
		car.NowPorpId = 8
		UseProp()
