extends Node2D
class_name CarAgent

@export var car: Car
@export var observation_handler: ObservationHandler
@export var reward_handler: RewardHandler
@export var training_controller: TrainingController
@export var is_adversarial_agent := false

const ACTION_REPEAT := 5
const RACING_AGENT_PATH := "res://Assets/agents/racing_agent.bin"
const ADVERSARIAL_AGENT_PATH := "res://Assets/agents/adversarial_agent.bin"

var policy := LSTMPolicy.new()
var frames_left := 0
var input_action: Array[bool] = [false, false, false, false, false]

func _ready() -> void:
	var path := ADVERSARIAL_AGENT_PATH if is_adversarial_agent else RACING_AGENT_PATH
	if not policy.load_weights(path):
		push_error("Failed to load policy %s" % path)
	reset_agent()

## call whenever a race/episode starts or restarts.
func reset_agent() -> void:
	policy.reset_state()
	frames_left = 0
	input_action = [false, false, false, false, false]

func get_action() -> Array[bool]:
	if Game.is_training:
		return training_controller.input_action

	if frames_left <= 0:
		var obs := PackedFloat32Array(observation_handler.get_observation())
		set_action(policy.act_from_obs(obs))
		#set_action(policy.sample_from_obs(obs))
		frames_left = ACTION_REPEAT
	frames_left -= 1
	return input_action

func set_action(action: Dictionary) -> void:
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
