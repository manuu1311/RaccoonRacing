extends Prop
class_name PetroProp


var UseTime:float = 4;
var AddHorse:float = 1.8;
var AddHorsebyAuto:float = 0.2;
var endtick: int = 0

func _init(playerinst:Player) -> void:
	super(playerinst);
	proptype = 8;
	player.prop.del_prop_by_type(proptype);
	player.car.sounds.playPetroSound();
	player.car.IsUsingProp=true
	endtick = NetworkTime.tick+NetworkTime.seconds_to_ticks(UseTime)
	
func run_tick() -> void:
	if NetworkTime.tick<endtick:
		player.car.prop_effector.AddPetro()
		if player.car.jumpCurrheight < 1:
			player.car.speed += Vector2(AddHorsebyAuto, 0).rotated(player.car.rotation - PI / 2)
		
	elif NetworkTime.tick>endtick:
		delme()


func delme() -> void:
	if is_instance_valid(player.car):
		player.ResetUse()
		player.car.IsUsingProp = false
		player.car.prop_effector.StopPetro()
		player.prop.Delprop(self)
	
	
func del()->void:
	pass
