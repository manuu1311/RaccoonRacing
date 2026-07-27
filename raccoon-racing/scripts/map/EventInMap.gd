extends Node2D
class_name EventInMap

## angle in degrees
var angle:float;
var height:float;
var map:Map;
var width:float;
var x:float;
var y:float;
var edface:EdRectangle
var IsActivated:bool
var PlayerID:int
var lifetime:int

func setup(mapinst:Map, xinst:float, yinst:float, widthinst:float, heightinst:float, angleinst:float,id:int=0)->void:
	self.x = xinst;
	self.y = yinst;
	self.width = widthinst;
	self.height = heightinst;
	self.map = mapinst;
	self.angle = angleinst;
	self.edface = map.edevent.AddRectangle(x,y,width,height,angle);
	PlayerID=id
	
func GetHitEventStatus(_PlayerId:int,_unsynced:bool)->void:
	pass

func del()->void:
	queue_free()
