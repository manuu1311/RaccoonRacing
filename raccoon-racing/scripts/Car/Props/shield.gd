extends Prop
class_name ShieldProp


var ended: bool = false

func _init(playerinst:Player)->void:
	super(playerinst);
	use_time=8
	proptype = 3
	player.prop.del_prop_by_type(proptype);
	tick_end = NetworkTime.tick + NetworkTime.seconds_to_ticks(use_time)
	player.AddShield()
	
func run_tick() -> void:
	if NetworkTime.tick>tick_end:
		delme()

func delme() -> void:
	if is_instance_valid(player.car):
		#player.prop.Delprop(self)
		player.RemoveShield()

func del()->void:
	pass
