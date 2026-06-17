extends Prop
class_name PetroProp


var UseTime:float = 4;
var AddHorse:float = 1.8;
var AddHorsebyAuto:float = 0.2;
  
func _init(playerinst:Player) -> void:
    super(playerinst);
    proptype = 8;
    player.prop.del_prop_by_type(proptype);
    player.car.sounds.playPetroSound();
    delme()

func run()->void:
    if player.car.jumpCurrheight<1:
        player.car.speed+=Vector2(AddHorsebyAuto,0).rotated(player.car.rotation-PI/2)
    player.car.prop_effector.AddPetro();
    
    
func delme()->void:
    await player.car.get_tree().create_timer(UseTime).timeout
    player.ResetUse()
    player.car.prop_effector.StopPetro()
    if is_instance_valid(self):
        player.prop.Delprop(self);

func del()->void:
    pass
