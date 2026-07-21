extends Prop
class_name IceTrailProp

@export var ice_width: float = 30.0
var IcePatchScene: PackedScene=preload("res://Assets/Scenes/Screens/maps/Props/IceTrail.tscn")
var trail: IceTrailInMap
var active: bool = true

func _init(playerinst: Player) -> void:
	super(playerinst)
	proptype = 9
	player.car.sounds.playIceSound()
	_spawn_trail()

func _spawn_trail() -> void:
	trail = IcePatchScene.instantiate()
	trail.car=player.car
	player.car.map.add_child(trail)
	# Start the trail at the car's rear (70 units behind)
	trail.global_position = player.car.global_position + player.car.transform.y * 70



func delme()->void:
	player.prop.Delprop(self)
