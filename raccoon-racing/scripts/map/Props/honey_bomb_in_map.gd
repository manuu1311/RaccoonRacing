extends EventInMap

var IsActivated:bool = true;
var jumphigh:int = 2;
var bsValume:int = 40;
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var sprite_2d: AnimatedSprite2D = $Sprite2D

func setup(mapinst:Map, xinst:float, yinst:float, widthinst:float, heightinst:float, angleinst:float)->void:
    super(mapinst,xinst,yinst,widthinst,heightinst,angleinst);
    #TODO:add bombview in map, scale xy by map.scaledtimes
    global_position=Vector2(x,y)
    IsActivated = true;
    animated_sprite_2d.hide()

func GetHitEventStatus(PlayerId:int):
    var _loc2_;
    var _loc6_;
    var _loc5_;
    var _loc4_;
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
