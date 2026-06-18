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
	print('ohoh')
	await player.car.get_tree().create_timer(UseTime).timeout
	print('ya')
	player.prop.Delprop(self);

func del()->void:
	print('oki')
	player.prop.IsUseShield = false;
	player.car.prop_effector.RemoveShield()
