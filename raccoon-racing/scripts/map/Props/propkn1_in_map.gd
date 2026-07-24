extends MissileInMap
class_name Propkn1InMap

var JumpHigh:int=4

func OnHitCar(car:Car,is_fresh:bool=true)->void:
	if hit or car.playerID!=aimed:
		return
	hit = true
	hit_tick = int(NetworkTime.tick)
	var dist:Vector2
	if(!car.isInvincible && !car.player.car.IsUseShield):
		dist=car.global_position-global_position
		car.bsex = 90;
		car.Jump(JumpHigh)
		car.speed*=0.1
		car.speed+=dist*0.03
		if is_fresh:
			car.sounds.playerBombSound()

	if(car.player.car.IsUseShield):
		car.player.RemoveShield(is_fresh);

	if is_fresh:
		car.prop_effector.PlayBomb(global_position)
		car.sounds.playBedumpSound()
		MissileHit.emit()
