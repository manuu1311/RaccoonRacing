extends Prop
class_name Propkn1Prop


var Aimplayer:Player;
var HomingMissile:MoveObject
var BombEffect
var NowPointId:int
var jumphigh:int = 4;
func _init(playerinst:Player)->void:
    super(playerinst);
    proptype = 5;
    SetAimPlayer();

func SetAimPlayer()->void:
      Aimplayer = GameData.PlayersArr[GameData.OrderInfo[0]];

func SetObj()->void:
    pass


func onHitCar(car:Car)->void:
    if(!car.isInvincible && !car.player.prop.IsUseShield):
        var direction:Vector2=car.global_position-HomingMissile.global_position
        car.bsEx = 90;
        car.Jump(jumphigh);
        car.speed=car.speed*0.1+direction*0.03
        car.sounds.playerBombSound();
    if(car.player.prop.IsUseShield):
        car.player.prop.Delpropbytype(3);
    car.prop_effector.PlayBomb(HomingMissile.global_position)
    car.sounds.playBedumpSound();
    delme()
    
    
func delme()->void:
    pass
    
