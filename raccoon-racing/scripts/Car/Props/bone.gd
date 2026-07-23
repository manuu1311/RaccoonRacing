extends Prop
class_name BoneProp

var UseTime:float=4
var start_tick: int
var end_tick: int

func _init(playerinst:Player)->void:
	super(playerinst);
	proptype = 9;
	player.prop.del_prop_by_type(9)
	player.car.prop_effector.PlayBone()
	player.car.prop_effector.bonehit.connect(_on_bone_hit)
	start_tick = NetworkTime.tick
	end_tick = start_tick + int(NetworkTime.tickrate * UseTime)

func _on_bone_hit() -> void:
	end_tick = NetworkTime.tick

func run_tick(tick: int, is_fresh: bool) -> void:
	if tick >= end_tick:
		if is_fresh:
			_expire()
	if tick >end_tick+70:
		player.prop.Delprop(self)

func run()->void:
	player.car.prop_effector.bone.scale*=1.0007


func _expire() -> void:
	if is_instance_valid(player.car):
		player.car.sounds.StopdogSSound()
		player.car.prop_effector.StopBone()


func del()->void:
	player.car.sounds.StopdogSSound()
	player.car.prop_effector.StopBone()
	player.car.prop_effector.bonehit.disconnect(_on_bone_hit)
	queue_free()
