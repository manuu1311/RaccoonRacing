extends Prop
class_name SleepProp


func _init(playerinst:Player)->void:
	super(playerinst);
	use_time=4
	proptype = 2;
	player.prop.del_prop_by_type(proptype);
	player.car.isSleep = true;
	player.car.prop_effector.PlaySleep()
	tick_end=NetworkTime.tick+NetworkTime.seconds_to_ticks(use_time)

func run_tick() -> void:
	if NetworkTime.tick>tick_end:
		delme()
	
func delme()->void:
	if is_instance_valid(player.car):
		player.prop.Delprop(self);
	
	
func del()->void:
	for playerinst:Player in GameData.PlayersArr:
		playerinst.car.prop_effector.StopSleepHudAnimation()
	player.car.prop_effector.StopSleep()
	player.car.sounds.StopBeSleepSound();
	player.car.isSleep = false;
