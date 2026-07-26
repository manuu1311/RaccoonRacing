extends EventInMap

func setup(mapinst:Map, xinst:float, yinst:float, widthinst:float, heightinst:float, angleinst:float,id:int=0)->void:
	super.setup(mapinst,xinst,yinst,widthinst,heightinst,angleinst,id)
	global_position=Vector2(x,y)
	rotation_degrees=angle
	
	
func GetHitEventStatus(PlayerId:int)->void:
	GameData.PlayersArr[PlayerId].car.JumpBySpeed(0.5)
