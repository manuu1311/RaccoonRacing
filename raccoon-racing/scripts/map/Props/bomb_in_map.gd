extends EventInMap
class_name BombInMap

var jumphigh:int = 3;
var bsValume:int = 60;
var bombview:AnimatedSprite2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var synchronizer: RollbackSynchronizer = $RollbackSynchronizer
const EXPLODE_TICKS := 35
var alive:bool=true
var exploded: bool = false
var explode_tick: int = -1

# Called when the node enters the scene tree for the first time.
func setup(mapinst:Map, xinst:float, yinst:float, widthinst:float, heightinst:float, angleinst:float,id:int=0)->void:
	super(mapinst,xinst,yinst,widthinst,heightinst,angleinst,id);
	bombview=preload("res://Assets/Scenes/Screens/maps/Props/BombView.tscn").instantiate() as AnimatedSprite2D
	global_position=Vector2(x,y)
	map.SpawnProp("Mine",id,self)
	map.minimap.add_child(bombview)
	bombview.position=map.offset+global_position*map.ScaledTimes
	animated_sprite_2d.hide()


func GetHitEventStatus(PlayerId: int,is_fresh:bool) -> void:
	if not IsActivated or exploded:
		return
	var car: Car = GameData.PlayersArr[PlayerId].car
	if car.isInvincible:
		return
	exploded = true
	explode_tick = NetworkTime.tick
	IsActivated = false
	if car.jumpCurrheight < jumphigh - 1:
		if not car.IsUseShield:
			car.bsex = bsValume
			car.Jump(jumphigh)
			car.speed *= 0.3
			car.speed += (car.global_position - global_position) * 0.03
		else:
			if is_fresh:
				car.player.prop.del_prop_by_type(3)
		if is_fresh:
			car.sounds.playerBombSound()
			animated_sprite_2d.show()
			animated_sprite_2d.play()
			sprite_2d.hide()
			bombview.hide()


func _rollback_tick(_delta: float, tick: int, is_fresh: bool) -> void:
	if not exploded:
		return
	if tick - explode_tick >= EXPLODE_TICKS+70:
			_rollback_destroy()
	if not alive:
		return
	if tick == explode_tick and is_fresh:
		# one-shot cosmetics, only on the first time we ever see this tick
		pass
	if tick - explode_tick >= EXPLODE_TICKS:
		alive=false

func _rollback_spawn() -> void:
	IsActivated=true

func _rollback_despawn() -> void:
	IsActivated=false

func _rollback_destroy() -> void:
	map.DelEventInMap(edface.getId())

func del()->void:
	if is_instance_valid(bombview):
		bombview.queue_free()
	queue_free()
