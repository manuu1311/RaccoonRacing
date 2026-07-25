extends Node
class_name InputHandler

var player:Player
var controller:CarController
var specialtick:int=0

func setup(playerinst:Player,controllerinst:CarController)->void:
	player=playerinst
	controller=controllerinst

func _process(_delta: float) -> void:
	player.car.isLock=NetworkTime.tick<player.car.StartTick
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
			prints('view from player:',GameData.FocusPlayer.PlayerID,'player:',player.charid,'using prop:',player.car.NowPorpId,'but can he use it:',player.car.CanUseProp)
			player.UseProp()
			controller.special_buffered=false
	player.Update()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _rollback_tick(_delta: float, tick: int, is_fresh: bool) -> void:
	player.car.isLock=tick<player.car.StartTick
	player.car.isfresh=is_fresh
	player.car.currtick=tick
	if tick==player.car.StartTick:
		if(player.car.speed.length() > 2):
			player.car.speed=Vector2.ZERO;
		elif(player.car.speed.length() > 0.5):
			player.car.StartBoost=true
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
		if controller.special and tick>specialtick:
			prints('view from player:',GameData.FocusPlayer.PlayerID,'player:',player.charid,'using prop:',player.car.NowPorpId,'but can he use it:',player.car.CanUseProp)
			player.UseProp()
			controller.special_buffered=false
			specialtick=tick
	player.Update(tick, is_fresh)
