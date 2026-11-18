extends Node2D
class_name RewardHandler

var rl_player:RLPlayer
@export var car:Car
@export var passive_penalty:float=0.2
@export var progress_reward_multiplier:float=0.05
@export var checkpoint_reward_bonus:float=10.0
@export var win_reward_bonus:float=50.0
@export var idle_reward_penalty:float=-10
@export var disruptor_reward_multiplier:float=0.0
@export var overtake_reward_bonus:float=0.0
@export var state_penalty:float=0.0
@export var propbox_reward:float=0.0
@export var wallhit_penalty:float=0.0
@export var speed_bonus:float=0.0

var current_checkpoint_id:int
var current_distance:float
# --------overtake reward-----------
var streak:=0
var confirmed_rank:=3
var candidate_rank:=3
var streak_length:=7
# --------state reward-----------
var bs_prev:=false
var bsex_prev:=0
var propid_prev:=0
var wallhit_accumulated_rew:=0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rl_player=car.player as RLPlayer
	car.WallBump.connect(_on_wall_hit)


func reset()->void:
	current_checkpoint_id = rl_player.current_point_id
	current_distance = _get_distance_to_checkpoint()
	confirmed_rank=3
	candidate_rank=3
	streak=0
	bs_prev=false
	bsex_prev=0
	propid_prev=0
	wallhit_accumulated_rew=0.0

func get_reward(mode:String) -> float:
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
	rew+=_get_passive_reward(mode)
	rew+=get_wall_penalty()
	rew+=get_state_penalty()
	rew+=get_propbox_shaping()
	rew+=overtake_reward()
	# reward speed
	rew += speed_bonus * clampf(car.speed.length() / 20, 0.0, 1.0)
	return rew

func _get_passive_reward(mode:String)->float:
	var rew:=0.0
	if mode=='curriculum':
		# constant passive penalty
		rew -= passive_penalty
	elif mode in ['early','mid','proppy','competitive']:
		# passive penalty scaled by track position 
		# 0 for first player, 3x for last player
		rew-=passive_penalty*(1.0 + 0.25 * car.player.OrderId)
	return rew
	
func _get_progress_reward()->float:
	var new_distance:=_get_distance_to_checkpoint()
	var rew:float=max(
		0, current_distance-new_distance
	)*progress_reward_multiplier
	current_distance=min(new_distance,current_distance)
	return rew


func overtake_reward() -> float:
	var raw_rank: int = car.player.OrderId
	if raw_rank == confirmed_rank:
		streak = 0
		return 0.0
	if raw_rank == candidate_rank:
		streak += 1
	else:
		candidate_rank = raw_rank
		streak = 1
	if streak >= streak_length:
		var gained := confirmed_rank - raw_rank  # positive = moved up
		confirmed_rank = raw_rank
		streak = 0
		return overtake_reward_bonus * gained
	return 0.0

func get_state_penalty()->float:
	var rew:=0.0
	# penalise car spin after mine or missile hit, bsex between 0 and 100
	rew-=maxf(0,(car.bsex-bsex_prev)/100.0)*state_penalty
	# penalise new bs effect, binary
	if not bs_prev and car.bs:
		# divide by 2
		rew-=state_penalty*0.5
	bsex_prev=car.bsex
	bs_prev=car.bs
	return rew

func get_propbox_shaping()->float:
	var rew:=0.0
	# if inventory was empty and now has an item
	if propid_prev==0 and car.NowPorpId!=0:
		rew+= propbox_reward * (1.0 + 0.5 * car.player.OrderId)
	propid_prev=car.NowPorpId
	return rew

func get_wall_penalty()->float:
	var rew:=wallhit_accumulated_rew
	wallhit_accumulated_rew=0.0
	return rew
	
func _on_wall_hit(speed_lost:float)->void:
	wallhit_accumulated_rew-=clampf(abs(speed_lost) / 15.0, 0.0, 1.0)*wallhit_penalty

func add_win_reward()->float:
	return win_reward_bonus

func _get_distance_to_checkpoint()->float:
	return (
		car.global_position-rl_player.ai_points[rl_player.current_point_id]
		).length()
