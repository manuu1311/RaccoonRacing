extends Prop
class_name OilProp


var bs_in_map:EventInMap;
var arm_tick: int
var armed: bool = false
var done: bool = false

func _init(playerinst:Player)->void:
	super(playerinst);
	proptype = 7;
	bs_in_map=preload("res://Assets/Scenes/Screens/maps/Props/BsInMap.tscn"
	).instantiate() as EventInMap
	bs_in_map.LIFETIME_TICKS=NetworkTime.tickrate*30
	var pos:Vector2=Vector2(0,20).rotated(player.car.rotation)+player.car.global_position
	player.car.map.AddEventInMap(bs_in_map)
	bs_in_map.setup(player.car.map,pos.x,pos.y,50,50,player.car.rotation_degrees)
	bs_in_map.IsActivated = false;
	player.car.sounds.playoilSound();
	arm_tick = NetworkTime.tick + int(NetworkTime.tickrate * 0.3)
	
func run_tick(tick: int, is_fresh: bool) -> void:
	if done:
		return
	if not armed and tick >= arm_tick:
		armed = true
		if is_instance_valid(bs_in_map):
			bs_in_map.IsActivated = true
		done = true
		if is_fresh:
			player.prop.Delprop(self)
	
func run()->void:
	pass
	
func delme()->void:
	await player.car.get_tree().create_timer(30).timeout
	if is_instance_valid(player.car):
		player.prop.Delprop(self);
	
func del()->void:
	if is_instance_valid(bs_in_map) and is_instance_valid(player.car.map):
		player.car.map.DelEventInMap(bs_in_map.edface.getId())
