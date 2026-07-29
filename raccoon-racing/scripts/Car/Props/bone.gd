extends Prop
class_name BoneProp

var UseTime:float=4
var end_tick: int

func _init(playerinst:Player)->void:
	super(playerinst);
	proptype = 9;
	player.prop.del_prop_by_type(9)
	player.car.prop_effector.PlayBone()
	player.car.prop_effector.bonehit.connect(_on_bone_hit)
	end_tick = NetworkTime.tick + int(NetworkTime.tickrate * UseTime)

func _on_bone_hit(caropp:Car) -> void:
	ClearBone(caropp)



func ClearBone(caropp:Car)->void:
		caropp.prop_effector.PlayBomb(player.car.prop_effector.bone.global_position)
		caropp.sounds.playBedumpSound()
		Clear()
	

func Clear()->void:
	end_tick = NetworkTime.tick

func run_tick() -> void:
	player.car.prop_effector.bone.scale*=1.0007
	if NetworkTime.tick >= end_tick:
		_expire()



func _expire() -> void:
	if is_instance_valid(player.car):
		player.car.sounds.StopdogSSound()
		player.car.prop_effector.StopBone()
	player.prop.Delprop(self)


func del()->void:
	player.car.sounds.StopdogSSound()
	player.car.prop_effector.StopBone()
	player.car.prop_effector.bonehit.disconnect(_on_bone_hit)
	queue_free()
