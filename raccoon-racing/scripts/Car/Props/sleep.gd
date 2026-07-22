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
	delme()

func run()->void:
	pass
func delme()->void:
	if NetworkTime.tick!=tickactivate:
		return
	if is_instance_valid(player.car):
		player.prop.Delprop(self);
	
	
func del()->void:
	player.car.prop_effector.StopSleep()
	player.car.sounds.StopBeSleepSound();
	player.car.isSleep = false;
	queue_free()
