extends CarController
class_name HumanCarController

# Called every frame. 'delta' is the elapsed time since the previous frame.
func handle_input()->void:
	right=false
	left=false
	forward=false
	brake=false
	special=false
	if not player.car.isSleep and not (player.car.jumpCurrheight>=1) and player.car.playering:
		# Handle Steering (X-axis)
		if Input.is_action_pressed('Steer right'):
			right=true
		elif Input.is_action_pressed('Steer left'):
			left=true
		else:
			cancelturn=true

		# Handle Throttle/Brake (Y-axis)
		if Input.is_action_pressed('Accelerate'):
			forward=true
		elif Input.is_action_pressed('Brake'):
			brake=true
		#else:
			#player.car.Clearward()
		if Input.is_action_just_pressed("Special"):
			special=true
			#player.UseProp()
