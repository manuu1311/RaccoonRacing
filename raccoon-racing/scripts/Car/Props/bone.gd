extends Prop
class_name BoneProp

var UseTime:float=4

func _init(playerinst:Player)->void:
	super(playerinst);
	proptype = 9;
	player.prop.del_prop_by_type(9)
	delme()
	player.car.prop_effector.PlayBone()
	player.car.prop_effector.bonehit.connect(DeleteProp)

func run()->void:
	player.car.prop_effector.bone.scale*=1.0007

# Called every frame. 'delta' is the elapsed time since the previous frame.
func delme() -> void:
	await player.car.get_tree().create_timer(UseTime).timeout
	if is_instance_valid(player.car):
		DeleteProp()

func DeleteProp()->void:
	player.prop.Delprop(self)

func del()->void:
	player.car.sounds.StopdogSSound()
	player.car.prop_effector.StopBone()
	queue_free()
