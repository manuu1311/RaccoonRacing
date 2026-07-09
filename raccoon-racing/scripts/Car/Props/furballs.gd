extends Prop
class_name FurballsProp

var FurballArr:Array[FurballsInMap];
var Furballs1:Resource;
var PId:int;


func _init(playerinst:Player)->void:
    Furballs1=preload("res://Assets/Scenes/Screens/maps/Props/FurballsInMap.tscn")
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
        furballinst.setup(player.car.map,0,0)
        furballinst.speed=player.car.speed
        furballinst.petrolength=10
        furballinst.petrowidth=0.5
        furballinst.player=player
        var pos:Vector2=player.car.global_position+_loc5_
        furballinst.reset(pos.x,pos.y,player.car.rotation+deg_to_rad(60*_loc4_))
        furballinst.pid=_loc4_
        _loc4_+=1
    delme()

func delme()->void:
    await player.car.get_tree().create_timer(30).timeout
    if is_instance_valid(player.car):
        player.prop.Delprop(self)
    
    
func del()->void:
    for furball in FurballArr:
        if is_instance_valid(furball):
            furball.queue_free()
    FurballArr.clear()
