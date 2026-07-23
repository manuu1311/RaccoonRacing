extends Prop
class_name SleepProp

var UseTime:int = 4
var tickactivate:int

func _init(playerinst:Player)->void:
	super(playerinst);
	proptype = 2;
	player.prop.del_prop_by_type(proptype);
	player.car.isSleep = true;
	player.car.prop_effector.PlaySleep()
	tickactivate=NetworkTime.tick+NetworkTime.seconds_to_ticks(UseTime)

func run_tick(tick: int, is_fresh: bool) -> void:
	if tick==tickactivate:
		player.car.isSleep = false;
		if is_fresh:
			player.car.prop_effector.StopSleep()
			player.car.sounds.StopBeSleepSound();
	if tick>tickactivate+70:
		delme()
	
func delme()->void:
	if is_instance_valid(player.car):
		player.prop.Delprop(self);
	
	
func del()->void:
	queue_free()
