extends Node
class_name PropEffector

@export var car:Car
const effect:Resource=preload("res://Assets/Scenes/Screens/PropEffects/Petro.tscn")
var IsHovercraft:bool
@onready var invincible: AnimatedSprite2D = $"../Visual/TopEffect/Invincible"
@onready var shield: AnimatedSprite2D = $"../Visual/TopEffect/Shield"
@onready var bomb: AnimatedSprite2D = $"../Visual/TopEffect/Bomb"
@onready var get_sleep: AnimatedSprite2D = $"../Visual/TopEffect/GetSleep"
@onready var car_sleep: AnimatedSprite2D = $"../Visual/TopEffect/CarSleep"
@onready var give_sleep: AnimatedSprite2D = $"../Visual/TopEffect/GiveSleep"

func _ready() -> void:
	IsHovercraft=car.isHovercraft()
	invincible.hide()
	bomb.hide()
	
##boost
func AddPetro()->void:
	var boost: Node2D = effect.instantiate() as Node2D
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


#TODO: hud animation
func PlaySleep()->void:
	get_sleep.play()
	car_sleep.play()
	car.sounds.playBeSleepSound()

func StopSleep()->void:
	get_sleep.stop()
	car_sleep.stop()
	car.sounds.StopBeSleepSound()
	
func SleepShotArt(_id:int)->void:
	give_sleep.play()
	car.sounds.playuseSleepSound();
