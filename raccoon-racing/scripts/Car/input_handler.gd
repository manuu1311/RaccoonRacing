extends Node
class_name InputHandler

var player:Player
var controller:CarController
var specialtick:int=0

func setup(playerinst:Player,controllerinst:CarController)->void:
	player=playerinst
	controller=controllerinst

func _process(_delta: float) -> void:
	if not player.car.isSleep:
		##steering
		if controller.right:
			player.car.TurnLRight()
		elif controller.left:
			player.car.TurnLeft()
		else:
			player.car.CancelTurn()
		##accelerating
		if controller.forward:
			player.car.Forward()
		elif controller.brake:
			player.car.Backward()
		else:
			player.car.Clearward()
		if controller.special:
			player.UseProp()
			controller.special_buffered=false
	if is_multiplayer_authority():
		player.Update()
	
