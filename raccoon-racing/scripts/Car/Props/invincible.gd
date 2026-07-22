extends Prop
class_name InvincibleProp

var UseTime:int = 6;
var AddHorse:float = 1.5;
var tickactivate:int

func _init(playerinst:Player)->void:
	super(playerinst);
	proptype = 1;
	if(player.PlayerID == GameData.FocusPlayer.PlayerID && !player.car.isInvincible):
		MusicPlayer.PlayMusic("invincible")
	player.prop.del_prop_by_type(proptype);
	player.car.isInvincible = true
	player.car.prop_effector.AddInvincible(1.5)
	player.IsUsingProp=true
	tickactivate=NetworkTime.tick+NetworkTime.seconds_to_ticks(UseTime)
	delme()


func run()->void:
	pass
	
func delme()->void:
	if NetworkTime.tick!=tickactivate:
		return
	if is_instance_valid(player.car):
		player.IsUsingProp=false
		if(player.PlayerID==GameData.FocusPlayer.PlayerID):
			MusicPlayer.PlayMusic("map"+str(GameData.currentMap))
		player.prop.Delprop(self);
	
func del()->void:
	player.car.prop_effector.StopInvincible()
