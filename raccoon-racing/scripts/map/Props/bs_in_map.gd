extends EventInMap

func setup(mapinst:Map, xinst:float, yinst:float, widthinst:float, heightinst:float, angleinst:float)->void:
	super.setup(mapinst,xinst,yinst,widthinst,heightinst,angleinst)
	map.add_child(self)
	global_position=Vector2(x,y)
	rotation=angle
	IsActivated=true
	
	
func GetHitEventStatus(PlayerId:int):
	if(IsActivated):
		var car:Car=GameData.PlayersArr[PlayerId].car
		if(not car.isInvincible):
			car.bsf = car.speed.angle() > rotation;
			car.bs = true;
			car.sounds.playBsSound()
