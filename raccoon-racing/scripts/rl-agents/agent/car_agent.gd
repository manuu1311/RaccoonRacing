extends Node2D
class_name CarAgent

@export var car:Car
@export var observation_handler:ObservationHandler
@export var reward_handler:RewardHandler
@export var training_controller:TrainingController

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func get_action()->Array[bool]:
	return training_controller.input_action
