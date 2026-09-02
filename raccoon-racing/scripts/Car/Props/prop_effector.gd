extends Node
class_name PropEffector

@export var car:Car
const effect:PackedScene=preload("res://Assets/Scenes/Screens/PropEffects/Petro.tscn")
var IsHovercraft:bool
@onready var invincible: AnimatedSprite2D = $"../Visual/TopEffect/Invincible"
@onready var shield: AnimatedSprite2D = $"../Visual/TopEffect/Shield"
@onready var bomb: AnimatedSprite2D = $"../Visual/TopEffect/Bomb"
@onready var get_sleep: AnimatedSprite2D = $"../Visual/TopEffect/GetSleep"
@onready var car_sleep: AnimatedSprite2D = $"../Visual/TopEffect/CarSleep"
@onready var give_sleep: AnimatedSprite2D = $"../Visual/TopEffect/GiveSleep"
@onready var bone: Sprite2D = $"../Visual/BottomEffect/Circler/Bone"
## bone wrapper: useful for rl agents
@onready var bone_wrapper: Node2D = $"../Visual/BottomEffect/Circler"
@onready var rotator: AnimationPlayer = $"../Visual/BottomEffect/Circler/Bone/Rotator"
@onready var mover: AnimationPlayer = $"../Visual/BottomEffect/Circler/Bone/Mover"
@onready var area_2d: Area2D = $"../Visual/BottomEffect/Circler/Area2D"
signal bonehit

func _ready() -> void:
	IsHovercraft=car.isHovercraft()
	invincible.hide()
	bomb.hide()
	bone.hide()
	rotator.stop()
	mover.stop()

##boost
func AddPetro()->void:
	var boost: PetroEffect = effect.instantiate() as Node2D
	boost.is_hovercraft = IsHovercraft  
	
	boost.rotation=car.rotation
	boost.global_position=car.global_position
	boost.global_position += Vector2(0,randf_range(-5.0, 5.0)).rotated(boost.rotation)
	var base_scale := (randi() % 60 + 40) * 0.7 / 100.0
	boost.scale = Vector2.ONE * base_scale
	car.bottom_effect.add_child(boost)
	boost.top_level = true
	
func StopPetro()->void:
	pass
	
	
func AddInvincible(newhorse:float)->void:
	car.horse*=newhorse
	car.isInvincible=true
	invincible.show()
	invincible.play()
	
func StopInvincible()->void:
	car.horse=car.carhorse
	car.isInvincible=false
	invincible.hide()
	invincible.stop()
	
 
func AddShield()->void:
	shield.play("default")
	car.sounds.playShieldSound()
	
func RemoveShield()->void:
	shield.play("fade")   

func PlayBomb(pos:Vector2)->void:
	bomb.show()
	bomb.global_position=pos
	bomb.play()


func PlaySleep()->void:
	get_sleep.play()
	car_sleep.play()
	car.sounds.playBeSleepSound()

func PlaySleepHudAnimation(id:int)->void:
	if car.player.hud!=null:
		car.player.hud.SleepEffect(id)

func StopSleep()->void:
	get_sleep.stop()
	car_sleep.stop()
	car.sounds.StopBeSleepSound()

func StopSleepHudAnimation()->void:
	if (car.player.hud!=null):
		car.player.hud.StopSleep()
	
func SleepShotArt(_id:int)->void:
	give_sleep.play()
	car.sounds.playuseSleepSound();

func PlayBone()->void:
	bone.scale=Vector2.ONE
	bone.show()
	rotator.play("Bone")
	mover.play("BoneMove")
	car.sounds.playdogSSound()
	if not GameData.IsMultiplayer or NetworkManager.is_host:
		area_2d.area_entered.connect(OnAreaEntered)
	

func StopBone()->void:
	bone.hide()
	rotator.stop()
	mover.stop()
	if area_2d.area_entered.has_connections():
		area_2d.area_entered.disconnect(OnAreaEntered)
	


func OnAreaEntered(body:Area2D)->void:
	if body.is_in_group("Body"):
		var caropp:Car=body.get_parent().get_parent() as Car
		if caropp.playerID!=car.playerID:
			if caropp.jumpCurrheight<caropp.heightOverWall:
				if !caropp.isResetting:
					_on_bone_hit(caropp)
	
#bone hit logic
func _on_bone_hit(caropp:Car) -> void:
	if NetworkManager.is_host:
		if caropp.isInvincible:
			BoneInvincible.rpc(caropp.playerID)
		else:
			if caropp.player.car.IsUseShield:
				BoneShield.rpc(caropp.playerID)
			else:
				BoneEffect.rpc(caropp.playerID)

@rpc('call_local','reliable')
func BoneEffect(caroppid:int)->void:
	var caropp:Car=GameData.PlayersArr[caroppid].car
	var dist:Vector2 =caropp.global_position-(car.global_position)
	var loc7:float=0.005
	var distsq:float=dist.length_squared()
	if distsq<2000:
		loc7 = 0.005 + 0.05 * (2000 - distsq) / 2000;
	var knockback:Vector2=dist*loc7
	caropp.speed+=knockback*40
	caropp.bs=true
	bonehit.emit(caropp)

@rpc('call_local','reliable')
func BoneShield(caroppid:int)->void:
	var caropp:Car=GameData.PlayersArr[caroppid].car
	caropp.player.RemoveShield()
	bonehit.emit(caropp)

@rpc('call_local','reliable')
func BoneInvincible(caroppid:int)->void:
	var caropp:Car=GameData.PlayersArr[caroppid].car
	bonehit.emit(caropp)
