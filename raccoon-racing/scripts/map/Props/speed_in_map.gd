extends EventInMap


var Horse:Vector2
var TimePropReShow:int = 3000

func setup(mapinst:Map, xinst:float, yinst:float, widthinst:float, heightinst:float, angleinst:float)->void:
	super.setup(mapinst,xinst,yinst,widthinst,heightinst,angleinst)
	Horse=Vector2(1,0)
	global_position=Vector2(x,y)
	rotation_degrees=angle
	
	
func GetHitEventStatus(PlayerId:int)->void:
	var car:Car=GameData.PlayersArr[PlayerId].car
	car.speed+=Horse.rotated(deg_to_rad(angle-90))
	car.sounds.playFastSound()
	car.sounds.playAddSpeedSound()
