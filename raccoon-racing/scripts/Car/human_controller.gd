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
		var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		# Handle Steering (X-axis)
		if input_dir.x > 0:
			right=true
		elif input_dir.x < 0:
			left=true
		#else:
			#player.car.CancelTurn()

		# Handle Throttle/Brake (Y-axis)
		if input_dir.y < 0:
			forward=true
		elif input_dir.y > 0:
			brake=true
		#else:
			#player.car.Clearward()
		if Input.is_action_just_pressed("Special"):
			special_buffered=true
			#player.UseProp()
