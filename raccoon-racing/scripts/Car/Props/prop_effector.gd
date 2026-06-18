extends Node
class_name PropEffector

@export var car:Car
const effect:Resource=preload("res://Assets/Scenes/Screens/PropEffects/Petro.tscn")
var IsHovercraft:bool
@onready var invincible: AnimatedSprite2D = $"../Visual/TopEffect/Invincible"

func _ready() -> void:
    IsHovercraft=car.isHovercraft()
    invincible.hide()
    
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
    
    
