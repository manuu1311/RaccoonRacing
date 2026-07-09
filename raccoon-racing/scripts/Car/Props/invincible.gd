extends Prop
class_name InvincibleProp

var UseTime:int = 6;
var AddHorse:float = 1.5;

func _init(playerinst:Player)->void:
	super(playerinst);
	proptype = 1;
	if(player.PlayerID == 0 && !player.car.isInvincible):
		MusicPlayer.PlayMusic("invincible")
	player.prop.del_prop_by_type(proptype);
	player.car.isInvincible = true
	player.car.prop_effector.AddInvincible(1.5)
	player.IsUsingProp=true
	delme()


func run()->void:
	pass
	
func delme()->void:
	await player.car.get_tree().create_timer(UseTime).timeout
	if is_instance_valid(player.car):
		player.IsUsingProp=false
		if(player.PlayerID==0):
			MusicPlayer.PlayMusic("map"+str(GameData.currentMap))
		player.prop.Delprop(self);
	
func del()->void:
	player.car.prop_effector.StopInvincible()
