extends Prop
class_name BoneProp

var UseTime:float=4
var start_tick: int
var end_tick: int
var ended: bool = false

func _init(playerinst:Player)->void:
    super(playerinst);
    proptype = 9;
    player.prop.del_prop_by_type(9)
    delme()
    player.car.prop_effector.PlayBone()
    player.car.prop_effector.bonehit.connect(DeleteProp)
    start_tick = NetworkTime.tick
    end_tick = start_tick + int(NetworkTime.tick_rate * UseTime)

func run_tick(tick: int, is_fresh: bool) -> void:
    if ended:
        return
    if tick >= end_tick:
        ended = true
        if is_fresh:
            _expire()
#TODO: set the scale in event inmap object
func run()->void:
    player.car.prop_effector.bone.scale*=1.0007


func _expire() -> void:
    if is_instance_valid(player.car):
        player.prop.Delprop(self)
        player.car.sounds.StopdogSSound()
        player.car.prop_effector.StopBone()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func delme() -> void:
    await player.car.get_tree().create_timer(UseTime).timeout
    if is_instance_valid(player.car):
        DeleteProp()

func DeleteProp()->void:
    player.prop.Delprop(self)

func del()->void:
    player.car.sounds.StopdogSSound()
    player.car.prop_effector.StopBone()
    queue_free()
