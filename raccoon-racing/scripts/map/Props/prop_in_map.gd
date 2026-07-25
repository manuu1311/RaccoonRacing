extends EventInMap

@onready var timer: Timer = $Timer
@onready var synchronizer: RollbackSynchronizer = $RollbackSynchronizer

@export var respawn_ticks: int = NetworkTime.tickrate*3
@onready var rollback_synchronizer: RollbackSynchronizer = $RollbackSynchronizer

var box_visible: bool = true
var hide_tick: int = -1

func setup(mapinst:Map, xinst:float, yinst:float, widthinst:float, heightinst:float, angleinst:float,id:int=0)->void:
	super.setup(mapinst,xinst,yinst,widthinst,heightinst,angleinst,id)
	var scaled_size:Vector2 = $Sprite2D.texture.get_size() * $Sprite2D.global_scale
	width=scaled_size.x
	height=scaled_size.y
	scale=Vector2(0.7,0.7)
	global_position=Vector2(x,y)
	await ready
	rollback_synchronizer.add_state(self, "box_visible")
	rollback_synchronizer.add_state(self, "hide_tick")

func GetHitEventStatus(PlayerId:int,_isfresh:bool,currtick:int)->void:
	if not box_visible:
		return
	var player:Player=GameData.PlayersArr[PlayerId]
	box_visible=false
	hide_tick = currtick
	player.RunPropBox(global_position.x,global_position.y,currtick)
		
func _rollback_tick(_delta: float, tick: int, _is_fresh: bool) -> void:
	if not box_visible and tick - hide_tick >= respawn_ticks:
		box_visible = true

func _process(_delta: float) -> void:
	visible = box_visible
	
func del()->void:
	queue_free()
