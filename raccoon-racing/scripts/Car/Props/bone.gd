extends Prop
class_name BoneProp

var UseTime:float=4
var end_tick: int
var isactive:bool=true

func _init(playerinst:Player)->void:
	super(playerinst);
	proptype = 9;
	player.prop.del_prop_by_type(9)
	player.car.prop_effector.PlayBone()
	player.car.prop_effector.bonehit.connect(_on_bone_hit)
	end_tick = NetworkTime.tick + int(NetworkTime.tickrate * UseTime)

func _on_bone_hit(caropp:Car) -> void:
	if is_multiplayer_authority():
		if not caropp.isInvincible:
			if caropp.player.car.IsUseShield:
				RemoveShield.rpc(caropp.playerID)
			else:
				ApplyEffect.rpc(caropp.playerID)


@rpc('call_local','reliable')
func ApplyEffect(caroppid:int)->void:
	var caropp:Car=GameData.PlayersArr[caroppid].car
	var dist:Vector2 =caropp.global_position-(player.car.global_position)
	var loc7:float=0.005
	var distsq:float=dist.length_squared()
	if distsq<2000:
		loc7 = 0.005 + 0.05 * (2000 - distsq) / 2000;
	var knockback:Vector2=dist*loc7
	caropp.speed-=knockback*40
	caropp.bs=true
	ClearBone(caropp)

@rpc('call_local','reliable')
func RemoveShield(caroppid:int)->void:
	var caropp:Car=GameData.PlayersArr[caroppid].car
	caropp.player.RemoveShield()
	ClearBone(caropp)

func ClearBone(caropp:Car)->void:
	if isactive:
		caropp.prop_effector.PlayBomb(player.car.prop_effector.bone.global_position)
		caropp.sounds.playBedumpSound()
		_expire()
	

func Clear()->void:
	end_tick = NetworkTime.tick

func run_tick() -> void:
	player.car.prop_effector.bone.scale*=1.0007
	if NetworkTime.tick >= end_tick and isactive:
		_expire()



func _expire() -> void:
	isactive=false
	if is_instance_valid(player.car):
		player.car.sounds.StopdogSSound()
		player.car.prop_effector.StopBone()
	player.prop.Delprop(self)


func del()->void:
	player.car.sounds.StopdogSSound()
	player.car.prop_effector.StopBone()
	player.car.prop_effector.bonehit.disconnect(_on_bone_hit)
	queue_free()
