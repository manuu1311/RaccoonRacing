extends EventInMap


var Horse:Vector2
var TimePropReShow:int = 3000

func setup(mapinst:Map, xinst:float, yinst:float, widthinst:float, heightinst:float, angleinst:float)->void:
    super.setup(mapinst,xinst,yinst,widthinst,heightinst,angleinst)
    Horse=Vector2(1,0)
    global_position=Vector2(x,y)
    rotation=angle
    
    
func GetHitEventStatus(PlayerId:int):
    var player:Player=Game.players[PlayerId]
    player.car.Speed+=Horse.rotated(deg_to_rad(angle-90))
    player.car.sounds.playFastSound()
    player.car.sounds.playAddSpeedSound()
