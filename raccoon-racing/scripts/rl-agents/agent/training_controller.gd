extends AIController2D
class_name TrainingController

@export var reward_handler:RewardHandler
@export var observation_handler:ObservationHandler
@export var car:Car
@export var debug_reward_flag:bool=true
var input_action:Array[bool]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	input_action=[0,0,0,0,0]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	reward+=reward_handler.get_reward(delta)
	if debug_reward_flag:
		queue_redraw()


#-- Methods that need implementing using the "extend script" option in Godot --#
func get_obs() -> Dictionary:
	return {"obs":observation_handler.get_observation()}

func get_reward() -> float:
	return reward
	
func get_action_space() -> Dictionary:
	return {
			"throttle" : {
				"size": 2,
				"action_type": "discrete"
			},
			"steer" : {
				"size": 2,
				"action_type": "discrete"
			},
			"special" : {
				"size": 1,
				"action_type": "discrete"
			},
			}
	
func set_action(action:Dictionary) -> void:
	input_action=action['throttle'][0]
	input_action=action['throttle'][1]
	input_action=action['steer'][0]
	input_action=action['steer'][1]
	input_action=action['special'][0]

func reset()->void:
	done=true

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
