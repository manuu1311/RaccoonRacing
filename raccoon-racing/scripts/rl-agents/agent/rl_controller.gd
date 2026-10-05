extends CarController
class_name RLCarController

var rl_player:RLPlayer
var agent:CarAgent

func _init(playerinst:Player) -> void:
	rl_player=playerinst as RLPlayer
	super(playerinst)
	agent=player.car.get_parent() as CarAgent

# Called every frame. 'delta' is the elapsed time since the previous frame.
func handle_input()->void:
	if not player.car.isSleep and not player.car.isLock and not (player.car.jumpCurrheight>=1) and player.IsPlayering():
		var inputArr:Array[bool]=agent.AutoInput()
		forward=inputArr[0]
		brake=inputArr[1]
		left=inputArr[2]
		right=inputArr[3]
		cancelturn=inputArr[4]
		if GameData.AICanUseProp:
			special=rl_player.AutoUseProp()
		else:
			special=false
	else:
		forward=false
		brake=false
		left=false
		right=false
		cancelturn=false
