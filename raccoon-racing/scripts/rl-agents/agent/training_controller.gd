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
var mode:String
var timer:Timer
var idle_timer_duration:=60
signal car_idled()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reset_after=9999999
	input_action=[0,0,0,0,0]

func set_mode(new_mode:String)->void:
	mode=new_mode
	apply_mode()

func apply_mode()->void:
	if mode=='curriculum':
		reward_handler.passive_penalty=0.2
		if timer == null:
			timer = Timer.new()
			timer.one_shot = true
			add_child(timer)
			timer.timeout.connect(idle_finish)
			var player := car.player as RLPlayer
			player.new_point_reached.connect(timer_restart)
		timer.start(idle_timer_duration)
	elif mode=='early':
		pass
	elif mode=='competitive':
		pass
	elif mode=='adversarial':
		pass

func timer_restart()->void:
	timer.start(idle_timer_duration)

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

# episode ended
func _end_episode()->void:
	total_reward_debug=0.0
	done=true
	finished=false
	if mode == 'curriculum':
		timer.start(idle_timer_duration)

# race ended
func _end_race(id:int)->void:
	finished=true
	if id==car.playerID:
		should_add_win_bonus=true

# finish by idle timer
func idle_finish()->void:
	timer.stop()
	reward+=reward_handler.idle_reward_penalty
	car_idled.emit()

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
