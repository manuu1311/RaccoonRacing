extends Prop
class_name ShieldProp


var UseTime:float = 6;
var start_tick: int
var end_tick: int
var ended: bool = false

func _init(playerinst:Player)->void:
	super(playerinst);
	proptype = 3
	player.prop.del_prop_by_type(proptype);
	start_tick = NetworkTime.tick
	end_tick = start_tick + int(NetworkTime.tickrate * UseTime)

func run_tick(tick: int, is_fresh: bool) -> void:
	if ended:
		return
	if tick==start_tick+1:
		player.AddShield(is_fresh)
	if tick >= end_tick:
		player.RemoveShield(is_fresh)
		ended = true
	if tick>end_tick+70:
		_expire()

func _expire() -> void:
	if is_instance_valid(player.car):
		player.prop.Delprop(self)

func del()->void:
	pass
	#player.car.IsUseShield = false;
	#player.car.prop_effector.RemoveShield()

func _rollback_spawn() -> void:
	player.AddShield(false)

func _rollback_despawn() -> void:
	player.RemoveShield(false)
