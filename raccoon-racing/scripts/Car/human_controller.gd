extends CarController
class_name HumanCarController

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if not player.car.isSleep and not player.car.jumpCurrheight>=1:
		var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

		# Handle Steering (X-axis)
		if input_dir.x > 0:
			player.car.TurnLRight()
		elif input_dir.x < 0:
			player.car.TurnLeft()
		else:
			player.car.CancelTurn()

		# Handle Throttle/Brake (Y-axis)
		if input_dir.y < 0:
			player.car.Forward()  # In Godot 2D, negative Y is UP
		elif input_dir.y > 0:
			player.car.Backward()
		else:
			player.car.Clearward()
		if Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_Z):
			player.UseProp()
	player.car.Update()
