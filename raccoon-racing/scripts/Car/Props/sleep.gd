extends Prop
class_name SleepProp

var UseTime:int = 4
var tickend:int

func _init(playerinst:Player)->void:
	super(playerinst);
	proptype = 2;
	player.prop.del_prop_by_type(proptype);
	player.car.isSleep = true;
	player.car.prop_effector.PlaySleep()
	tickend=NetworkTime.tick+NetworkTime.seconds_to_ticks(UseTime)

func run_tick() -> void:
	if NetworkTime.tick>tickend:
		delme()
	
func delme()->void:
	if is_instance_valid(player.car):
		player.prop.Delprop(self);
	
	
func del()->void:
	player.car.prop_effector.StopSleep()
	player.car.sounds.StopBeSleepSound();
	player.car.isSleep = false;
