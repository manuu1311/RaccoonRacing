extends Node2D
class_name RewardHandler

var rl_player:RLPlayer
@export var car:Car
@export var passive_penalty:float
@export var progress_reward_multiplier:float=0.05
@export var checkpoint_reward_bonus:float=10.0
@export var disruptor_reward_multiplier:float=0.0
@export var debug:bool=true
var current_checkpoint_id:int
var current_distance:float
# delta for passive reward
var _last_physics_frame := Engine.get_physics_frames()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rl_player=car.player as RLPlayer


func reset()->void:
	current_checkpoint_id = rl_player.current_point_id
	current_distance = _get_distance_to_checkpoint()

func get_reward() -> float:
	# update delta time
	var frames := Engine.get_physics_frames() - _last_physics_frame
	_last_physics_frame = Engine.get_physics_frames()
	var dt := frames / float(Engine.physics_ticks_per_second)
	var rew:=0.0
	# agent reached a new checkpoint -> give distance reward as well as 
	# bonus reward
	if rl_player.current_point_id!=current_checkpoint_id:
		# give remaining distance as reward
		rew+=current_distance*progress_reward_multiplier
		# bonus for new checkpoint reached
		rew+=checkpoint_reward_bonus
		# calculate distance between next 2 checkpoints
		current_distance=(rl_player.ai_points[current_checkpoint_id]-
			rl_player.ai_points[rl_player.current_point_id]).length()
		# update point id 
		current_checkpoint_id = rl_player.current_point_id
	

	# check for agent progress
	rew+=_get_progress_reward()
	# passive reward
	rew -= passive_penalty*dt
	return rew

func _get_progress_reward()->float:
	var new_distance:=_get_distance_to_checkpoint()
	var rew:float=max(
		0, current_distance-new_distance
	)*progress_reward_multiplier
	current_distance=min(new_distance,current_distance)
	return rew

func _get_distance_to_checkpoint()->float:
	return (
		car.global_position-rl_player.ai_points[rl_player.current_point_id]
		).length()
