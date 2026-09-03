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
@export var car_detection_offset:=42
## max jump height
@export var max_jump_height:=30.0
@export_group("Debug Settings")
@export var debug_rays_flag:bool=true
@export var debug_wall_color:Color=Color.RED
@export var debug_jumpwall_color:Color=Color.YELLOW
@export var debug_empty_color:Color=Color.GREEN
@export var debug_ray_width:int=2
@export var debug_stats_flag:bool=true
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
	if debug_rays_flag or debug_stats_flag:
		queue_redraw()


#region Observation

func _normalize_dist(dist: float, max_dist: float,offset:int,zero_range:bool, inverse:bool=true) -> float:
	var clamped_dist:float
	var log_0_to_1: float
	if zero_range:
		var sign_factor: float = signf(dist)
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


## Computes and returns the flattened observation array for the kart.
## [br]
## Returns a [PackedFloat32Array] containing 33 normalized feature elements, 
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
## [b]Status & Power-Ups (Indices 11–26)[/b]
## • [code][11..26][/code]: Currently active props, and its duration. Nominally: 
## [br]
## • [b]Sleep[/b] [code][11,12][/code], [b]Boost[/b] [code][13,14][/code], [b]Star[/b] [code][15,16][/code], 
## [b]Shield[/b] [code][17,18][/code], [b]Small state[/b] [code][19,20][/code], 
## [b]Ice trail[/b] [code][21,22][/code], [b]Bone[/b] [code][23,24][/code], [b]Bone position[/b],
## relative to the car, expressed in sin,cos [code][25,26][/code]
## [br]
## • [code][27][/code]: Can use prop flag
## [br]
# [code][28,29][/code] [code][11,12][/code]
## [b]Position relative to agent (Indices 28-32[/b]
## • [code][28,29][/code]: Car relative rotation, expressed as sin,cos
## • [code][30,31][/code]: Car relative position
## • [code][32][/code]: Car at range flag: is car at range? When out of range, 
## the signal is saturated
## @return PackedFloat32Array containing 33 flattened float features.
func _get_opponent_state(car_inst:Car)->PackedFloat32Array:
	var vectorized:=PackedFloat32Array()
	vectorized.resize(33)
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
	var relative_coords : Vector2 = _position_to_relative(car_inst.global_position)
	vectorized[30] = _normalize_dist(
				relative_coords[0],car_detection_range,car_detection_offset,true
	)
	vectorized[31] = _normalize_dist(
				relative_coords[1],car_detection_range,car_detection_offset,true
	)
	# one axis out of range: car not present in range (saturated signal)
	if relative_coords[0]>car_detection_range or relative_coords[1]>car_detection_range:
		vectorized[32]=0.0
	# car present in range
	else:
		vectorized[32]=1.0
	
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
## [b]One hot encoding of all possible props (Indices 28-42[/b]
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


#endregion

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
				text_val = "%.1f" % (processed_distance)
				
			# Draw the ray line
			draw_line(car.position, end_point, line_color, debug_ray_width)
			
			var text_position: Vector2 = end_point + dir * 8.0
			draw_string(font, text_position, text_val, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, line_color)
	
	if debug_stats_flag:
		var text_position: Vector2 = car.position+Vector2(5,-25)
		var text_val:String
		car_state=_get_internal_state(car)
		var indexes:=[23,24,25,26]
		for i:int in indexes:
			text_val = "%.1f" % (car_state[i])
			draw_string(
					font, text_position, text_val, 
					HORIZONTAL_ALIGNMENT_CENTER, -1, font_size,
					Color.BLUE
					)
			text_position+=Vector2(0,-15)
			
			
			
			
			
