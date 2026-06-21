extends MoveObject
class_name FurballsInMap


var petrolength:int
var petrowidth:float
var pid:int
var player:Player
var horse:Vector2=Vector2(1,0)
const petroeffect:Resource=preload("res://Assets/Scenes/Screens/PropEffects/Petro.tscn")
@onready var bomb_effect: AnimatedSprite2D = $BombEffect
@onready var bottom_effect: Node2D = $BottomEffect
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    Update()
    AddPetro()
    Forward()

func Forward()->void:
    speed+=horse.rotated(rotation)


func reset(x:float,y:float,r:float)->void:
      global_position=Vector2(x,y)
      rotation=r
      Update()

func Update()->void:
    UpdateCarPos();
    UpdateSpeed();
    if(bsEx > 0):
        rotation_degrees += min(bsEx,30);
        bsEx = bsEx - 1;


func onHitStatus()->void:
    bomb_effect.play()
    await bomb_effect.animation_finished
    queue_free()
    
    
func AddPetro()->void:
    var boost: Node2D = petroeffect.instantiate() as Node2D
    
    boost.rotation=rotation-PI/2
    boost.global_position=global_position
    boost.global_position += Vector2(0,randf_range(-5.0, 5.0)).rotated(boost.rotation)
    var base_scale := (randi() % 60 + 40) * 0.7 / 100.0*petrowidth
    boost.scale = Vector2.ONE * base_scale
    bottom_effect.add_child(boost)
    
    
func OnHitCar(Who:Car)->void:
    if Who.playerID==player.PlayerID:
        return
    if(!Who.isInvincible && !Who.player.prop.IsUseShield):
        Who.bsex = 50;
        Who.sounds.playBsSound();
        #car.Speed.plus(new as.Vector(_loc6_,_loc5_).scaleNew(0.1));
    if(Who.player.prop.IsUseShield):
        Who.player.prop.Delpropbytype(3);
    bomb_effect.play()
    Who.sounds.playBedumpSound();
    await bomb_effect.animation_finished
    queue_free()
