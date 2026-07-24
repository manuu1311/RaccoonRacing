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
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var synchronizer: RollbackSynchronizer = $RollbackSynchronizer
var petroadd:bool=true
var hit: bool = false
var hit_tick: int = -1
const HIT_LINGER_TICKS := 25
var _is_fresh: bool = false
var alive:bool=true
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.

func setup(mapinst:Map,_ishitcar:bool,_ishitwall:bool)->void:
    map=mapinst
    for i in range(1):
        collisions.append(get_node("Collisions/CollisionPoint"+str(i)))

func _rollback_tick(_delta: float, tick: int, is_fresh: bool) -> void:
    if hit and tick - hit_tick >= HIT_LINGER_TICKS+50:
        queue_free()
    if not alive:
        return
    _is_fresh = is_fresh
    if hit:
        if tick - hit_tick >= HIT_LINGER_TICKS:
            alive=false
        return

    if not petroadd:
        return

    Forward()
    UpdateCarPos()
    UpdateSpeed()
    if bsEx > 0:
        rotation_degrees += min(bsEx, 30)
        bsEx -= 1
    if _is_fresh:
        AddPetro() 

func Forward()->void:
    speed+=horse.rotated(rotation)


func reset(x:float,y:float,r:float)->void:
      global_position=Vector2(x,y)
      rotation=r

func Update()->void:
    if not petroadd:return
    UpdateCarPos();
    UpdateSpeed();
    if(bsEx > 0):
        rotation_degrees += min(bsEx,30);
        bsEx = bsEx - 1;


func GetHitStatus(tx:float,ty:float)->void:
    var wallAngledeg:float =GetHitStatusAng(tx,ty)
    #no wall detected
    if(is_nan(wallAngledeg)):
        return 
    _pop(null)

func _pop(who: Car) -> void:
    if hit:
        return
    hit = true
    hit_tick = int(NetworkTime.tick)
    speed = Vector2.ZERO
    horse = Vector2.ZERO
    petroadd = false
    if _is_fresh:
        bomb_effect.play()
        sprite_2d.hide()
        if who:
            who.sounds.playBedumpSound()

func OnHitStatus()->void:
    speed=Vector2(0,0)
    horse=Vector2(0,0)
    bomb_effect.play()
    sprite_2d.hide()
    petroadd=false
    
    
func AddPetro()->void:
    var boost: Node2D = petroeffect.instantiate() as Node2D
    
    boost.rotation=rotation
    boost.global_position=global_position
    boost.global_position += Vector2(0,randf_range(-5.0, 5.0)).rotated(boost.rotation)
    var base_scale := (randi() % 60 + 40) * 0.7 / 100.0*petrowidth
    boost.scale = Vector2.ONE * base_scale
    bottom_effect.add_child(boost)
    
    
func UpdateCarPos()->void:
    GetHitCar();
    @warning_ignore("integer_division")
    stepx = int(speed.x * 10) / 10;
    @warning_ignore("integer_division")
    stepy = int(speed.y * 10) / 10;
    tempx = position.x + stepx;
    tempy = position.y + stepy;
    GetHitStatus(tempx,tempy);
    position = Vector2(tempx,tempy)
    
    

func OnHitCar(who: Car,isfresh:bool=true) -> void:
    if hit or who.playerID == player.PlayerID:
        return
    if not who.isInvincible and not who.player.car.IsUseShield:
        who.bsex = 50
        if _is_fresh:
            who.sounds.playBsSound()
    if who.player.car.IsUseShield:
        who.player.RemoveShield(isfresh);
    _pop(who)

func _rollback_spawn() -> void:
    show()

func _rollback_despawn() -> void:
    hide()

func _rollback_destroy() -> void:
    queue_free()
