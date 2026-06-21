extends Prop
class_name FurballsProp

var FurballArr:Array[FurballsInMap];
var Furballs1:Resource;
var PId:int;


func _init(playerinst:Player)->void:
	Furballs1=preload("res://Assets/Scenes/Screens/maps/Props/FurballsInMap.tscn")
	var effect:Resource=preload("res://Assets/Scenes/Screens/PropEffects/bomb.tscn")
	super(playerinst)
	proptype = 9;
	FurballArr = []
	player.car.sounds.playCatSSound();
	var _loc4_:int = 0;
	var _loc5_:Vector2;
	while(_loc4_ < 6):
		_loc5_ =Vector2(0,25)
		_loc5_.rotated(deg_to_rad(_loc4_ * 360 / 6));
		var furballinst:FurballsInMap=Furballs1.instantiate() as FurballsInMap
		player.car.map.add_child(furballinst)
		furballinst.speed=player.car.speed
		furballinst.petrolength=10
		furballinst.petrowidth=0.5
		furballinst.player=player
		var pos:Vector2=player.car.global_position+_loc5_
		furballinst.reset(pos.x,pos.y,player.car.rotation+deg_to_rad(60*_loc4_))
		furballinst.pid=_loc4_
		delme()
		_loc4_+=1

func delme()->void:
	player.prop.Delprop(self)
	
	
func del()->void:
	queue_free()
