extends TextureRect
class_name IconController

@onready var get_sleep: AnimatedSprite2D = $GetSleep
@onready var car_sleep: AnimatedSprite2D = $CarSleep
var playerid:int


func setup(id:int)->void:
	playerid=id
	
func PlaySleep()->void:
	get_sleep.play()
	car_sleep.play()

func StopSleep()->void:
	get_sleep.stop()
	car_sleep.stop()
