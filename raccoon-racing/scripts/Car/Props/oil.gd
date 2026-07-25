extends Prop
class_name OilProp


var bs_in_map:EventInMap
var lifetime:int=30

func _init(playerinst:Player)->void:
	super(playerinst);
	proptype = 7;
	bs_in_map=preload("res://Assets/Scenes/Screens/maps/Props/BsInMap.tscn"
	).instantiate() as EventInMap
	bs_in_map.lifetime=30
	var pos:Vector2=Vector2(0,20).rotated(player.car.rotation)+player.car.global_position
	player.car.map.AddEventInMap(bs_in_map)
	bs_in_map.setup(player.car.map,pos.x,pos.y,50,50,player.car.rotation_degrees)
	player.car.sounds.playoilSound();
	
func run_tick() -> void:
	pass

	
func delme()->void:
	if is_instance_valid(player.car):
		player.prop.Delprop(self);
	
func del()->void:
	pass
