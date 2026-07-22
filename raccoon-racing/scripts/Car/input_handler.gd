extends Node
class_name InputHandler

var player:Player
var controller:CarController

func setup(playerinst:Player,controllerinst:CarController)->void:
	player=playerinst
	controller=controllerinst

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _rollback_tick(_delta: float, tick: int, is_fresh: bool) -> void:
	player.car.isLock=tick<player.car.StartTick
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
		##special
		if controller.special and is_fresh:
			print('--using special!--z')
			player.UseProp()
	player.Update(tick, is_fresh)
