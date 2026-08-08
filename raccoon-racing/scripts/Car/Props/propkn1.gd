extends Prop
class_name Propkn1Prop

var Aimplayer: Player
var HomingMissile: Propkn1InMap
var HomingMissileView: Sprite2D

func _init(playerinst: Player) -> void:
	super(playerinst)
	proptype = 5
	Aimplayer = SetAimPlayer()
	HomingMissile = preload("res://Assets/Scenes/Screens/maps/Props/Propkn1InMap.tscn").instantiate() as Propkn1InMap
	HomingMissileView = preload("res://Assets/Scenes/Screens/maps/PropknView.tscn").instantiate() as Sprite2D
	HomingMissile.map=player.car.map
	SetDmc()
	delme()

func SetDmc()->void:
	player.car.map.SpawnProp("HomingMissile",player.PlayerID,HomingMissile)
	HomingMissile.global_position=player.car.global_position+Vector2(-25,0).rotated(player.car.rotation)
	HomingMissile.rotation=player.car.rotation-PI/2
	var view_sprite:Sprite2D = player.car.map.minimap
	view_sprite.add_child(HomingMissileView)
	HomingMissile.missileview=HomingMissileView
	HomingMissile.AimPlayer=Aimplayer
	HomingMissile.NowPointId=player.car.NowPointId
	HomingMissile.speed=player.car.speed
	HomingMissile.petrolength=10
	HomingMissile.petrowidth=1
	if player.current_control==Player.control_type.HUMAN:
		player.car.sounds.playMissileSound()

func SetAimPlayer() -> Player:
	return GameData.PlayersArr[GameData.OrderInfo[0]]



func delme() -> void:
	player.prop.Delprop(self)

func del() -> void:
	pass
