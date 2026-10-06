extends CarController
class_name RLCarController

var rl_player:RLPlayer
var agent:CarAgent

func _init(playerinst:Player,agent_inst:CarAgent) -> void:
	rl_player=playerinst as RLPlayer
	agent=agent_inst
	super(playerinst)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func handle_input()->void:
	if not player.car.isSleep and not player.car.isLock and not (player.car.jumpCurrheight>=1) and player.IsPlayering():
		var inputArr:Array[bool]=agent.get_action()
		forward=inputArr[0]
		brake=inputArr[1]
		left=inputArr[2]
		right=inputArr[3]
		special=inputArr[4]
		cancelturn=not left and not right
	else:
		forward=false
		brake=false
		left=false
		right=false
		cancelturn=false
