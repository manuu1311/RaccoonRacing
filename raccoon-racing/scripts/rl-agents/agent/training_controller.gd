extends AIController2D
class_name TrainingController

@export var reward_handler:RewardHandler
@export var observation_handler:ObservationHandler
@export var car:Car
@export var debug_reward_flag:bool=true
var input_action:Array[bool]
var finished: bool = false
var last_obs: PackedFloat32Array

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	input_action=[0,0,0,0,0]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if debug_reward_flag:
		queue_redraw()


#-- Methods that need implementing using the "extend script" option in Godot --#
func get_obs() -> Dictionary:
	if finished:
		return {"obs": last_obs}
	last_obs = observation_handler.get_observation()
	return {"obs": last_obs}

func get_reward() -> float:
	if finished:
		return 0.0
	reward+=reward_handler.get_reward()
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

func end_episode()->void:
	done=true
	finished=false

func _end_race(_id:int)->void:
	finished=true

# debug total reward
func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	var font_size: int = ThemeDB.fallback_font_size

	var text_position := car.position+Vector2(-10, -150) 

	var debug_text := "Reward: %.2f" % [reward]

	draw_string(
		font,
		text_position,
		debug_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		Color.GREEN
	)
