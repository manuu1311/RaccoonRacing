extends Prop
class_name IceTrailProp

@export var stamp_interval: float = 0.15   # how often to drop a patch
@export var grow_time: float = 2.0          # matches original CarUse window

var growing := true
var stamp :int= 0

var IcePatchScene :Resource


func _init(playerinst:Player)->void:
	super(playerinst);
	proptype = 9;
	IcePatchScene=preload("res://Assets/Scenes/Screens/maps/Props/IceTrail.tscn")
	player.car.sounds.playIceSound()
	delme()

func advance() -> void:
	stamp += 1
	if stamp >= 3:
		stamp = 0
		_drop_ice_stamp()

func run()->void:
	advance()


func delme()->void:
	await player.car.map.get_tree().create_timer(grow_time).timeout
	if is_instance_valid(player.car):
		player.prop.Delprop(self)
	
func del()->void:
	queue_free()


func _drop_ice_stamp()->void:
	var patch:Node2D = IcePatchScene.instantiate()
	player.car.map.add_child(patch)
	patch.global_position = player.car.global_position + player.car.transform.y * 70
