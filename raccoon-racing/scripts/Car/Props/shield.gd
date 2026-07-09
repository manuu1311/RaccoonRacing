extends Prop
class_name ShieldProp


var UseTime:float = 6;
func _init(playerinst:Player)->void:
	super(playerinst);
	proptype = 3
	player.prop.del_prop_by_type(proptype);
	player.prop.IsUseShield = true;
	player.car.prop_effector.AddShield()
	delme()

func run()->void:
	pass
	
func delme()->void:
	await player.car.get_tree().create_timer(UseTime).timeout
	if is_instance_valid(player.car):
		player.prop.Delprop(self);

func del()->void:
	player.prop.IsUseShield = false;
	player.car.prop_effector.RemoveShield()
