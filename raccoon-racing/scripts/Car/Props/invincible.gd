extends Prop
class_name InvincibleProp


var AddHorse:float = 1.5;

func _init(playerinst:Player)->void:
	super(playerinst);
	use_time = 6
	proptype = 1;
	if(player.current_control==Player.control_type.HUMAN && !player.car.isInvincible):
		MusicPlayer.PlayMusic("invincible")
	player.prop.del_prop_by_type(proptype);
	player.car.isInvincible = true
	player.car.prop_effector.AddInvincible(1.5)
	player.car.IsUsingProp=true
	tick_end=NetworkTime.tick+NetworkTime.seconds_to_ticks(use_time)


func run_tick() -> void:
	if NetworkTime.tick>tick_end:
		delme()
	
func delme()->void:
	if is_instance_valid(player.car):
		player.car.IsUsingProp=false
		if(player.current_control==Player.control_type.HUMAN):
			MusicPlayer.PlayMusic("map"+str(GameData.currentMap))
		player.prop.Delprop(self);
	
func del()->void:
	player.car.prop_effector.StopInvincible()
