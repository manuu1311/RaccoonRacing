extends EventInMap
class_name HoneyBombInMap

var jumphigh:int = 2;
var bsValume:int = 40;
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var sprite_2d: AnimatedSprite2D = $Sprite2D
@onready var marker_2d: Marker2D = $Marker2D
@onready var synchronizer: RollbackSynchronizer = $RollbackSynchronizer
const EXPLODE_TICKS := 20
var exploded: bool = false
var explode_tick: int = -1
var _is_fresh: bool = false

func setup(mapinst:Map, xinst:float, yinst:float, widthinst:float, heightinst:float, angleinst:float)->void:
	mapinst.add_child(self)
	global_position=Vector2(xinst,yinst)
	rotation=angleinst
	super(mapinst,marker_2d.global_position.x,marker_2d.global_position.y,widthinst,heightinst,angleinst);
	animated_sprite_2d.hide()

func GetHitEventStatus(PlayerId:int,is_fresh: bool)->void:
	if not IsActivated or exploded:
		return
	var car: Car = GameData.PlayersArr[PlayerId].car
	if car.isInvincible:
		return
	exploded = true
	explode_tick = int(NetworkTime.tick)
	IsActivated = false
	if car.jumpCurrheight < jumphigh - 1:
		car.bsex = bsValume
		car.Jump(jumphigh)
		car.speed *= 0.3
		car.speed += (car.global_position - global_position) * 0.03
	if is_fresh:
		car.sounds.playerBombSound()

func _rollback_tick(_delta: float, tick: int, is_fresh: bool) -> void:
	_is_fresh = is_fresh
	if not exploded:
		return
	if tick == explode_tick and is_fresh:
		sprite_2d.hide()
		animated_sprite_2d.show()
		animated_sprite_2d.play()
	if tick - explode_tick >= EXPLODE_TICKS:
		synchronizer.despawn()

func _rollback_spawn() -> void:
	show()

func _rollback_despawn() -> void:
	hide()
	animated_sprite_2d.stop()

func _rollback_destroy() -> void:
	queue_free()

func del() -> void:
	pass
