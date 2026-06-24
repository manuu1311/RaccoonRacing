extends Prop
class_name Propkn1Prop


var Aimplayer:Player;
var HomingMissile:Propkn1InMap;
var HomingMissileView:Sprite2D
var NowPointId:int;
var EndTime:float = 30000;
var LockAim:bool = false;

func _init(playerinst:Player)->void:
	super(playerinst);
	proptype = 5;
	Aimplayer = SetAimPlayer();
	HomingMissile=preload(
        "res://Assets/Scenes/Screens/maps/Props/Propkn1InMap.tscn"
	).instantiate() as Propkn1InMap
	HomingMissileView=preload(
        "res://Assets/Scenes/Screens/maps/PropknView.tscn"
	).instantiate() as Sprite2D
	HomingMissile.aimed=Aimplayer.PlayerID
	HomingMissile.MissileHit.connect(delme)
	SetDmc();
	

func SetDmc()->void:
	player.car.map.add_child(HomingMissile)
	HomingMissile.global_position=player.car.global_position+Vector2(-25,0).rotated(player.car.rotation)
	HomingMissile.rotation=player.car.rotation
	var view_sprite:Sprite2D = player.car.map.minimap
	view_sprite.add_child(HomingMissileView)
	HomingMissile.speed=player.car.speed
	HomingMissile.petrolength=10
	HomingMissile.petrowidth=1
	HomingMissile.Update()
	NowPointId=player.NowPointId
	player.car.sounds.playMissileSound()

#TODO: is that mess really needed?
func SetAimPlayer()->Player:
	return GameData.PlayersArr[0]


func run()->void:
	AutoPlay();
	UpdatePoint();
	HomingMissile.Update();
	HomingMissile.AddPetro();
	UpdateView()


func OnHitStatus()->void:
	pass


func AutoPlay()->void:
	HomingMissile.DoAction(0);
	var targetangle:float;
	if(NowPointId == Aimplayer.NowPointId || LockAim):
		var dist:Vector2=Aimplayer.car.global_position-HomingMissile.global_position
		targetangle = rad_to_deg(atan2(dist.y, dist.x))
		LockAim = true;
	else:
		var dist:Vector2=Aimplayer.car.map.Points[NowPointId]-HomingMissile.global_position
		targetangle = rad_to_deg(atan2(dist.y, dist.x))
	var anglediff:float=targetangle-HomingMissile.rotation_degrees+90
	anglediff = wrapf(anglediff, -180.0, 180.0)
	if(anglediff > 5 && anglediff < 180):
		HomingMissile.DoAction(3);
	elif(anglediff < -5 && anglediff > -180):
		HomingMissile.DoAction(2);

	
func UpdatePoint()->void:
	if LockAim:
		return
	var _loc4_:Vector2;
	if(NowPointId + 1 < player.car.map.Points.size()):
		_loc4_ = player.car.map.Points[NowPointId + 1];
	else:
		_loc4_ = player.car.map.Points[0];
	var tonext:float=(_loc4_).distance_to(HomingMissile.global_position)
	var tocurr:float=player.car.map.Points[NowPointId].distance_to(HomingMissile.global_position)
	var between:float=player.car.map.Points[NowPointId].distance_to(_loc4_)
	if(tonext + 200 < between || tocurr < 200):
		NowPointId += 1;
		if(NowPointId >= player.car.map.Points.size()):
			NowPointId = 0;

func UpdateView()->void:
	HomingMissileView.position=player.car.map.offset+HomingMissile.global_position*player.car.map.ScaledTimes
	HomingMissileView.rotation=HomingMissile.rotation-PI/2

func delme()->void:
	player.prop.Delprop(self)

func del()->void:
	HomingMissile.queue_free()
	HomingMissileView.queue_free()
	queue_free()
