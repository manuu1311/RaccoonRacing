extends AIController2D

@export var reward_handler:RewardHandler
@export var observation_handler:ObservationHandler
@export var car:Car
@export var debug_reward_flag:bool=true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	reward+=reward_handler.get_reward(delta)
	if debug_reward_flag:
		queue_redraw()


#-- Methods that need implementing using the "extend script" option in Godot --#
func get_obs() -> Dictionary:
	assert(false, "the get_obs method is not implemented when extending from ai_controller") 
	return {"obs":[]}

func get_reward() -> float:	
	assert(false, "the get_reward method is not implemented when extending from ai_controller") 
	return 0.0
	
func get_action_space() -> Dictionary:
	assert(false, "the get get_action_space method is not implemented when extending from ai_controller") 
	return {
		"example_actions_continous" : {
			"size": 2,
			"action_type": "continuous"
		},
		"example_actions_discrete" : {
			"size": 2,
			"action_type": "discrete"
		},
		}
	
func set_action(action) -> void:
	assert(false, "the get set_action method is not implemented when extending from ai_controller") 	
# -----------------------------------------------------------------------------#

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
