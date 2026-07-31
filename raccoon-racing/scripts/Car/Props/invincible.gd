extends Prop
class_name InvincibleProp

var UseTime:int = 6;
var AddHorse:float = 1.5;
var tickend:int

func _init(playerinst:Player)->void:
	super(playerinst);
	proptype = 1;
	if(player.current_control==Player.control_type.HUMAN && !player.car.isInvincible):
		MusicPlayer.PlayMusic("invincible")
	player.prop.del_prop_by_type(proptype);
	player.car.isInvincible = true
	player.car.prop_effector.AddInvincible(1.5)
	player.car.IsUsingProp=true
	tickend=NetworkTime.tick+NetworkTime.seconds_to_ticks(UseTime)


func run_tick() -> void:
	if NetworkTime.tick>tickend:
		delme()
	
func delme()->void:
	if is_instance_valid(player.car):
		player.car.IsUsingProp=false
		if(player.current_control==Player.control_type.HUMAN):
			MusicPlayer.PlayMusic("map"+str(GameData.currentMap))
		player.prop.Delprop(self);
	
func del()->void:
	player.car.prop_effector.StopInvincible()
