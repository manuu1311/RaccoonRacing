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
	player.car.IsUseShield = true;
	player.car.prop_effector.AddShield()
	start_tick = NetworkTime.tick
	end_tick = start_tick + int(NetworkTime.tickrate * UseTime)

func run_tick(tick: int, is_fresh: bool) -> void:
	if ended:
		return
	if tick >= end_tick:
		ended = true
		if is_fresh:
			_expire()

func _expire() -> void:
	if is_instance_valid(player.car):
		player.car.IsUseShield = false
		player.car.prop_effector.RemoveShield()
		player.prop.Delprop(self)
	
func delme()->void:
	await player.car.get_tree().create_timer(UseTime).timeout
	if is_instance_valid(player.car):
		player.prop.Delprop(self);

func del()->void:
	pass
	#player.car.IsUseShield = false;
	#player.car.prop_effector.RemoveShield()
