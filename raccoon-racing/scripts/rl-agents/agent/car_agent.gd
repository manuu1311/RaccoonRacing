extends Node2D
class_name CarAgent

#region export variables
@export var car:Car
@export var sensors:CustomRaycastObs
@export_group("Observation Tuning")
## offset to account for car shape in raycast sensors
@export var raycast_sensors_offset:=30
## maximum forward and lateral speed
@export var max_speed:=Vector2(15,25)
## maximum inverse speed (higher resolution)
@export var max_speed_reverse:=9.0
## maximum car detection range (after which observation is saturated)
@export var car_detection_range:=1200
## offset to account for car shape in car distance calculation
@export var car_detection_offset:=0
#@export var car_detection_offset:=60
## buffer size for static hazards
@export var static_hazard_buffer_length:=4
## maximum static hazard detection range (after which observation is saturated)
@export var static_hazard_detection_range:=1000
## prop box buffer size
@export var prop_box_buffer_length:=5
## max jump height
@export var max_jump_height:=30.0
@export_group("Debug Settings")
@export var debug_rays_flag:bool=true
@export var debug_wall_color:Color=Color.RED
@export var debug_jumpwall_color:Color=Color.YELLOW
@export var debug_empty_color:Color=Color.GREEN
@export var debug_ray_width:int=2
@export var debug_stats_flag:bool=true
@export var debug_opponent_flag:bool=true
@export var debug_map_events_flag:bool=true
#endregion

#region agent input variables
var sensor_output:PackedFloat32Array
var car_state:PackedFloat32Array
#endregion

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _process(_delta: float) -> void:
	sensor_output=sensors.get_observation()
	car_state=_get_internal_state(car)
	#_get_hazards_state()
	if debug_rays_flag or debug_stats_flag:
		queue_redraw()


#region Observation

func _normalize_dist(dist: float, max_dist: float,offset:int,zero_range:bool, inverse:bool=true) -> float:
	var clamped_dist:float
	var log_0_to_1: float
	if zero_range:
		var sign_factor: float = signf(dist)
		if sign_factor == 0.0:
			sign_factor = 1.0
		var abs_dist: float = absf(dist)
		clamped_dist = clampf(abs_dist - offset, 0.0, max_dist)
		log_0_to_1 = log(1.0 + clamped_dist) / log(1.0 + max_dist)
		var magnitude: float = (1.0 - log_0_to_1) if inverse else log_0_to_1
		return magnitude * sign_factor
	# Remap from [0.0, 1.0] to [-1.0, 1.0]
	else:
		clamped_dist = clampf(dist-offset, 0.0, max_dist)
		log_0_to_1 = log(1.0 + clamped_dist) / log(1.0 + max_dist)
		return (log_0_to_1 * 2.0) - 1.0


func _normalize_raycast(dist: float, max_dist: float,offset:int,zero_range:bool, inverse:bool=true) -> float:
	var clamped_dist:float
	var log_0_to_1: float
	if zero_range:
		clamped_dist = clampf(dist-offset, 0.0, max_dist)
		log_0_to_1 = log(1.0 + clamped_dist) / log(1.0 + max_dist)
		if inverse:
			return 1-log_0_to_1
		else:
			return log_0_to_1
	# Remap from [0.0, 1.0] to [-1.0, 1.0]
	else:
		clamped_dist = clampf(dist-offset, 0.0, max_dist)
		log_0_to_1 = log(1.0 + clamped_dist) / log(1.0 + max_dist)
		return (log_0_to_1 * 2.0) - 1.0


## Computes and returns the flattened observation array for the opponent kart.
## [br]
## Returns a [PackedFloat32Array] containing 42 normalized feature elements, 
## structured into the following observation groups:
## [br]
## [b]Speed & Physics (Indices 0–2)[/b]
## • [code][0,1][/code]: Relative speed vector
## [br]
## [b]Airborne & Car State (Indices 3–8)[/b]
## • [code][2,3][/code]: Current and previous jump height 
## • [code][4][/code]: Is jumping flag 
## • [code][5,6][/code]: Bs and its direction flags
## • [code][7,8][/code]: Bsx flag and its magnitude
## [br]
## [b]Surface Properties (Indices 9–15)[/b]
## • [code][9][/code]: Is at ice flag
## • [code][10][/code]: Friction (how close car is to bs)
## [br]
## [b]Status & Power-Ups (Indices 11–42)[/b]
## • [code][11..26][/code]: Currently active props, and its duration. Nominally: 
## [br]
## • [b]Sleep[/b] [code][11,12][/code], [b]Boost[/b] [code][13,14][/code], [b]Star[/b] [code][15,16][/code], 
## [b]Shield[/b] [code][17,18][/code], [b]Small state[/b] [code][19,20][/code], 
## [b]Ice trail[/b] [code][21,22][/code], [b]Bone[/b] [code][23,24][/code], [b]Bone position[/b],
## relative to the car, expressed in sin,cos [code][25,26][/code]
## [br]
## • [code][27][/code]: Can use prop flag
## [br]
## • [code][28,29][/code]: Relative rotation (sin, cos)
## [br]
## • [code][30,31][/code]: Relative distance
## [br]
## • [code][32][/code]: Relative scalar distance
## [br]
## • [code][33][/code]: Flag: is distance saturated (car out of range)
## [br]
## • [code][34,35][/code]: Scalar velocity of opponent to the agent, 
## lateral and perpendicular (is opponent approaching/dodging me?)
## [br]
## • [code][36,37][/code]: Scalar velocity of agent to the opponent, 
## lateral and perpendicular (am i approaching/dodging opponent?)
## [br]
## @return PackedFloat32Array of size 38, containing flattened float features.
func _get_opponent_state(car_inst:Car)->PackedFloat32Array:
	var vectorized:=PackedFloat32Array()
	vectorized.resize(38)
	var speed:=_speed_to_relative(car_inst.speed)
	# since opponent can move at maximum speed in any axis, relative to own car
	vectorized[0]=speed.x/max_speed[1]
	vectorized[1]=-speed.y/max_speed[1]
	vectorized[2]=car_inst.jumpCurrheight/max_jump_height
	vectorized[3]=car_inst.jumpPrevheight/max_jump_height
	# is jumping flag
	if car_inst.jumpCurrheight>1:
		vectorized[4]=1.0
	else:
		vectorized[4]=0.0
	if car_inst.bs:
		vectorized[5]=1.0
		vectorized[6]=1.0 if car_inst.bsf else 0.0
	else:
		vectorized[5]=0.0
		vectorized[6]=0.0
	if car_inst.bsex>0:
		vectorized[7]=1.0
		vectorized[8]=car_inst.bsex/100.0
	else:
		vectorized[7]=0.0
		vectorized[8]=0.0
	if car_inst.isAtIce:
		vectorized[9]=1.0
	else:
		vectorized[9]=0.0
	# car friction
	vectorized[10]=car_inst.friction/90
	# sleep
	_process_prop(vectorized,11,car_inst.player.prop.get_prop_by_type(2))
	# boost
	_process_prop(vectorized,13,car_inst.player.prop.get_prop_by_type(8))
	# invincibility star
	_process_prop(vectorized,15,car_inst.player.prop.get_prop_by_type(1))
	# shield
	_process_prop(vectorized,17,car_inst.player.prop.get_prop_by_type(3))
	# laser small state
	_process_prop(vectorized,19,car_inst.player.prop.get_prop_by_type(10))
	# ice trail state
	_process_prop(vectorized,21,car_inst.player.prop.get_prop_by_type(12))
	# bone state
	if _process_prop(vectorized,23,car_inst.player.prop.get_prop_by_type(11)):
		#give bone rotation
		vectorized[25]=sin(car_inst.prop_effector.bone_wrapper.rotation)
		vectorized[26]=cos(car_inst.prop_effector.bone_wrapper.rotation)
	else:
		vectorized[25]=0.0
		vectorized[26]=0.0
	
	# can use prop flag
	vectorized[27]=1.0 if car_inst.player.can_use_prop_check() else 0.0
	
	# rotation relative to own car 
	vectorized[28]=sin(car_inst.global_rotation-car.global_rotation)
	vectorized[29]=cos(car_inst.global_rotation-car.global_rotation)
	# are relative coordinates better, or direction and magnitude?
	# with magnitude, i have to calculate a square root (length calculation)
	var relative_coords : Vector2 = _position_to_relative(
				car_inst.global_position)
	vectorized[30] = _normalize_dist(
				relative_coords[0],car_detection_range,car_detection_offset,true
				)
	vectorized[31] = _normalize_dist(
				relative_coords[1],car_detection_range,car_detection_offset,true
				)
	# scalar distance
	vectorized[32]=_normalize_dist(
				relative_coords.length(),car_detection_range,
				car_detection_offset,true
				)
	# one axis out of range: car not present in range (saturated signal)
	if abs(relative_coords.x) > car_detection_range or abs(relative_coords.y) > car_detection_range:
		vectorized[33]=0.0
	# car present in range
	else:
		vectorized[33]=1.0
	var closing_speed := 0.0
	var lateral_speed := 0.0
	var ego_approach_speed := 0.0
	var ego_lateral_speed := 0.0

	var dist_len := relative_coords.length()
	if dist_len > 0.0001:
		var dir_to_opponent := relative_coords / dist_len
		var perp_dir := Vector2(-dir_to_opponent.y, dir_to_opponent.x)

		closing_speed = -speed.dot(dir_to_opponent)
		lateral_speed = speed.dot(perp_dir)
		vectorized[34] = clamp(closing_speed / max_speed[1], -1.0, 1.0)
		vectorized[36] = clamp(lateral_speed / max_speed[1], -1.0, 1.0)

		var ego_relative_speed := _speed_to_relative(car.speed)
		ego_approach_speed = ego_relative_speed.dot(dir_to_opponent)
		ego_lateral_speed = ego_relative_speed.dot(perp_dir)
		vectorized[35] = clamp(ego_approach_speed / max_speed[1], -1.0, 1.0)
		vectorized[37] = clamp(ego_lateral_speed / max_speed[1], -1.0, 1.0) 
	else:
		vectorized[34] = 0.0
		vectorized[35] = 0.0
		vectorized[36] = 0.0
		vectorized[37] = 0.0
	
	return vectorized

## Computes and returns the flattened observation array for the agent kart.
## [br]
## Returns a [PackedFloat32Array] containing 42 normalized feature elements, 
## structured into the following observation groups:
## [br]
## [b]Speed & Physics (Indices 0–2)[/b]
## • [code][0,1][/code]: Relative speed vector
## [br]
## [b]Airborne & Car State (Indices 3–8)[/b]
## • [code][2,3][/code]: Current and previous jump height 
## • [code][4][/code]: Is jumping flag 
## • [code][5,6][/code]: Bs and its direction flags
## • [code][7,8][/code]: Bsx flag and its magnitude
## [br]
## [b]Surface Properties (Indices 9–15)[/b]
## • [code][9][/code]: Is at ice flag
## • [code][10][/code]: Friction (how close car is to bs)
## [br]
## [b]Status & Power-Ups (Indices 11–42)[/b]
## • [code][11..26][/code]: Currently active props, and its duration. Nominally: 
## [br]
## • [b]Sleep[/b] [code][11,12][/code], [b]Boost[/b] [code][13,14][/code], [b]Star[/b] [code][15,16][/code], 
## [b]Shield[/b] [code][17,18][/code], [b]Small state[/b] [code][19,20][/code], 
## [b]Ice trail[/b] [code][21,22][/code], [b]Bone[/b] [code][23,24][/code], [b]Bone position[/b],
## relative to the car, expressed in sin,cos [code][25,26][/code]
## [br]
## • [code][27][/code]: Can use prop flag
## [br]
## [b]One hot encoding of all possible props (Indices 28-41)[/b]
## @return PackedFloat32Array containing 33 flattened float features.
func _get_internal_state(car_inst:Car)->PackedFloat32Array:
	var vectorized:=PackedFloat32Array()
	vectorized.resize(42)
	var speed:=_speed_to_relative(car_inst.speed)
	vectorized[0]=speed.x/max_speed[0]
	# moving backwards
	if speed.y>0:
		vectorized[1]=-speed.y/max_speed_reverse
	# moving forward
	else:
		vectorized[1]=-speed.y/max_speed[0]
	vectorized[2]=car_inst.jumpCurrheight/max_jump_height
	vectorized[3]=(car_inst.jumpPrevheight/max_jump_height)
	# STATUS FLAGS
	# is jumping flag
	if car_inst.jumpCurrheight>1:
		vectorized[4]=1.0
	else:
		vectorized[4]=0.0
		
	if car_inst.bs:
		vectorized[5]=1.0
		vectorized[6]=1.0 if car_inst.bsf else -1.0
	else:
		vectorized[5]=0.0
		vectorized[6]=0.0
	if car_inst.bsex>0:
		vectorized[7]=1.0
		vectorized[8]=car_inst.bsex/100.0
	else:
		vectorized[7]=0.0
		vectorized[8]=0.0
	if car_inst.isAtIce:
		vectorized[9]=1.0
	else:
		vectorized[9]=0.0
	# car friction
	vectorized[10]=car_inst.friction/90
	# sleep
	_process_prop(vectorized,11,car_inst.player.prop.get_prop_by_type(2))
	# boost
	_process_prop(vectorized,13,car_inst.player.prop.get_prop_by_type(8))
	# invincibility star
	_process_prop(vectorized,15,car_inst.player.prop.get_prop_by_type(1))
	# shield
	_process_prop(vectorized,17,car_inst.player.prop.get_prop_by_type(3))
	# laser small state
	_process_prop(vectorized,19,car_inst.player.prop.get_prop_by_type(10))
	# ice trail state
	_process_prop(vectorized,21,car_inst.player.prop.get_prop_by_type(12))
	# bone state
	if _process_prop(vectorized,23,car_inst.player.prop.get_prop_by_type(11)):
		#give bone rotation
		vectorized[25]=sin(car_inst.prop_effector.bone_wrapper.rotation)
		vectorized[26]=cos(car_inst.prop_effector.bone_wrapper.rotation)
	else:
		vectorized[25]=0.0
		vectorized[26]=0.0
	
	
	# can use prop flag
	vectorized[27]=1.0 if car_inst.player.can_use_prop_check() else 0.0
	# vectorized 28 - 41: which prop am i holding?
	# 14 available props: 8 base props + 6 special props (1 for each char)
	# is it faster to change values individually, or create an array of 0s?
	var id:int=car_inst.NowPorpId
	# if special prop: add character id, to map special to the correct char
	if id!=0:
		if id==9:
			id+=car_inst.CharID-1
		vectorized[27+id]=1.0
	
	return vectorized


## Computes and returns the flattened observation array for all events
## in map.
## [br]
## Returns a [PackedFloat32Array] containing 104 normalized feature elements, 
## structured into the following observation groups:
## [br]
## [b]Static hazards (Indices 0–39)[/b]
## [br]
## [b]Missiles (Indices 40-67)[/b]
## [br]
## [b]Furballs (Indices 68-85)[/b]
## [br]
## [b]Ice trail (Indices 86-96)[/b]
## [br]
## [b]Prop boxes (Indices 97-121)[/b]
## [br]
## [b] Jump and Speed Pads (Indices 122-141)[/b]
## @return PackedFloat32Array containing flattened float features.
func _get_hazards_state()->PackedFloat32Array:
	var vectorized:=PackedFloat32Array()
	vectorized.resize(150)
	var offset:=0
	_get_static_hazards(vectorized,offset)
	offset+=40
	_get_missiles(vectorized,offset)
	offset+=28
	_get_furballs(vectorized,offset)
	offset+=18
	_get_icetrail(vectorized,offset)
	offset+=11
	_get_prop_boxes(vectorized,offset)
	offset+=25
	_get_map_pads(vectorized,offset)
	offset+=28
	return vectorized


## Computes and returns the flattened observation array for missiles  
## in the map (blue and red).
## [br]
## For each missile: [code]0[/code]: present or not ([code]1/0[/code]),
## [code]1,2[/code]: normalised distance to agent (x,y), 
## [code]3,4[/code]: scalar distance and closing speed, 
## relative to the aimed player
## [code]5[/code]: is targeting me flag, 
## [br]
## [code]6[/code]: which player the missile is aimed at, as 
## a difference between orderid of the agent and the aimed car
## [br]
## Takes a [PackedFloat32Array] as input, 
## to which it will write [code]7 * buffer_size (2+2)[/code]
## the values, starting from an offset position
func _get_missiles(vectorized:PackedFloat32Array,offset:int)->void:
	for group:String in ['missile','missile_kn']:
		var missiles:=_get_nearest_in_group(
			group,2
		)
		for i in range(2):
			if i<missiles.size():
				var missile:MissileInMap=missiles[i] as MissileInMap
				# missile is present
				vectorized[offset]=1.0
				var relative_coords:=_position_to_relative(missile.global_position)
				vectorized[offset+1]=_normalize_dist(
						relative_coords[0],static_hazard_detection_range,0,true
						)
				vectorized[offset+2]=_normalize_dist(
						relative_coords[1],static_hazard_detection_range,0,true
						)

				# for missile, only closing speed is relevant (impossible to dodge)
				var target_car :Car= GameData.PlayersArr[(missile.AimPlayer.PlayerID)].car
				var target_relative_pos := target_car.global_position - missile.global_position
				var target_relative_vel := missile.speed - target_car.speed
				var closing_speed_to_target :=0.0
				vectorized[offset+3]=_normalize_dist(
						target_relative_pos.length(),static_hazard_detection_range,
						0,true
						)

				var target_dist := target_relative_pos.length()
				if target_dist > 0.0001:
					var dir_to_hazard := target_relative_pos / target_dist
					closing_speed_to_target = target_relative_vel.dot(dir_to_hazard)
					vectorized[offset+4] = clamp(
							closing_speed_to_target / max_speed[1], -1.0, 1.0
							)
				else:
					vectorized[offset+4] = 0.0
				# is it targeting me
				if missile.AimPlayer.PlayerID==car.playerID:
					vectorized[offset+5]=1.0
				else:
					vectorized[offset+5]=0.0
				# which player is it targeting
				# always consider 4 racers
				vectorized[offset+6]=(
					float(missile.AimPlayer.OrderId - car.player.OrderId)/(3))
			else:
				vectorized[offset+0]=0.0
				vectorized[offset+1]=0.0
				vectorized[offset+2]=0.0
				vectorized[offset+3]=0.0
				vectorized[offset+4]=0.0
				vectorized[offset+5]=0.0
				vectorized[offset+6]=0.0
			offset+=7


## Computes and returns the flattened observation array for prop boxes  
## in the map.
## [br]
## For each propbox: [code]0[/code]: present or not ([code]1/0[/code]),
## [code]1,2[/code]: normalised distance to agent (x,y), 
## [code]3[/code]: is active flag, 
## [code]4[/code]: how long until is active (0: just got inactive, 
## 1: will be active soon)
## [br]
## Takes a [PackedFloat32Array] as input, 
## to which it will write [code]5 * buffer_size[/code] 
## values, starting from an offset position
func _get_prop_boxes(vectorized:PackedFloat32Array,offset:int)->void:
	var boxes:=_get_nearest_in_group('propbox',prop_box_buffer_length)
	for instance:Node in boxes:
		var box:=instance as PropInMap
		# is present flag
		vectorized[offset]=1.0
		var relative_coords:=_position_to_relative(box.global_position)
		
		vectorized[offset+1]=_normalize_dist(
				relative_coords[0],static_hazard_detection_range,0,true
				)
		vectorized[offset+2]=_normalize_dist(
				relative_coords[1],static_hazard_detection_range,0,true
				)
		if box.IsActivated:
			vectorized[offset+3]=1.0
			vectorized[offset+4]=1.0
		else:
			vectorized[offset+3]=0.0
			vectorized[offset+4]=1-clampf(float(
				box.hide_tick-NetworkTime.tick
				)/box.respawn_ticks,0,1)
		offset+=5

## Computes and returns the flattened observation array for pads   
## in the map (speed pad, jump pad). Two different buffers of size 2 each.
## [br]
## For each pad: [code]0[/code]: present or not ([code]1/0[/code]),
## [code]1,2[/code]: normalised distance to agent (x,y), 
## [code]3,4[/code]: scalar distance, closing speed 
## [code]5,6[/code]: sin, cos of angle relative to agent orientation 
## [br]
## Takes a [PackedFloat32Array] as input, 
## to which it will write [code]7 * buffer_size(4)[/code] 
## values, starting from an offset position
func _get_map_pads(vectorized:PackedFloat32Array,offset:int)->void:
	for group:String in ['speed_pad','jump_pad']:
		var instances:=_get_nearest_in_group(group,2)
		for i in range(2):
			if i<instances.size():
				var pad:=instances[i] as Node2D
				# is present flag
				vectorized[offset]=1.0
				var relative_coords:=_position_to_relative(pad.global_position)
				vectorized[offset+1]=_normalize_dist(
						relative_coords[0],static_hazard_detection_range,0,true
						)
				vectorized[offset+2]=_normalize_dist(
						relative_coords[1],static_hazard_detection_range,0,true
						)
				vectorized[offset+3]=_normalize_dist(
					relative_coords.length(),static_hazard_detection_range,
					0,true
					)
				var ego_approach_speed := 0.0
				var speed:=car.speed

				var dist_len := relative_coords.length()
				if dist_len > 0.0001:
					var dir_to_hazard := relative_coords / dist_len
					var ego_relative_speed := _speed_to_relative(car.speed)
					#closing speed
					ego_approach_speed = ego_relative_speed.dot(dir_to_hazard)
					vectorized[offset+4] = clamp(
							ego_approach_speed / max_speed[1], -1.0, 1.0
							)
				# angle
				var relative_rotation := wrapf(
					pad.global_rotation - global_rotation, -PI, PI
					)
				vectorized[offset+5] = sin(relative_rotation)
				vectorized[offset+6] = cos(relative_rotation)
			else:
				# pad slot with default zeros if fewer than 2 pads exist
				vectorized[offset] = 0.0 
				vectorized[offset+1] = 0.0
				vectorized[offset+2] = 0.0
				vectorized[offset+3] = 0.0
				vectorized[offset+4] = 0.0
				vectorized[offset+5] = 0.0
				vectorized[offset+6] = 0.0
			offset+=7

## Computes and returns the flattened observation array for furballs  
## hazards in the map.
## [br]
## For each hazard: [code]0[/code]: present or not ([code]1/0[/code]),
## [code]1,2[/code]: normalised distance to agent (x,y), 
## [code]3,4,5[/code]: scalar distance and speed (lateral, perpendicular)
## [br]
## Takes a [PackedFloat32Array] as input, 
## to which it will write [code]6 * 3[/code]
## values, starting from an offset position
func _get_furballs(vectorized:PackedFloat32Array,offset:int)->void:
	var hazards:=_get_nearest_in_group(
			'furball',3
		)
	for hazard in hazards:
		# prop is present
		vectorized[offset]=1.0
		var relative_coords:=_position_to_relative(hazard.global_position)
		vectorized[offset+1]=_normalize_dist(
				relative_coords[0],static_hazard_detection_range,0,true
				)
		vectorized[offset+2]=_normalize_dist(
				relative_coords[1],static_hazard_detection_range,0,true
				)
		vectorized[offset+3]=_normalize_dist(
				relative_coords.length(),static_hazard_detection_range,
				0,true
				)
		var target_relative_pos := car.global_position - hazard.global_position
		var target_relative_vel := (hazard as FurballsInMap).speed - car.speed
		var target_lateral_vel := 0.0
		var closing_speed_to_target :=0.0
		vectorized[offset+3]=_normalize_dist(
				target_relative_pos.length(),static_hazard_detection_range,
				0,true
				)

		var target_dist := target_relative_pos.length()
		if target_dist > 0.0001:
			var dir_to_hazard := target_relative_pos / target_dist
			var perp_dir := Vector2(-dir_to_hazard.y, dir_to_hazard.x)
			closing_speed_to_target = target_relative_vel.dot(dir_to_hazard)
			target_lateral_vel = target_relative_vel.dot(perp_dir)
			vectorized[offset+4] = clamp(
					closing_speed_to_target / max_speed[1], -1.0, 1.0
					)
			vectorized[offset+5] = clamp(
					target_lateral_vel / max_speed[1], -1.0, 1.0
					) 
		else:
			vectorized[offset+4] = 0.0
			vectorized[offset+5] = 0.0
		
		offset+=6
	

## Computes and returns the flattened observation array for icetrail   
## in the map.
## [br]
## For the icetrail: [code]0[/code]: present or not ([code]1/0[/code]),
## [code]1,2,3,4,5,6,7,8,9[/code]: normalised (x,y) and scalar
## distance to agent for each point (start, mid, end) 
## [br]
## [code]10[/code]: how much time left for it to disappear 
## (1: maximum time, 0: about to disappear)
## [br]
## Takes a [PackedFloat32Array] as input, 
## to which it will write [code]11[/code]
## values, starting from an offset position
func _get_icetrail(vectorized:PackedFloat32Array,offset:int)->void:
	var icetrails:=_get_nearest_in_group(
			'icetrail',1
		)
	for prop in icetrails:
		var icetrail:=prop as IceTrailInMap
		# prop is present
		vectorized[offset]=1.0
		var points:=icetrail.get_trail_points()
		for point in points:
			var relative_coords:=_position_to_relative(point)
			vectorized[offset+1]=_normalize_dist(
					relative_coords[0],static_hazard_detection_range,0,true
					)
			vectorized[offset+2]=_normalize_dist(
					relative_coords[1],static_hazard_detection_range,0,true
					)
			vectorized[offset+3]=_normalize_dist(
					relative_coords.length(),static_hazard_detection_range,
					0,true
					)
			offset+=3
		# remaining duration
		vectorized[offset+1]=float(
				icetrail.fadetick-NetworkTime.tick
				)/icetrail.lifetime

## Computes and returns the flattened observation array for static 
## hazards in the map (bs, mines, honey bombs).
## [br]
## For each hazard: [code]0[/code]: present or not ([code]1/0[/code]),
## [code]1,2[/code]: normalised distance to agent (x,y), 
## [code]3,4,5[/code]: scalar distance and speed (lateral, perpendicular), 
## [code]6,7,8[/code]: type (bs,mine,honey mine), 
## [br]
## [code]9[/code]: duration (1:full, 0:disappearing), mines are always 1 
## [br]
## Takes a [PackedFloat32Array] as input, 
## to which it will write [code]10 * buffer_size[/code]
## the values, starting from an offset position
func _get_static_hazards(vectorized:PackedFloat32Array,offset:int)->void:
	# TODO: optionally give isactive as flag
	var hazards:=_get_nearest_in_group(
			'static_hazard',static_hazard_buffer_length
		)
	for hazard in hazards:
		# prop is present
		vectorized[offset]=1.0
		var relative_coords:=_position_to_relative(hazard.global_position)
		vectorized[offset+1]=_normalize_dist(
				relative_coords[0],static_hazard_detection_range,0,true
				)
		vectorized[offset+2]=_normalize_dist(
				relative_coords[1],static_hazard_detection_range,0,true
				)
		vectorized[offset+3]=_normalize_dist(
				relative_coords.length(),static_hazard_detection_range,
				0,true
				)
		# saturated
		if (abs(relative_coords.x) > car_detection_range or 
				abs(relative_coords.y) > car_detection_range):
			vectorized[offset+3]=0.0
		var ego_approach_speed := 0.0
		var ego_lateral_speed := 0.0
		var speed:=car.speed

		var dist_len := relative_coords.length()
		if dist_len > 0.0001:
			var dir_to_hazard := relative_coords / dist_len
			var perp_dir := Vector2(-dir_to_hazard.y, dir_to_hazard.x)

			var ego_relative_speed := _speed_to_relative(car.speed)
			#closing speed
			ego_approach_speed = ego_relative_speed.dot(dir_to_hazard)
			ego_lateral_speed = ego_relative_speed.dot(perp_dir)
			vectorized[offset+4] = clamp(
					ego_approach_speed / max_speed[1], -1.0, 1.0
					)
			vectorized[offset+5] = clamp(
					ego_lateral_speed / max_speed[1], -1.0, 1.0
					) 
		else:
			vectorized[offset+4] = 0.0
			vectorized[offset+5] = 0.0
		if hazard.is_in_group('bs'):
			vectorized[offset+6]=1.0
			var bs:=hazard as BsInMap
			if bs.lifetimeticks!=0:
				vectorized[offset+9]=1-wrapf(
					(float(bs.currtick)/bs.lifetimeticks),0,1)
			else:
				vectorized[offset+9]=1
		elif hazard.is_in_group('mine'):
			vectorized[offset+7]=1.0
			vectorized[offset+9]=1
		elif hazard.is_in_group('honeymine'):
			vectorized[offset+8]=1.0
			vectorized[offset+9]=1
			
		offset+=10

## convert global speed to relative speed
func _speed_to_relative(speed:Vector2)->Vector2:
	return speed.rotated(-car.rotation)
	
## convert global position to relative position
func _position_to_relative(pos:Vector2)->Vector2:
	return (pos-car.global_position).rotated(-car.rotation)

func _process_prop(vectorized:PackedFloat32Array, offset:int, prop:Prop)->bool:
	if prop!=null:
		# flag
		vectorized[offset]=1.0
		# time until reset
		vectorized[offset+1]=(float(prop.tick_end-NetworkTime.tick)/
				NetworkTime.seconds_to_ticks(prop.use_time))
		return true
	else:
		# reset flag
		vectorized[offset]=0.0
		vectorized[offset+1]=0.0
		return false

## Finds the [code]n[/code] nearest nodes in the given [code]group[/code],
## and returns them sorted by the closest.
func _get_nearest_in_group(group: String, n: int) -> Array[Node2D]:
	var best_dist := PackedFloat32Array()
	var best_node: Array[Node2D] = []
	best_dist.resize(n)
	best_node.resize(n)
	for i in n:
		best_dist[i] = INF
		best_node[i] = null

	var origin := car.global_position
	for h in get_tree().get_nodes_in_group(group):
		var d := origin.distance_squared_to((h as Node2D).global_position)
		if d >= best_dist[n - 1]:
			continue
		var idx := n - 1
		while idx > 0 and best_dist[idx - 1] > d:
			best_dist[idx] = best_dist[idx - 1]
			best_node[idx] = best_node[idx - 1]
			idx -= 1
		best_dist[idx] = d
		best_node[idx] = h
	return best_node.filter(func(node:Node)->bool: return node != null)

#endregion

#region debug
func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 12
	if debug_rays_flag:
		for i in range(0, sensor_output.size(), 5):
			var is_colliding: float = sensor_output[i]
			var hit_distance: float = sensor_output[i + 1]
			var ray_length: float = sensor_output[i + 2]
			var collision_type: float = sensor_output[i + 3]
			var ray_angle: float = sensor_output[i + 4]-90
			var processed_distance:float=0.0

			var dir: Vector2 = Vector2.RIGHT.rotated(
						car.global_rotation + deg_to_rad(ray_angle)
						)
			
			var end_point: Vector2
			var text_val: String
			var line_color: Color
			
			if is_colliding < 0.5:
				if collision_type >= 0.5:
					# skip non-colliding jumpwalls
					continue
				end_point = car.position + dir * ray_length
				line_color = debug_empty_color
				text_val = ''
			else:
				end_point = car.position + dir * hit_distance
				line_color = debug_jumpwall_color if collision_type >= 0.5 else debug_wall_color
				#text_val = "%.1f" % (hit_distance/ray_length)
				processed_distance=_normalize_raycast(
							hit_distance,ray_length,raycast_sensors_offset,true,true
							)
				text_val = "%.2f" % (processed_distance)
				
			# Draw the ray line
			draw_line(car.position, end_point, line_color, debug_ray_width)
			
			var text_position: Vector2 = end_point + dir * 8.0
			draw_string(font, text_position, text_val, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, line_color)
	
	if debug_stats_flag:
		var text_position: Vector2 = car.position+Vector2(5,-25)
		var text_val:String
		car_state=_get_opponent_state(car)
		var indexes:=[]
		for i:int in indexes:
			text_val = "%.1f" % (car_state[i])
			draw_string(
					font, text_position, text_val, 
					HORIZONTAL_ALIGNMENT_CENTER, -1, font_size,
					Color.BLUE
					)
			text_position+=Vector2(0,-15)
			
			
	if debug_opponent_flag:
		for player:Player in GameData.PlayersArr:
			if player.car==car:
				continue
			# draw rectangle
			car_state=_get_opponent_state(player.car)
			# x and y distance
			var raw_x: float = _denormalize_dist(
				car_state[30], car_detection_range, car_detection_offset, true
				)
			var raw_y: float = _denormalize_dist(
				car_state[31], car_detection_range, car_detection_offset, true
				)
			var dist:=Vector2(raw_x,raw_y).rotated(car.rotation)
			var rect_pos: Vector2 = car.position + dist - Vector2(25, 25)
			var rect: Rect2 = Rect2(rect_pos, Vector2(50, 50))
			draw_rect(rect, Color.GOLD, false, 2.0)
			# draw arrow
			# x and y velocity
			#var vel:=Vector2(
				#car_state[0],-car_state[1]).rotated(car.rotation
				#)*max_speed[1]*15
			#_draw_arrow(
				#car.position+dist,car.position+dist+vel,Color.CRIMSON
			#)
			# draw string
			var text_pos: Vector2 = Vector2(rect_pos.x, rect_pos.y - 8)
			draw_string(
				font, text_pos, "Opponent", HORIZONTAL_ALIGNMENT_LEFT, 
				-1, font_size, Color.BLACK
				)
	
	if debug_map_events_flag:
		_draw_map_events(font)
	
	var jump_pads: Array[Node2D] = []
	jump_pads.assign(get_tree().get_nodes_in_group("jump_pad"))
	#for pad in jump_pads:
		#var pad_center: Vector2 = to_local(pad.global_position)
#
		## move canvas origin to the pad center and apply pad's rotation
		#draw_set_transform(pad_center, pad.global_rotation, Vector2.ONE)
#
		## draw a 100x100 box centered at (0, 0) relative to the new canvas origin
		#var local_rect: Rect2 = Rect2(Vector2(-50, -50), Vector2(100, 100))
		#draw_rect(local_rect, Color.AQUAMARINE, false, 2.0)
		#
		#draw_set_transform(pad_center, pad.global_rotation-3.14/2, Vector2.ONE)
		#draw_string(
			#font, Vector2(-50, -58), "Jump Pad", HORIZONTAL_ALIGNMENT_LEFT, 
			#-1, font_size, Color.BLACK
			#)
		## reset transform so other draw calls aren't affected
		#draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

		
			
func _draw_map_events(font:Font)->void:
	_draw_hazard_detection_range()
	var vectorized:=_get_hazards_state()
	_draw_static_hazards(vectorized,0,font)
	_draw_missiles(vectorized,40,font)
	_draw_furballs(vectorized,68,font)
	_draw_icetrail(vectorized,86,font)
	_draw_prop_boxes(vectorized,97,font)
	_draw_pads(vectorized,122,font)


func _draw_hazard_detection_range()->void:
	draw_set_transform(car.position, 0, Vector2.ONE)
	draw_circle(
		Vector2.ZERO,static_hazard_detection_range,Color.CADET_BLUE,false,10
		)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	
func _draw_static_hazards(vectorized:PackedFloat32Array,offset:int,font:Font)->void:
	for i in range(offset,offset+(10*static_hazard_buffer_length),10):
		#if prop is present
		if vectorized[i]>0.5:
			var pos:=Vector2(
				_denormalize_dist(
					vectorized[i+1],static_hazard_detection_range,0,true
					),
				_denormalize_dist(
					vectorized[i+2],static_hazard_detection_range,0,true
					),
				).rotated(car.rotation)#+car.global_position
			draw_set_transform(pos+car.position, 0, Vector2.ONE)
			# draw a 100x100 box centered at (0, 0) relative to the new canvas origin
			var local_rect: Rect2 = Rect2(Vector2(-35, -35), Vector2(70, 70))
			draw_rect(local_rect, Color.AQUAMARINE, false, 2.0)
			# get name of hazard
			var label:=_get_hazard_name(vectorized,i)
			# draw label
			draw_string(
				font, Vector2(-35, -40), label, HORIZONTAL_ALIGNMENT_LEFT, 
				-1, 12, Color.BLACK
				)
			draw_string(
				font, Vector2(0, -38), 
				"%0.1f, %0.1f, %0.1f" % [
					vectorized[i+4], vectorized[i+5], vectorized[i+9],
					], 
				HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.BLACK
			)

			# reset transform so other draw calls aren't affected
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_missiles(vectorized:PackedFloat32Array,offset:int,font:Font)->void:
	for i in range(offset,offset+28,7):
		#if prop is present
		if vectorized[i]>0.5:
			var pos:=Vector2(
				_denormalize_dist(
					vectorized[i+1],static_hazard_detection_range,0,true
					),
				_denormalize_dist(
					vectorized[i+2],static_hazard_detection_range,0,true
					),
				).rotated(car.rotation)#+car.global_position
			draw_set_transform(pos+car.position, 0, Vector2.ONE)
			var color:=Color.DARK_GREEN
			if vectorized[i+5]>0.5:
				color=Color.ORANGE_RED
			# draw a 100x100 box centered at (0, 0) relative to the new canvas origin
			var local_rect: Rect2 = Rect2(Vector2(-50, -50), Vector2(100, 100))
			draw_rect(local_rect, color, false, 2.0)
			draw_string(
				font, Vector2(-25, -56), "Missile %0.1f" % vectorized[i+6], 
				HORIZONTAL_ALIGNMENT_LEFT, 
				-1, 12, Color.BLACK
				)
			# reset transform so other draw calls aren't affected
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_prop_boxes(vectorized:PackedFloat32Array,offset:int,font:Font)->void:
	for i in range(offset,offset+25,5):
		#if prop is present
		if vectorized[i]>0.5:
			var pos:=Vector2(
				_denormalize_dist(
					vectorized[i+1],static_hazard_detection_range,0,true
					),
				_denormalize_dist(
					vectorized[i+2],static_hazard_detection_range,0,true
					),
				).rotated(car.rotation)#+car.global_position
			draw_set_transform(pos+car.position, 0, Vector2.ONE)
			# draw a 100x100 box centered at (0, 0) relative to the new canvas origin
			var local_rect: Rect2 = Rect2(Vector2(-25, -25), Vector2(50, 50))
			draw_rect(local_rect, Color.AQUAMARINE, false, 2.0)
			draw_string(
				font, Vector2(-25, -28), "Propbox", HORIZONTAL_ALIGNMENT_LEFT, 
				-1, 6, Color.BLACK
				)
			draw_string(
				font, Vector2(0, -28), "%0.1f" % vectorized[i+3], HORIZONTAL_ALIGNMENT_LEFT, 
				-1, 6, Color.BLACK
			)
			draw_string(
				font, Vector2(17, -28), "%0.1f" % vectorized[i+4], HORIZONTAL_ALIGNMENT_LEFT, 
				-1, 6, Color.BLACK
			)
			# reset transform so other draw calls aren't affected
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_furballs(vectorized:PackedFloat32Array,offset:int,font:Font)->void:
	pass

func _draw_icetrail(vectorized:PackedFloat32Array,offset:int,font:Font)->void:
	pass

func _draw_pads(vectorized:PackedFloat32Array,offset:int,font:Font)->void:
	# swap between speed and jump pad
	var index:=0
	for i in range(offset,offset+28,7):
		#if prop is present
		if vectorized[i]>0.5:
			var pos:=Vector2(
				_denormalize_dist(
					vectorized[i+1],static_hazard_detection_range,0,true
					),
				_denormalize_dist(
					vectorized[i+2],static_hazard_detection_range,0,true
					),
				).rotated(car.rotation)#+car.global_position
			var angle_radians := atan2(vectorized[i+5], vectorized[i+6])
			draw_set_transform(
				pos+car.global_position, angle_radians-3.14/2, 
				Vector2.ONE
				)
			# draw a 100x100 box centered at (0, 0) relative to the new canvas origin
			var local_rect: Rect2 = Rect2(Vector2(-50, -50), Vector2(100, 100))
			draw_rect(local_rect, Color.AQUAMARINE, false, 2.0)
			var label:='Speed pad'
			if index>=14:
				label='Jump pad'
			draw_string(
				font, Vector2(-20, -56), label, HORIZONTAL_ALIGNMENT_LEFT, 
				-1, 12, Color.BLACK
				)
			# reset transform so other draw calls aren't affected
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		index+=7

func _draw_arrow(start: Vector2, end: Vector2, color: Color, width: float = 2.0) -> void:
	# Main vector line
	draw_line(start, end, color, width)
	
	# Arrowhead geometry
	var dir: Vector2 = (end - start).normalized()
	var arrowhead_size: float = 8.0
	var left_wing: Vector2 = end - dir.rotated(deg_to_rad(30)) * arrowhead_size
	var right_wing: Vector2 = end - dir.rotated(deg_to_rad(-30)) * arrowhead_size
	
	draw_line(end, left_wing, color, width)
	draw_line(end, right_wing, color, width)


func _denormalize_dist(norm_val: float, max_dist: float, offset: int, zero_range: bool, inverse: bool = true) -> float:
	if zero_range:
		var sign_factor: float = signf(norm_val)
		if sign_factor == 0.0:
			sign_factor = 1.0
		var magnitude: float = absf(norm_val)
		
		# reverse the inverse flag
		var log_0_to_1: float = (1.0 - magnitude) if inverse else magnitude
		
		# reverse log compression using exponentiation: e^(log_0_to_1 * ln(1 + max_dist)) - 1
		var clamped_dist: float = exp(log_0_to_1 * log(1.0 + max_dist)) - 1.0
		
		# reverse offset and restore sign
		var dist: float = (clamped_dist + offset) * sign_factor
		return dist
	else:
		# remap [-1.0, 1.0] back to [0.0, 1.0]
		var log_0_to_1: float = (norm_val + 1.0) / 2.0
		
		# reverse log compression
		var clamped_dist: float = exp(log_0_to_1 * log(1.0 + max_dist)) - 1.0
		
		# reverse offset
		var dist: float = clamped_dist + offset
		return dist

func _get_hazard_name(vectorized:PackedFloat32Array,offset:int)->String:
	if vectorized[offset+6]>0.5:
		return 'Bs'
	elif vectorized[offset+7]>0.5:
		return 'Mine'
	elif vectorized[offset+8]>0.5:
		return 'HMine'
	else:
		return 'ERROR'

#endregion
