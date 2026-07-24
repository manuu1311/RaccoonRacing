extends Node
class_name InputHandler

var player:Player
var controller:CarController
var specialtick:int=0

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
        if controller.special and tick>specialtick:
            prints('view from player:',GameData.FocusPlayer.PlayerID,'player:',player.charid,'using prop:',player.car.NowPorpId,'but can he use it:',player.car.CanUseProp)
            player.UseProp()
            specialtick=tick
    player.Update(tick, is_fresh)
