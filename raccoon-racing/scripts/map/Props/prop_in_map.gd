extends EventInMap

@onready var timer: Timer = $Timer

func setup(mapinst:Map, xinst:float, yinst:float, widthinst:float, heightinst:float, angleinst:float)->void:
	super.setup(mapinst,xinst,yinst,widthinst,heightinst,angleinst)
	var scaled_size:Vector2 = $Sprite2D.texture.get_size() * $Sprite2D.global_scale
	width=scaled_size.x
	height=scaled_size.y
	scale=Vector2(0.7,0.7)
	global_position=Vector2(x,y)

func GetHitEventStatus(PlayerId:int):
	if(visible):
		var player:Player=GameData.PlayersArr[PlayerId]
		player.RunPropBox(global_position.x,global_position.y)
		hide()
		timer.start()
		await timer.timeout
		ReShowProp()
		

func ReShowProp()->void:
	show();
	
#TODO: is this necessary?
func del():
	queue_free()
