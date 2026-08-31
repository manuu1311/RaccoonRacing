extends Prop
class_name PetroProp


var AddHorse:float = 1.8;
var AddHorsebyAuto:float = 0.2;

func _init(playerinst:Player) -> void:
	super(playerinst);
	use_time=4
	proptype = 8;
	player.prop.del_prop_by_type(proptype);
	player.car.sounds.playPetroSound();
	player.car.IsUsingProp=true
	tick_end = NetworkTime.tick+NetworkTime.seconds_to_ticks(use_time)
	
func run_tick() -> void:
	if NetworkTime.tick<tick_end:
		player.car.prop_effector.AddPetro()
		if player.car.jumpCurrheight < 1:
			player.car.speed += Vector2(AddHorsebyAuto, 0).rotated(player.car.rotation - PI / 2)
		
	elif NetworkTime.tick>tick_end:
		delme()


func delme() -> void:
	if is_instance_valid(player.car):
		player.ResetUse()
		player.car.IsUsingProp = false
		player.car.prop_effector.StopPetro()
		player.prop.Delprop(self)
	
	
func del()->void:
	pass
