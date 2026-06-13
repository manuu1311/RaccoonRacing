extends CarController
class_name HumanCarController

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
    var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

    # Handle Steering (X-axis)
    if input_dir.x > 0:
        car.TurnLRight()
    elif input_dir.x < 0:
        car.TurnLeft()
    else:
        car.CancelTurn()

    # Handle Throttle/Brake (Y-axis)
    if input_dir.y < 0:
        car.Forward()  # In Godot 2D, negative Y is UP
    elif input_dir.y > 0:
        car.Backward()
    else:
        car.Clearward()
    car.Update()
