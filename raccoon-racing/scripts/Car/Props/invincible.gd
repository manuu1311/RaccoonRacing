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
	player.car.IsUsingProp=true
	tickactivate=NetworkTime.tick+NetworkTime.seconds_to_ticks(UseTime)


func run_tick(tick: int, is_fresh: bool) -> void:
	if is_instance_valid(player.car) and tick==tickactivate:
		player.car.IsUsingProp=false
		if(player.PlayerID==GameData.FocusPlayer.PlayerID) and is_fresh:
			MusicPlayer.PlayMusic("map"+str(GameData.currentMap))
			player.car.prop_effector.StopInvincible()
	if tick>tickactivate+70:
		player.prop.Delprop(self);
	
func delme()->void:
	if NetworkTime.tick!=tickactivate:
		return
	if is_instance_valid(player.car):
		player.car.IsUsingProp=false
		if(player.PlayerID==GameData.FocusPlayer.PlayerID):
			MusicPlayer.PlayMusic("map"+str(GameData.currentMap))
		player.prop.Delprop(self);
	
func _rollback_spawn() -> void:
	player.car.isInvincible = true
	player.car.IsUsingProp=true

func _rollback_despawn() -> void:
	player.car.isInvincible = false
	player.car.IsUsingProp=false
