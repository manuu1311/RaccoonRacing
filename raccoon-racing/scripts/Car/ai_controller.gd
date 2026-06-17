extends CarController
class_name AICarController


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	player.car.Update()
