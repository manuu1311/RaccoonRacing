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

func setup(mapinst:Map, xinst:float, yinst:float, widthinst:float, heightinst:float, angleinst:float)->void:
	self.x = xinst;
	self.y = yinst;
	self.width = widthinst;
	self.height = heightinst;
	self.map = mapinst;
	self.angle = angleinst;
	self.edface = map.edevent.AddRectangle(x,y,width,height,angle);
	
func GetHitEventStatus(_PlayerId:int):
	pass

func del():
	queue_free()
