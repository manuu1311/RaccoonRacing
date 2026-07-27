extends EventInMap
class_name BombInMap

var jumphigh:int = 3;
var bsValume:int = 60;
var bombview:AnimatedSprite2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var sprite_2d: Sprite2D = $Sprite2D

# Called when the node enters the scene tree for the first time.
func setup(mapinst:Map, xinst:float, yinst:float, widthinst:float, heightinst:float, angleinst:float,id:int=0)->void:
	super(mapinst,xinst,yinst,widthinst,heightinst,angleinst,id);
	bombview=preload("res://Assets/Scenes/Screens/maps/Props/BombView.tscn").instantiate() as AnimatedSprite2D
	global_position=Vector2(x,y)
	map.SpawnProp("Mine",id,self)
	map.minimap.add_child(bombview)
	bombview.position=map.offset+global_position*map.ScaledTimes
	animated_sprite_2d.hide()


func GetHitEventStatus(PlayerId: int) -> void:
	if not is_multiplayer_authority():
		return
	if not IsActivated:
		return
	var car: Car = GameData.PlayersArr[PlayerId].car
	if car.isInvincible:
		return
	MineExplode.rpc(car)

@rpc('call_local','reliable')
func MineExplode(car:Car)->void:
	IsActivated = false
	if car.jumpCurrheight < jumphigh - 1:
		if not car.IsUseShield:
			car.bsex = bsValume
			car.Jump(jumphigh)
			car.speed *= 0.3
			car.speed += (car.global_position - global_position) * 0.03
		else:
			car.player.RemoveShield();
		car.sounds.playerBombSound()
		animated_sprite_2d.show()
		animated_sprite_2d.play()
		sprite_2d.hide()
		bombview.hide()
	destroy()

func destroy() -> void:
	map.DelEventInMap(edface.getId())

func del()->void:
	if is_instance_valid(bombview):
		bombview.queue_free()
	queue_free()
