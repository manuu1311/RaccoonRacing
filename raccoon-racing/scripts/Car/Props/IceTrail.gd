extends Prop
class_name IceTrailProp

@export var use_time: float = 2.0
@export var ice_width: float = 30.0
var IcePatchScene: PackedScene
var trail: IceTrailInMap
var time_active: float = 0.0
var active: bool = true
var delta: float = 0.0
var end_timer: SceneTreeTimer

func _init(playerinst: Player) -> void:
	super(playerinst)
	proptype = 9
	IcePatchScene = preload("res://Assets/Scenes/Screens/maps/Props/IceTrail.tscn")
	player.car.sounds.playIceSound()
	_spawn_trail()
	end_timer = player.car.get_tree().create_timer(use_time)
	end_timer.timeout.connect(_on_use_time_elapsed)

func _spawn_trail() -> void:
	trail = IcePatchScene.instantiate()
	player.car.map.add_child(trail)
	# Start the trail at the car's rear (70 units behind)
	trail.global_position = player.car.global_position + player.car.transform.y * 70
	trail.add_point(Vector2.ZERO)  # First point at origin

func _physics_process(deltat: float) -> void:
	delta = deltat

func run_tick(_tick: int, is_fresh: bool) -> void:
	if not active or not is_instance_valid(trail) or not is_fresh:
		return
	time_active += delta
	trail.add_point(player.car.global_position + player.car.transform.y * 70)

func _on_use_time_elapsed() -> void:
	active = false
	if is_instance_valid(trail):
		trail.stop_growing()
	player.prop.Delprop(self)

func del() -> void:
	if is_instance_valid(trail):
		trail.queue_free()
	queue_free()

func _exit_tree() -> void:
	if end_timer and end_timer.is_connected("timeout", _on_use_time_elapsed):
		end_timer.disconnect("timeout", _on_use_time_elapsed)
