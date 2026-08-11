extends TextureRect
class_name IconController

@onready var get_sleep: AnimatedSprite2D = $GetSleep
@onready var car_sleep: AnimatedSprite2D = $CarSleep
var playerid:int


func setup(id:int)->void:
	playerid=id
	var icon:Sprite2D=($IconHighlight as Sprite2D)
	if Game.IsSplitScreen:
		if GameData.PlayersArr[playerid].current_control==Player.control_type.HUMAN:
			if playerid==0:
				icon.self_modulate=Color.ORANGE_RED
			elif playerid==1:
				icon.self_modulate=Color.CYAN
			elif playerid==2:
				icon.self_modulate=Color.YELLOW
			elif playerid==3:
				icon.self_modulate=Color.LAWN_GREEN
		else:
			icon.visible=false
	else:
		if playerid==0:
			icon.self_modulate=Color.RED
		else:
			icon.visible=false
	
func PlaySleep()->void:
	get_sleep.play()
	car_sleep.play()

func StopSleep()->void:
	get_sleep.stop()
	car_sleep.stop()
