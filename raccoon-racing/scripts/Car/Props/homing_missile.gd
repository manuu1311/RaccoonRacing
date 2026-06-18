extends Prop
class_name HomingMissileProp


var Aimplayer:Player;
var HomingMissile:MissileInMap;
var HomingMissileView:Sprite2D
var NowPointId:int;
var EndTime:float = 30000;
var LockAim:bool = false;

func _init(playerinst:Player)->void:
    super(playerinst);
    proptype = 6;
    SetDmc();
    Aimplayer = SetAimPlayer();
    HomingMissile=preload(
        "res://Assets/Scenes/Screens/maps/Props/MissileInMap.tscn"
    ).instantiate() as MissileInMap
    HomingMissileView=preload(
        "res://Assets/Scenes/Screens/maps/MissileView.tscn"
    ).instantiate() as Sprite2D
    HomingMissile.onhitstatfun=OnHitStatus
    HomingMissile.onhitcarfun=OnHitCar.bind(
        Aimplayer.car,Aimplayer.PlayerID
        )
    

func SetDmc()->void:
    player.car.map.add_child(HomingMissile)
    HomingMissile.global_position=player.car.global_position+Vector2(0,25).rotated(player.car.rotation)
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
    return GameData.PlayersArr[GameData.OrderInfo[player.OrderId-1]]


func run()->void:
    AutoPlay();
    UpdatePoint();
    HomingMissile.Update();
    HomingMissile.AddPetro();


func OnHitStatus()->void:
    pass

func OnHitCar(car:Car,id:int)->void:
    if car.playerID!=id:
        return
    var dist:Vector2
    if(!car.isInvincible && !car.player.prop.IsUseShield):
        dist=car.global_position-HomingMissile.global_position
        car.bsex = 50;
        car.sounds.playBsSound();
        car.Speed+=dist*0.1

    if(car.player.prop.IsUseShield):
        car.player.prop.Delpropbytype(3);

    car.prop_effector.PlayBomb(HomingMissile.global_position)
    car.sounds.playBedumpSound();
    delme();

func AutoPlay()->void:
    HomingMissile.DoAction(0);
    var targetangle:float;
    if(NowPointId == Aimplayer.NowPointId || LockAim):
        var dist=Aimplayer.car.global_position-HomingMissile.global_position
        targetangle = rad_to_deg(atan2(dist.y, dist.x))
        LockAim = true;
    else:
        var dist=Aimplayer.car.map.Points[NowPointId]-HomingMissile.global_position
        targetangle = rad_to_deg(atan2(dist.y, dist.x))
    var anglediff:float=targetangle-HomingMissile.rotation_degrees
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
        if(NowPointId >= player.map.Points.size()):
            NowPointId = 0;

func delme()->void:
    pass
