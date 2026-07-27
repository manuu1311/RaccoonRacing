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
			player.car.CurrentState=Car.turnstate.RIGHT
		elif controller.left:
			player.car.TurnLeft()
			player.car.CurrentState=Car.turnstate.LEFT
		else:
			player.car.CancelTurn()
			player.car.CurrentState=Car.turnstate.FORWARD
		##accelerating
		if controller.forward:
			player.car.Forward()
			player.car.IsAccelerating=true
		elif controller.brake:
			player.car.Backward()
			player.car.IsAccelerating=false
		else:
			player.car.Clearward()
		if controller.special:
			player.UseProp()
			controller.special_buffered=false
	if is_multiplayer_authority():
		player.AuthorityUpdate()
	player.Update()
	
