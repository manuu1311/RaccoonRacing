extends Prop
class_name HomingMissileProp


var Aimplayer:Player;
var HomingMissile:MissileInMap;
var HomingMissileView:Sprite2D

func _init(playerinst:Player)->void:
	super(playerinst);
	proptype = 6;
	Aimplayer = SetAimPlayer();
	HomingMissile=preload(
        "res://Assets/Scenes/Screens/maps/Props/MissileInMap.tscn"
	).instantiate() as MissileInMap
	HomingMissileView=preload(
        "res://Assets/Scenes/Screens/maps/MissileView.tscn"
	).instantiate() as Sprite2D
	HomingMissile.aimed=Aimplayer.PlayerID
	HomingMissile.MissileHit.connect(delme)
	HomingMissile.map=player.car.map
	SetDmc();
	

func SetDmc()->void:
	player.car.map.SpawnProp("HomingMissile",player.PlayerID,HomingMissile)
	HomingMissile.global_position=player.car.global_position+Vector2(-25,0).rotated(player.car.rotation)
	HomingMissile.rotation=player.car.rotation-PI/2
	var view_sprite:Sprite2D = player.car.map.minimap
	view_sprite.add_child(HomingMissileView)
	HomingMissile.missileview=HomingMissileView
	HomingMissile.AimPlayer=Aimplayer
	HomingMissile.speed=player.car.speed
	HomingMissile.petrolength=10
	HomingMissile.petrowidth=1
	if player.PlayerID == GameData.FocusPlayer.PlayerID:
		player.car.sounds.playMissileSound()


func SetAimPlayer()->Player:
	return GameData.PlayersArr[GameData.OrderInfo[player.OrderId-1]]

func run_tick(_tick: int, _is_fresh: bool) -> void:
	if not is_instance_valid(HomingMissile):
		return
	#HomingMissile.AutoPlay(Aimplayer)
	#HomingMissile.UpdatePoint()
	#HomingMissile.AddPetro()
	#UpdateView()

func run()->void:
	pass
	#HomingMissile.AutoPlay();
	#HomingMissile.UpdatePoint();
	#HomingMissile.Update();
	#HomingMissile.AddPetro();
	#UpdateView()


func OnHitStatus()->void:
	pass

func delme()->void:
	player.prop.Delprop(self)

func del()->void:
	if is_instance_valid(HomingMissileView):
		HomingMissileView.queue_free()
	queue_free()
