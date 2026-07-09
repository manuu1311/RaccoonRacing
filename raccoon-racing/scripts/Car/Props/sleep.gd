extends Prop
class_name SleepProp

var UseTime:float = 4

func _init(playerinst:Player)->void:
	super(playerinst);
	proptype = 2;
	player.prop.del_prop_by_type(proptype);
	player.car.isSleep = true;
	player.car.prop_effector.PlaySleep()
	delme()

func run()->void:
	pass
func delme()->void:
	await player.car.get_tree().create_timer(UseTime).timeout
	if is_instance_valid(player.car):
		player.prop.Delprop(self);
	
	
func del()->void:
	player.car.prop_effector.StopSleep()
	player.car.sounds.StopBeSleepSound();
	player.car.isSleep = false;
	queue_free()
