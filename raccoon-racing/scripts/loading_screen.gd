extends CanvasLayer
class_name LoadingScreen

@onready var hint: AnimatedSprite2D = $Hint
@onready var percentage: Label = $Text/Percentage

var target_scene: String = "res://Assets/Scenes/Screens/experiment.tscn"
var progress_array: Array = []
var hint_timer: float = 0.0
var hint_interval: float = 3.5

# --- progress model ---------------------------------------------------
# The bar has two phases:
#   0.0 .. LOAD_WEIGHT        -> driven by the REAL ResourceLoader progress
#   LOAD_WEIGHT .. 1.0        -> driven by SetSetupProgress() calls from
#                                whatever does the post-load setup (world.gd)
# display_progress never jumps; it chases target_progress every frame so
# the % label always reads smoothly even if the underlying steps are chunky.
const LOAD_WEIGHT := 0.7
var display_progress: float = 0.0
var target_progress: float = 0.0
var smooth_speed: float = 1.5 # bar-fractions per second it can move

func _ready() -> void:
	visible = false
	set_process(false)

func ChangeScene() -> void:
	visible = true
	set_process(true)
	display_progress = 0.0
	target_progress = 0.0
	percentage.text = "0%"
	hint_timer = 0.0

	if get_tree().current_scene:
		get_tree().current_scene.queue_free()
		get_tree().current_scene = null

	target_scene = 'res://Assets/Scenes/Screens/experiments/Experiment1.tscn'

	UiOverAnimation.animated_sprite_2d.frame = 0
	hint.stop()
	_cycle_hint()

	ResourceLoader.load_threaded_request('res://Assets/Scenes/Screens/maps/Map%02d.tscn' % GameData.currentMap)
	ResourceLoader.load_threaded_request(target_scene)

	call_deferred('_wait_for_loading')

func _wait_for_loading() -> void:
	while true:
		var status := ResourceLoader.load_threaded_get_status(target_scene, progress_array)

		if progress_array.size() > 0:
			# real progress (0..1) from the resource loader, scaled into the
			# first LOAD_WEIGHT slice of the bar. Never goes backwards.
			target_progress = max(target_progress, float(progress_array[0]) * LOAD_WEIGHT)

		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var packed_scene: PackedScene = ResourceLoader.load_threaded_get(target_scene)
			target_progress = LOAD_WEIGHT
			get_tree().change_scene_to_packed(packed_scene)
			break
		elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("LoadingScreen: failed to load %s (status %d)" % [target_scene, status])
			# TODO: surface an actual error/retry UI here instead of hanging silently.
			break

		await get_tree().process_frame

# Called by the new scene's own setup code (see world.gd) once the resource
# has finished loading. stage_ratio is 0..1 progress *within* setup — the
# loading screen maps that onto the remaining (1 - LOAD_WEIGHT) of the bar.
func SetSetupProgress(stage_ratio: float) -> void:
	target_progress = LOAD_WEIGHT + (1.0 - LOAD_WEIGHT) * clamp(stage_ratio, 0.0, 1.0)

func _process(delta: float) -> void:
	display_progress = move_toward(display_progress, target_progress, smooth_speed * delta)
	percentage.text = str(int(display_progress * 100)) + "%"

	hint_timer += delta
	if hint_timer >= hint_interval:
		hint_timer = 0.0
		_cycle_hint()

func _cycle_hint() -> void:
	var total_frames: int = hint.sprite_frames.get_frame_count(hint.animation)
	if total_frames <= 1:
		return
	var newframe: int = hint.frame
	while newframe == hint.frame:
		newframe = randi_range(0, total_frames - 1)
	hint.frame = newframe

func HideLoading() -> void:
	target_progress = 1.0
	display_progress = 1.0
	percentage.text = "100%"
	set_process(false)
	visible = false
