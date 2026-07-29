extends Prop
class_name ShieldProp


var UseTime:float = 6;
var end_tick: int
var ended: bool = false

func _init(playerinst:Player)->void:
	super(playerinst);
	proptype = 3
	player.prop.del_prop_by_type(proptype);
	end_tick = NetworkTime.tick + NetworkTime.seconds_to_ticks(UseTime)
	player.AddShield()
	
func run_tick() -> void:
	if NetworkTime.tick>end_tick:
		delme()

func delme() -> void:
	if is_instance_valid(player.car):
		player.prop.Delprop(self)

func del()->void:
	player.RemoveShield()
