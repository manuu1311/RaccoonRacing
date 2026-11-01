extends AIController2D
class_name TrainingController

@export var reward_handler:RewardHandler
@export var observation_handler:ObservationHandler
@export var car:Car
@export var debug_reward_flag:bool=true
var input_action:Array[bool]
var finished: bool = false
var last_obs: PackedFloat32Array
var should_add_win_bonus:bool=false
var total_reward_debug:float=0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reset_after=9999999
	input_action=[0,0,0,0,0]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if debug_reward_flag:
		queue_redraw()


#-- Methods that need implementing using the "extend script" option in Godot --#
func get_obs() -> Dictionary:
	if finished:
		print('noo it finished..')
		return {"obs": last_obs}
	last_obs = observation_handler.get_observation()
	return {"obs": last_obs}

func get_reward() -> float:
	if finished:
		if should_add_win_bonus:
			should_add_win_bonus=false
			return reward_handler.add_win_reward()
		return 0.0
	reward+=reward_handler.get_reward()
	total_reward_debug+=reward
	return reward
	
func get_action_space() -> Dictionary:
	return {
		# 0 neutral, 1 accelerate, 2 brake
		"throttle": {
			"size": 3, "action_type": "discrete"
			}, 
		# 0 neutral, 1 left, 2 right
		"steer":    {
			"size": 3, "action_type": "discrete"
			}, 
		# 0 off, 1 on
		"special":  {
			"size": 2, "action_type": "discrete"
			}, 
			}
	
func set_action(action:Dictionary) -> void:
	var throttle := int(action["throttle"])
	var steer := int(action["steer"])
	var special := int(action["special"])

	# accelerate, brake, left, right, special
	input_action = [
		throttle == 1,
		throttle == 2,
		steer == 1,
		steer == 2,
		special == 1,
	]

func _end_episode()->void:
	total_reward_debug=0.0
	done=true
	finished=false

func _end_race(id:int)->void:
	finished=true
	if id==car.playerID:
		should_add_win_bonus=true

# debug total reward
func _draw() -> void:
	if debug_reward_flag:
		var font: Font = ThemeDB.fallback_font
		var font_size: int = ThemeDB.fallback_font_size

		var text_position := car.position+Vector2(-10, -150) 

		var debug_text := "Reward: %.2f" % [total_reward_debug]

		draw_string(
			font,
			text_position,
			debug_text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size,
			Color.GREEN
		)
