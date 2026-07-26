extends MissileInMap
class_name Propkn1InMap

var JumpHigh:int=4

func OnHitCar(car:Car)->void:
	if car.playerID!=aimed:
		return
	car.prop_effector.PlayBomb(global_position)
	car.sounds.playBedumpSound()
	if not is_multiplayer_authority():
		return
	if(!car.isInvincible && !car.IsUseShield):
		ApplyExplosion.rpc(car)

	if(car.IsUseShield):
		RemoveShield.rpc(car)
	ClearMissile.rpc()



@rpc('call_local','reliable')
func ApplyExplosion(car:Car)->void:
	var dist:Vector2=car.global_position-global_position
	car.bsex = 90;
	car.sounds.playerBombSound();
	car.speed*=0.1
	car.speed+=dist*0.03
	car.Jump(JumpHigh)
@rpc('call_local','reliable')
func RemoveShield(car:Car)->void:
	car.player.RemoveShield()
@rpc('call_local','reliable')
func ClearMissile()->void:
	queue_free()
	missileview.queue_free()
