extends EventInMap
class_name BsInMap

var lifetimeticks:int=0

func setup(mapinst:Map, xinst:float, yinst:float, widthinst:float, heightinst:float, angleinst:float,id:int=0)->void:
	super.setup(mapinst,xinst,yinst,widthinst,heightinst,angleinst)
	map.SpawnProp("Bs",id,self)
	global_position=Vector2(x,y)
	rotation=angle
	IsActivated=true
	lifetimeticks=NetworkTime.seconds_to_ticks(lifetime)
	delme()
	
	
func GetHitEventStatus(PlayerId:int)->void:
	if(IsActivated):
		var car:Car=GameData.PlayersArr[PlayerId].car
		if(not car.isInvincible):
			car.bsf = car.speed.angle() > rotation;
			car.bs = true;
			car.sounds.playBsSound()

func delme()->void:
	if lifetime>0:
		var i:int=0
		while i<lifetimeticks:
			await NetworkTime.after_tick
			i+=1
		map.DelEventInMap(edface.getId())

func del() -> void:
	queue_free()
