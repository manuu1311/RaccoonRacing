extends CanvasLayer
class_name LoadingScreen

@onready var hint: AnimatedSprite2D = $Hint
@onready var percentage: Label = $Text/Percentage

var target_scene: String = "res://Assets/Scenes/Screens/experiment.tscn"
var progress_array: Array = [] 
var hint_timer: float = 0.0
var hint_interval: float = 3.5
var totaltime:float=0.0
var expectedtime:float=5


func _ready() -> void:
	visible=false

func ChangeScene() -> void:
	visible=true
	if get_tree().current_scene:
		get_tree().current_scene.queue_free()
		get_tree().current_scene = null
	if Game.IsSplitScreen:
		target_scene='res://Assets/Scenes/Screens/experiments/Experiment1.tscn'
	else:
		target_scene='res://Assets/Scenes/Screens/experiments/Experiment1.tscn'
	UiOverAnimation.animated_sprite_2d.frame=0
	hint.stop()
	_cycle_hint()
	ResourceLoader.load_threaded_request('res://Assets/Scenes/Screens/maps/Map%02d.tscn' % GameData.currentMap)
	ResourceLoader.load_threaded_request(target_scene)
	call_deferred('_wait_for_loading')

func _wait_for_loading() -> void:
	while true:
		# Pass progress_array so Godot can write the percentage into it
		var status: = ResourceLoader.load_threaded_get_status(target_scene, progress_array)
		
		# Update Percentage Text
		if progress_array.size() > 0:
			percentage.text = str(int(min(totaltime/expectedtime,0.90)*100)) + "%"
		
		# Cycle Hint images every 2 seconds
		hint_timer += get_process_delta_time()
		totaltime += get_process_delta_time()
		if hint_timer >= hint_interval:
			hint_timer = 0.0
			_cycle_hint()
			
		# Check Loading Status
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			percentage.text="100%"
			await get_tree().create_timer(0.3).timeout
			var packed_scene:Resource = ResourceLoader.load_threaded_get(target_scene)
			get_tree().change_scene_to_packed(packed_scene)
			break
		elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			print("Error: Failed to load scene.")
			break
			
		await get_tree().process_frame

func _cycle_hint() -> void:
	# Get total frames in current animation
	var total_frames:int = hint.sprite_frames.get_frame_count(hint.animation)
	var newframe:int=hint.frame
	while newframe==hint.frame:
		newframe=randi_range(0,total_frames-1)
	hint.frame=newframe

func HideLoading()->void:
	visible=false
