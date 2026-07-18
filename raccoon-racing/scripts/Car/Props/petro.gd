extends Prop
class_name PetroProp


var UseTime:float = 4;
var AddHorse:float = 1.8;
var AddHorsebyAuto:float = 0.2;
var start_tick: int = 0
var max_ticks: int = 0
var ended: bool = false

func _init(playerinst:Player) -> void:
	super(playerinst);
	proptype = 8;
	player.prop.del_prop_by_type(proptype);
	player.car.sounds.playPetroSound();
	delme()
	player.IsUsingProp=true
	start_tick = NetworkTime.tick
	max_ticks = int(NetworkTime.tick_rate * UseTime)
	
func run_tick(tick: int, is_fresh: bool) -> void:
	if ended:
		return
	if player.car.jumpCurrheight < 1:
		player.car.speed += Vector2(AddHorsebyAuto, 0).rotated(player.car.rotation - PI / 2)
	player.car.prop_effector.AddPetro()

	if is_fresh:
		if tick == start_tick:
			player.car.sounds.playPetroSound()
		if tick - start_tick >= max_ticks:
			delme()

func run()->void:
	if player.car.jumpCurrheight<1:
		player.car.speed+=Vector2(AddHorsebyAuto,0).rotated(player.car.rotation-PI/2)
	player.car.prop_effector.AddPetro();
	

func delme() -> void:
	if ended:
		return
	ended = true
	if is_instance_valid(player.car):
		player.IsUsingProp = false
		player.ResetUse()
		player.car.prop_effector.StopPetro()
	player.prop.Delprop(self)
		
func del()->void:
	pass
