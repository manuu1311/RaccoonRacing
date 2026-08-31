extends Prop
class_name BoneProp


func _init(playerinst:Player)->void:
	super(playerinst);
	use_time=4
	proptype = 11;
	player.prop.del_prop_by_type(11)
	player.car.prop_effector.PlayBone()
	player.car.prop_effector.bonehit.connect(_on_bone_hit)
	tick_end = NetworkTime.tick + int(NetworkTime.tickrate * use_time)

func _on_bone_hit(caropp:Car) -> void:
	ClearBone(caropp)


func ClearBone(caropp:Car)->void:
		caropp.prop_effector.PlayBomb(player.car.prop_effector.bone.global_position)
		caropp.sounds.playBedumpSound()
		Clear()
	

func Clear()->void:
	tick_end = NetworkTime.tick

func run_tick() -> void:
	player.car.prop_effector.bone.scale*=1.0007
	if NetworkTime.tick >= tick_end:
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
