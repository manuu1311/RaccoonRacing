extends Prop
class_name MineProp


var bomb_in_map:EventInMap;
var tickactivate:int=int(0.3*NetworkTime.tickrate)

func _init(playerinst:Player)->void:
	super(playerinst);
	proptype = 4;
	bomb_in_map=preload("res://Assets/Scenes/Screens/maps/Props/BombInMap.tscn"
	).instantiate() as EventInMap
	var pos:Vector2=Vector2(0,20).rotated(player.car.rotation)+player.car.global_position
	player.car.map.AddEventInMap(bomb_in_map)
	bomb_in_map.setup(player.car.map,pos.x,pos.y,25,25,0)
	bomb_in_map.IsActivated = false;
	player.car.sounds.playmineSound();
	tickactivate+=NetworkTime.tick
	usebomb()
	
func usebomb()->void:
	if NetworkTime.tick!=tickactivate:
		return
	if is_instance_valid(bomb_in_map):
		bomb_in_map.IsActivated = true;
	delme();
	
func run()->void:
	pass
	
func delme()->void:
	player.prop.Delprop(self);
	
func del()->void:
	pass
