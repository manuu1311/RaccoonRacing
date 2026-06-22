extends EventInMap

var jumphigh:int = 2;
var bsValume:int = 40;
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var sprite_2d: AnimatedSprite2D = $Sprite2D
@onready var marker_2d: Marker2D = $Marker2D

func setup(mapinst:Map, xinst:float, yinst:float, widthinst:float, heightinst:float, angleinst:float)->void:
	mapinst.add_child(self)
	global_position=Vector2(xinst,yinst)
	rotation=angleinst
	super(mapinst,marker_2d.global_position.x,marker_2d.global_position.y,widthinst,heightinst,angleinst);
	animated_sprite_2d.hide()

func GetHitEventStatus(PlayerId:int)->void:
	var car:Car=GameData.PlayersArr[PlayerId].car
	if(IsActivated):
		if(not car.isInvincible):
			IsActivated=false
			sprite_2d.hide()
			if(car.jumpCurrheight < jumphigh - 1):
				car.bsex=bsValume
				car.Jump(jumphigh)
				car.speed*=0.3
				car.speed+=(car.global_position-global_position)*0.03

			car.sounds.playerBombSound()
			animated_sprite_2d.show()
			animated_sprite_2d.play()
			await animated_sprite_2d.animation_finished
			map.DelEventInMap(edface.getId())

func del()->void:
	queue_free()
