extends Prop
class_name HoneyProp


var bomb_in_map1:EventInMap;
var bomb_in_map2:EventInMap;
var arm_tick: int
var armed: bool = false
var done: bool = false

func _init(playerinst: Player) -> void:
	super(playerinst)
	proptype = 9

	bomb_in_map1 = preload("res://Assets/Scenes/Screens/maps/Props/HoneyBombInMap.tscn").instantiate() as EventInMap
	bomb_in_map2 = preload("res://Assets/Scenes/Screens/maps/Props/HoneyBombInMap.tscn").instantiate() as EventInMap
	bomb_in_map1.IsActivated = false
	bomb_in_map2.IsActivated = false

	var car_rotation: float = player.car.rotation
	var spread_angle: float = deg_to_rad(30)

	# Same spawn point for both, just offset a bit in front of the car
	var spawn_pos: Vector2 = player.car.global_position + Vector2(0, 25).rotated(car_rotation)

	var angle1: float = car_rotation +PI - spread_angle 
	var angle2: float = car_rotation +PI + spread_angle 

	player.car.map.AddEventInMap(bomb_in_map1)
	player.car.map.AddEventInMap(bomb_in_map2)
	
	bomb_in_map2.scale = Vector2(-1, 1)
	
	bomb_in_map1.setup(player.car.map, spawn_pos.x, spawn_pos.y, 25, 25, angle1)
	bomb_in_map2.setup(player.car.map, spawn_pos.x, spawn_pos.y, 25, 25, angle2)


	player.car.sounds.playBearSSound()
	arm_tick = NetworkTime.tick + int(NetworkTime.tickrate * 0.1)
	
func run_tick(tick: int, is_fresh: bool) -> void:
	if done:
		return
	if not armed and tick >= arm_tick:
		armed = true
		if is_instance_valid(bomb_in_map1) and is_instance_valid(bomb_in_map2):
			bomb_in_map1.IsActivated = true
			bomb_in_map2.IsActivated = true
		done = true
		if is_fresh:
			player.prop.Delprop(self)

func del() -> void:
	pass
	
func run()->void:
	pass
	
func delme()->void:
	player.prop.Delprop(self);
	
