extends Node2D
class_name PetroEffect

@export var is_hovercraft: bool = false

@onready var ball: AnimatedSprite2D = $Ball
@onready var car_boost: AnimatedSprite2D = $CarBoost
@onready var hc_boost: AnimatedSprite2D = $HCBoost


func _ready() -> void:
    top_level = true

    if is_hovercraft:
        ball.hide()
        car_boost.hide()
        hc_boost.show()
        hc_boost.play()
        hc_boost.animation_finished.connect(queue_free)
    else:
        hc_boost.hide()
        ball.show()
        car_boost.show()
        ball.play()
        car_boost.play()
        ball.animation_finished.connect(queue_free)
        
        
