extends EventInMap

@onready var timer: Timer = $Timer
@onready var state_synchronizer: StateSynchronizer = $StateSynchronizer
@export var respawn_ticks: int = NetworkTime.tickrate*3
var hide_tick:int=0
##predict prop hidden after local collision
var predictingtick:int=0

func setup(mapinst:Map, xinst:float, yinst:float, widthinst:float, heightinst:float, angleinst:float,id:int=0)->void:
	super.setup(mapinst,xinst,yinst,widthinst,heightinst,angleinst,id)
	var scaled_size:Vector2 = $Sprite2D.texture.get_size() * $Sprite2D.global_scale
	width=scaled_size.x
	height=scaled_size.y
	scale=Vector2(0.7,0.7)
	global_position=Vector2(x,y)
	await ready
	state_synchronizer.add_state(self, "hide_tick")
	IsActivated=true

func GetHitEventStatus(PlayerId:int,_unsynced:bool)->void:
	if not IsActivated:
		return
	if is_multiplayer_authority():
		hide_tick=NetworkTime.tick+respawn_ticks
		NotifyPlayer.rpc(PlayerId,hide_tick)
	else:
		#hide it temporarily
		predictingtick=NetworkTime.tick+NetworkTime.seconds_to_ticks(1)
		GameData.PlayersArr[PlayerId].RunPropBox(global_position.x,global_position.y)

@rpc('call_local','reliable')
func NotifyPlayer(playerid:int,hidetick:int)->void:
	hide_tick=hidetick
	var player:Player=GameData.PlayersArr[playerid]
	player.ValidatePropBox(global_position.x,global_position.y)
	#delete client prediction
	predictingtick=0

func _process(_delta: float) -> void:
	var curtick:int=NetworkTime.tick
	if curtick<predictingtick:
		visible=false
		IsActivated=false
	else:
		visible=curtick>hide_tick
		IsActivated=curtick>hide_tick

func del()->void:
	queue_free()
