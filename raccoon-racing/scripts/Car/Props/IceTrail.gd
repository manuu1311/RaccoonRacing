extends Prop
class_name IceTrailProp

@export var ice_width: float = 30.0
var IcePatchScene: PackedScene=preload("res://Assets/Scenes/Screens/maps/Props/IceTrail.tscn")
var trail: IceTrailInMap
var active: bool = true

func _init(playerinst: Player) -> void:
	super(playerinst)
	proptype = 12
	#delete previous ice trail, if there is any
	var icetrails: = playerinst.car.get_tree().get_nodes_in_group("icetrail")
	for icetrail:IceTrailInMap in icetrails:
		icetrail.queue_free()
	player.car.sounds.playIceSound()
	_spawn_trail()
	use_time=2
	tick_end = NetworkTime.tick + int(NetworkTime.tickrate * use_time)
	
	
func run_tick() -> void:
	if NetworkTime.tick>tick_end:
		delme()

func _spawn_trail() -> void:
	trail = IcePatchScene.instantiate()
	trail.car=player.car
	player.car.map.SpawnProp("IceTrail",player.PlayerID,trail)
	# Start the trail at the car's rear (70 units behind)
	trail.global_position = player.car.global_position + player.car.transform.y * 70



func delme()->void:
	player.prop.Delprop(self)
