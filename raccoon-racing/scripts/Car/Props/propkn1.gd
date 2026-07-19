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
	HomingMissile.aimed = Aimplayer.PlayerID
	HomingMissile.MissileHit.connect(delme)
	SetDmc()

func SetDmc() -> void:
	player.car.map.add_child(HomingMissile)
	HomingMissile.global_position = player.car.global_position + Vector2(-25, 0).rotated(player.car.rotation)
	HomingMissile.rotation = player.car.rotation - PI / 2
	HomingMissile.speed = player.car.speed
	HomingMissile.NowPointId = player.car.NowPointId
	var view_sprite: Sprite2D = player.car.map.minimap
	view_sprite.add_child(HomingMissileView)
	if player.PlayerID == 0:
		player.car.sounds.playMissileSound()

func SetAimPlayer() -> Player:
	return GameData.PlayersArr[GameData.OrderInfo[0]]

func run_tick(_tick: int, _is_fresh: bool) -> void:
	if not is_instance_valid(HomingMissile):
		return
	HomingMissile.AutoPlay(player.car.map, Aimplayer)
	HomingMissile.UpdatePoint(player.car.map)
	HomingMissile.AddPetro()
	UpdateView()

func UpdateView() -> void:
	if not is_instance_valid(HomingMissile):
		return
	HomingMissileView.position = player.car.map.offset + HomingMissile.global_position * player.car.map.ScaledTimes
	HomingMissileView.rotation = HomingMissile.rotation

func delme() -> void:
	player.prop.Delprop(self)

func del() -> void:
	if is_instance_valid(HomingMissileView):
		HomingMissileView.queue_free()
	queue_free()
