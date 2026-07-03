extends MissileInMap
class_name Propkn1InMap

var JumpHigh:int=4

func OnHitCar(car:Car)->void:
	if car.playerID!=aimed:
		return
	var dist:Vector2
	if(!car.isInvincible && !car.player.prop.IsUseShield):
		dist=car.global_position-global_position
		car.bsex = 90;
		car.Jump(JumpHigh)
		car.sounds.playerBombSound();
		car.speed*=0.1
		car.speed+=dist*0.03

	if(car.player.prop.IsUseShield):
		car.player.prop.del_prop_by_type(3);

	car.prop_effector.PlayBomb(global_position)
	car.sounds.playBedumpSound();
	MissileHit.emit()
