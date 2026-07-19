extends EventInMap
class_name BsInMap

@onready var synchronizer: RollbackSynchronizer = $RollbackSynchronizer
var LIFETIME_TICKS :int= NetworkTime.tickrate*30*99999999
var spawn_tick: int = -1
var alive:bool=true

func setup(mapinst:Map, xinst:float, yinst:float, widthinst:float, heightinst:float, angleinst:float)->void:
	super.setup(mapinst,xinst,yinst,widthinst,heightinst,angleinst)
	map.add_child(self)
	global_position=Vector2(x,y)
	rotation=angle
	IsActivated=true
	spawn_tick = NetworkTime.tick
	
	
func GetHitEventStatus(PlayerId:int,is_fresh:bool)->void:
	if(IsActivated):
		var car:Car=GameData.PlayersArr[PlayerId].car
		if(not car.isInvincible):
			car.bsf = car.speed.angle() > rotation;
			car.bs = true;
			if is_fresh:
				car.sounds.playBsSound()


func _rollback_tick(_delta: float, tick: int, _is_fresh: bool) -> void:
	if not alive and tick - spawn_tick >= LIFETIME_TICKS+50:
			queue_free()
	if IsActivated and tick - spawn_tick >= LIFETIME_TICKS:
		IsActivated = false
		alive=false

func _rollback_spawn() -> void:
	show()

func _rollback_despawn() -> void:
	hide()

func _rollback_destroy() -> void:
	queue_free()
