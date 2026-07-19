extends MoveObject
class_name MissileInMap

@onready var synchronizer: RollbackSynchronizer = $RollbackSynchronizer
var onhitstatfun:Callable
var onhitcarfun:Callable
var petrolength:int=0
var petrowidth:int=0
var horse:Vector2
var WheelLengthNum:float=0.5
var MaxWheelLength:int=10
var SpeedHorse:int=1
const effect:Resource=preload("res://Assets/Scenes/Screens/PropEffects/Petro.tscn")
@onready var bottom_effect: Node2D = $BottomEffect
var aimed:int
signal MissileHit
var LockAim: bool = false
var NowPointId: int = 0
#network
var hit: bool = false
var hit_tick: int = -1
const HIT_LINGER_TICKS := 6
var alive:bool=true

func _ready() -> void:
	horse=Vector2(SpeedHorse,0)

func OnHitStatus()->void:
	return

func OnHitCar(car:Car,is_fresh: bool=true)->void:
	if hit or car.playerID!=aimed:
		return
	hit=true
	var dist:Vector2
	if(!car.isInvincible && !car.player.car.IsUseShield):
		dist=car.global_position-global_position
		car.bsex = 50;
		car.sounds.playBsSound();
		car.speed+=dist*0.1

	if(car.player.car.IsUseShield):
		car.player.prop.del_prop_by_type(3);

	if is_fresh:
		car.prop_effector.PlayBomb(global_position)
		car.sounds.playBedumpSound()
		MissileHit.emit()

func reset(x:float,y:float,r:float)->void:
	global_position=Vector2(x,y)
	rotation=r
	Update();

func _rollback_tick(_delta: float, tick: int, _is_fresh: bool) -> void:
	if hit and tick - hit_tick >= HIT_LINGER_TICKS + 50:
		queue_free()
	if not alive:
		return
	if hit:
		if tick - hit_tick >= HIT_LINGER_TICKS:
			alive = false
			visible = false
			hide()
		return
	UpdateCarPos()
	UpdateSpeed()
	if bsEx > 0:
		rotation_degrees += min(bsEx, 30)
		bsEx -= 1

func Update()->void:
	UpdateCarPos();
	UpdateSpeed();
	if(bsEx > 0):
		rotation_degrees += min(bsEx,30);
		bsEx = bsEx - 1;
	
	
func DoAction(action:int)->void:
	match(action):
		 0:
			Forward()
		 2:
			TurnLeft();
		 3:
			TurnRight();

func Forward()->void:
	speed+=horse.rotated(rotation)
func TurnLeft()->void:
	rotation_degrees += - min(
		speed.length() * WheelLengthNum,MaxWheelLength
		)

func TurnRight()->void:
	rotation_degrees += + min(
		speed.length() * WheelLengthNum,MaxWheelLength
		)

func AddPetro()->void:
	var boost: Node2D = effect.instantiate() as Node2D
	
	boost.rotation=rotation-PI/2
	boost.global_position=global_position
	boost.global_position += Vector2(0,randf_range(-5.0, 5.0)).rotated(boost.rotation)
	var base_scale := (randi() % 60 + 40) * 0.7 / 100.0*petrowidth
	boost.scale = Vector2.ONE * base_scale
	bottom_effect.add_child(boost)
	#boost.top_level = true

func AutoPlay(Aimplayer: Player)->void:
	DoAction(0);
	var targetangle:float;
	if(NowPointId == Aimplayer.car.NowPointId || LockAim):
		var dist:Vector2=Aimplayer.car.global_position-global_position
		targetangle = rad_to_deg(atan2(dist.y, dist.x))
		LockAim = true;
	else:
		var dist:Vector2=Aimplayer.car.map.Points[NowPointId]-global_position
		targetangle = rad_to_deg(atan2(dist.y, dist.x))
	var anglediff:float=targetangle-rotation_degrees
	anglediff = wrapf(anglediff, -180.0, 180.0)
	if(anglediff > 5 && anglediff < 180):
		DoAction(3);
	elif(anglediff < -5 && anglediff > -180):
		DoAction(2);

	
func UpdatePoint()->void:
	if LockAim:
		return
	var _loc4_:Vector2;
	if(NowPointId + 1 < map.Points.size()):
		_loc4_ = map.Points[NowPointId + 1];
	else:
		_loc4_ = map.Points[0];
	var tonext:float=(_loc4_).distance_to(global_position)
	var tocurr:float=map.Points[NowPointId].distance_to(global_position)
	var between:float=map.Points[NowPointId].distance_to(_loc4_)
	if(tonext + 200 < between || tocurr < 200):
		NowPointId += 1;
		if(NowPointId >= map.Points.size()):
			NowPointId = 0;

func GetHitStatus(tx:float,ty:float)->void:
	var wallAngledeg:float =GetHitStatusAng(tx,ty)
	#no wall detected
	if(is_nan(wallAngledeg)):
		return 
	OnHitStatus()
	if IsHitWall:
		var speedangle:float=speed.angle()
		var wallAngle :float= deg_to_rad(wallAngledeg)
		var speedwallangle:float=wrapf(
			-2*rad_to_deg(speedangle-wallAngle),
			-180.0,
			180.0
		)
		#-pi/2 to account for godot's angle system
		var poswallangle:float=wrapf(
			rad_to_deg(wallAngle-rotation-PI/2),
			-180.0,
			180.0
		)
		var speedwallangle90:float=fmod(rad_to_deg(speedangle-wallAngle),180.0)
		if speedwallangle90>90:
			speedwallangle90=180-speedwallangle90
		if speedwallangle90<-90:
			speedwallangle90+=180
		speedwallangle90=abs(speedwallangle90)
		if(poswallangle >= 0 and poswallangle < 45 or poswallangle < -135):
			rotation_degrees+=(speed.length()+1)*0.1/map.Wallspring
		if(poswallangle < 0 and poswallangle > -45 or poswallangle > 135):
			rotation_degrees-=(speed.length()+1)*0.1/map.Wallspring
		var loc1:float=wrapf(
			rad_to_deg(speedangle-wallAngle),
			-180.0,
			180
		)
		if(not (loc1>0 and loc1<180)):
			if(abs(speedwallangle) < 60):
				speedwallangle *=0.5
			speed=speed.rotated(deg_to_rad(speedwallangle))

		speed*=(1-map.Wallspring/2*(speedwallangle90*abs(abs(poswallangle)-90)/90))
		speed+=(Vector2(0.1,0).rotated(deg_to_rad(wallAngledeg+90)))
		stepx = int(speed.x * 10.0) / 10.0
		stepy = int(speed.y * 10.0) / 10.0
		tempx = position.x + stepx
		tempy = position.y + stepy


func UpdateSpeed()->void:
	var dir:int
	var speed_angle_deg: float = rad_to_deg(speed.angle())
	moveAngCar = wrapf(speed_angle_deg - rotation_degrees, -180.0, 180.0)
	friction = abs(moveAngCar)
	if(friction > 90):
		friction = 180 - friction;
	var dragFactor:float=(0.02 + int(friction) * 0.0008)
	speed *= max(0.0, 1.0 - dragFactor)
	if(moveAngCar < 90 and moveAngCar > 0 or moveAngCar < -90):
		dir = -1;
	else:
		dir = 1;
	#calculate magnitude and direction of force
	speed+= (speed*0.0008*int(90-friction)).rotated(deg_to_rad(90*dir))
