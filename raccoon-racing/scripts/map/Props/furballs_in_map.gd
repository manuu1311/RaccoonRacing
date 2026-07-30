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
var petroadd:bool=true
var exploded:bool=false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func setup(mapinst:Map,_ishitcar:bool,_ishitwall:bool)->void:
	map=mapinst
	for i in range(1):
		collisions.append(get_node("Collisions/CollisionPoint"+str(i)))

func _process(_delta: float) -> void:
	Forward()
	Update()
	AddPetro() 

func Forward()->void:
	speed+=horse.rotated(rotation)


func reset(x:float,y:float,r:float)->void:
	global_position=Vector2(x,y)
	rotation=r
	Update()

func Update()->void:
	if not petroadd:
		return
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
	OnHitStatus()


func OnHitStatus()->void:
	speed=Vector2(0,0)
	horse=Vector2(0,0)
	bomb_effect.play()
	sprite_2d.hide()
	petroadd=false
	await bomb_effect.animation_finished
	del()
	

func del()->void:
	await bomb_effect.animation_finished
	queue_free()
	
	
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
	
	

func OnHitCar(Who:Car)->void:
	if Who.playerID==player.PlayerID:
		return
	PlayEffect(Who)
	if is_multiplayer_authority():
		if(!Who.isInvincible && !Who.IsUseShield):
			ApplyCarEffect.rpc(Who.playerID)
			#car.Speed.plus(new as.Vector(_loc6_,_loc5_).scaleNew(0.1));
		if(Who.IsUseShield):
			RemoveShield.rpc(Who.playerID)
	del()

@rpc('call_local','reliable')
func ApplyCarEffect(Whoid:int)->void:
	var Who:Car=GameData.PlayersArr[Whoid].car
	Who.bsex = 50;
	Who.sounds.playBsSound()
	if not exploded:
		PlayEffect(Who)
	del()
	
@rpc('call_local','reliable')
func RemoveShield(Whoid:Car)->void:
	var Who:Car=GameData.PlayersArr[Whoid].car
	Who.player.RemoveShield();
	if not exploded:
		PlayEffect(Who)
	del()

func PlayEffect(Who:Car)->void:
	exploded=true
	speed=Vector2(0,0)
	horse=Vector2(0,0)
	bomb_effect.play()
	sprite_2d.hide()
	petroadd=false
	Who.sounds.playBedumpSound();
