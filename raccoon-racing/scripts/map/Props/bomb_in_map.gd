extends EventInMap

var jumphigh:int = 3;
var bsValume:int = 60;
var bombview:AnimatedSprite2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var sprite_2d: Sprite2D = $Sprite2D

# Called when the node enters the scene tree for the first time.
func setup(mapinst:Map, xinst:float, yinst:float, widthinst:float, heightinst:float, angleinst:float)->void:
	super(mapinst,xinst,yinst,widthinst,heightinst,angleinst);
	bombview=preload("res://Assets/Scenes/Screens/maps/Props/BombView.tscn").instantiate() as AnimatedSprite2D
	global_position=Vector2(x,y)
	map.add_child(self)
	map.minimap.add_child(bombview)
	bombview.position=map.offset+global_position*map.ScaledTimes
	IsActivated = true;
	animated_sprite_2d.hide()


func GetHitEventStatus(PlayerId:int)->void:
	var car:Car=GameData.PlayersArr[PlayerId].car
	if(IsActivated):
		if(not car.isInvincible):
			IsActivated=false
			sprite_2d.hide()
			bombview.hide()
			if(car.jumpCurrheight < jumphigh - 1):
				if(!car.isUseShield):
					car.bsex=bsValume
					car.Jump(jumphigh)
					car.speed*=0.3
					car.speed+=(car.global_position-global_position)*0.03
				else:
					car.DelPropByType(3)
			car.sounds.playerBombSound()
			animated_sprite_2d.show()
			animated_sprite_2d.play()
			await animated_sprite_2d.animation_finished
			map.DelEventInMap(edface.getId())


func del()->void:
	bombview.queue_free()
	queue_free()
