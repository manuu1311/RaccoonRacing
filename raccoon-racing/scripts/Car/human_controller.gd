extends CarController
class_name HumanCarController


var steer_right_map:String
var steer_left_map:String
var accelerate_map:String
var brake_map:String
var special_map:String
const actions=['Steer right','Steer left',
				'Accelerate','Brake','Special']

func _init(playerinst:Player) -> void:
	super(playerinst)
	SeparateInputDevices()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func handle_input()->void:
	right=false
	left=false
	forward=false
	brake=false
	special=false
	if not player.car.isSleep and not (player.car.jumpCurrheight>=1) and player.car.playering:
		# Handle Steering (X-axis)
		if Input.is_action_pressed(steer_right_map):
			right=true
		elif Input.is_action_pressed(steer_left_map):
			left=true
		else:
			cancelturn=true

		# Handle Throttle/Brake (Y-axis)
		if Input.is_action_pressed(accelerate_map):
			forward=true
		elif Input.is_action_pressed(brake_map):
			brake=true
		#else:
			#player.car.Clearward()
		if Input.is_action_just_pressed(special_map):
			special=true
			#player.UseProp()

func SeparateInputDevices()->void:
	if not Game.IsSplitScreen:
		steer_right_map=actions[0]
		steer_left_map=actions[1]
		accelerate_map=actions[2]
		brake_map=actions[3]
		special_map=actions[4]
		return
	var newactionslist:Array[String]
	match player.input_device_type:
		'Keyboard 1':
			newactionslist=SeparateKeyboardInput(0)
		'Keyboard 2':
			newactionslist=SeparateKeyboardInput(1)
		'Joypad':
			newactionslist=SeparateJoypadInput(player.input_device_id)
	steer_right_map=newactionslist[0]
	steer_left_map=newactionslist[1]
	accelerate_map=newactionslist[2]
	brake_map=newactionslist[3]
	special_map=newactionslist[4]

func SeparateKeyboardInput(id:int)->Array[String]:
	var newactionslist:Array[String]=[steer_right_map,steer_left_map,
										accelerate_map,brake_map,special_map]
	for i :int in actions.size():
		var action:String=actions[i]
		var new_action:String = "p%s_%s" % [str(player.PlayerID), action]
		newactionslist[i]=new_action
		if InputMap.has_action(new_action):
			InputMap.erase_action(new_action)
		#new action
		InputMap.add_action(new_action)
		var events:Array[InputEvent] = InputMap.action_get_events(action)
		#find first or second (according to id) action with keyboard
		var keyboard_count :int= 0
		for event in events:
			if event is InputEventKey:
				if keyboard_count == id:
					InputMap.action_add_event(new_action, event.duplicate())
					break
				keyboard_count += 1
	return newactionslist

func SeparateJoypadInput(device:int)->Array[String]:
	var newactionslist:Array[String]=[steer_right_map,steer_left_map,
										accelerate_map,brake_map,special_map]
	for i :int in actions.size():
		var action:String=actions[i]
		var new_action:String = "p%s_%s" % [str(player.PlayerID), action]
		newactionslist[i]=new_action
		if InputMap.has_action(new_action):
			InputMap.erase_action(new_action)
		#new action
		InputMap.add_action(new_action)
		var events:Array[InputEvent] = InputMap.action_get_events(action)
		#find first or second (according to id) action with keyboard
		for event in events:
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				var copy:InputEvent = event.duplicate()
				copy.device = device
				InputMap.action_add_event(new_action, copy)
	return newactionslist
