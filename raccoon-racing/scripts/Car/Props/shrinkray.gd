extends Prop
class_name ShrinkProp

const RAY_SCENE: PackedScene = preload("res://Assets/Scenes/Screens/maps/Props/ShrinkInMap.tscn")

var use_time: float = 3.0
var add_horse: float = 0.5
var small_scale: float = 1.0 / 3.0
var duration:float=0.5

var attacker: Car = null  # renamed: this is who fired the ray
var active_ray: ShrinkInMap = null
var effect_started: bool = false

func _init(player_inst: Player, attacker_car: Car) -> void:
    super(player_inst)
    proptype = 9
    player.prop.del_prop_by_type(9)
    self.attacker = attacker_car
    player.car.sounds.playPandaSSound()
    # Fire immediately — no need to wait for run() to pick it up
    effect_started = true
    _apply_shrink_effect()

func run() -> void:
    # Ray still spawns here since we need the scene tree
    if active_ray == null and is_instance_valid(attacker):
        active_ray = RAY_SCENE.instantiate() as ShrinkInMap
        player.car.map.add_child(active_ray)
        active_ray.setup(attacker, player.car, use_time)
        active_ray.z_index=2

    if not effect_started:
        effect_started = true
        _apply_shrink_effect()

func _apply_shrink_effect() -> void:
    # No attacker = fired into void, Flash just cleans up after 500ms
    if not is_instance_valid(attacker):
        await player.car.get_tree().create_timer(0.5).timeout
        player.prop.Delprop(self)
        return

    # Shrink player (the victim), not the attacker
    var original_horse: float = player.car.horse
    player.car.horse *= add_horse
    player.car.isSmallState = true

    var tween: Tween = player.car.create_tween()
    tween.tween_property(player.car, "shrinkscale", small_scale, 0.3)

    await player.car.get_tree().create_timer(use_time).timeout

    if not is_instance_valid(player):
        return

    player.car.horse = original_horse
    player.car.isSmallState = false

    var restore_tween: Tween = player.car.create_tween()
    restore_tween.tween_property(player.car, "shrinkscale", 1, 0.5)
    player.prop.del_prop_by_type(3)
    delme()

func delme()->void:
    player.prop.Delprop(self)
    
func del()->void:
    queue_free()
