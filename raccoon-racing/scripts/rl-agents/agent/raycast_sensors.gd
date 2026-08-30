@tool
extends Node2D
class_name CustomRaycastObs

@export_flags_2d_physics var collision_mask := 1:
	get:
		return collision_mask
	set(value):
		collision_mask = value
		_update()

@export var collide_with_areas := false:
	get:
		return collide_with_areas
	set(value):
		collide_with_areas = value
		_update()

@export var collide_with_bodies := true:
	get:
		return collide_with_bodies
	set(value):
		collide_with_bodies = value
		_update()

@export var rays_angles := [
	0,
	15,30,45,60,75,90,
	105,120,150,
	180,
	-15,-30,-45,-60,-75,-90,
	-105,-120,-150,
	]:
	get:
		return rays_angles
	set(value):
		rays_angles = value
		_update()

@export var rays_jump_angles := [
	0,15,-15
	]:
	get:
		return rays_jump_angles
	set(value):
		rays_jump_angles = value
		_update()

@export_range(5, 3000, 5.0) var ray_length := 200:
	get:
		return ray_length
	set(value):
		ray_length = value
		_update()

@export var ray_angle_threshold := 20:
	get:
		return ray_angle_threshold
	set(value):
		ray_angle_threshold = value
		_update()

@export var debug_draw := true:
	get:
		return debug_draw
	set(value):
		debug_draw = value
		_update()

var rays :Array[RayCast2D]= []
var jump_rays :Array[RayCast2D]= []

var _obs_buffer: PackedFloat32Array
var _wall_count: int
var _jump_count: int

func _update()->void:
	if Engine.is_editor_hint():
		if debug_draw:
			_spawn_nodes()
		else:
			for ray in get_children():
				if ray is RayCast2D:
					remove_child(ray)


func _ready() -> void:
	_spawn_nodes()
	_wall_count = len(rays)
	_jump_count = len(jump_rays)
	_obs_buffer = PackedFloat32Array()
	_obs_buffer.resize((_wall_count + _jump_count) * 5)

	_init_static_fields(rays, rays_angles, 0.0, 0)
	_init_static_fields(jump_rays, rays_jump_angles, 1.0, _wall_count)

# Write the constant parts (max_dist, angle) exactly once.
func _init_static_fields(ray_arr: Array[RayCast2D], angles: PackedFloat32Array, layer:float, base_index: int) -> void:
	for i: int in len(ray_arr):
		var offset: int = (base_index + i) * 5
		_obs_buffer[offset + 2] = ray_arr[i].target_position.length()
		_obs_buffer[offset + 3] = layer
		_obs_buffer[offset + 4] = angles[i]


func _spawn_nodes()->void:
	for ray:RayCast2D in rays:
		ray.queue_free()
	for ray:RayCast2D in jump_rays:
		ray.queue_free()
	rays = []
	jump_rays = []

	for angle:int in rays_angles:
		angle-=90
		var ray: = RayCast2D.new()
		var length:=ray_length
		# double length of rays within 50 degrees forward
		# useful for straights
		if abs(angle+90)<ray_angle_threshold:
			length*=2
		ray.set_target_position(
			Vector2(length * cos(deg_to_rad(angle)), length * sin(deg_to_rad(angle)))
		)
		ray.set_name("node_" + str(len(rays)))
		ray.enabled = false
		ray.collide_with_areas = collide_with_areas
		ray.collide_with_bodies = collide_with_bodies
		ray.collision_mask = collision_mask
		add_child(ray)
		rays.append(ray)
		
	for angle:int in rays_jump_angles:
		angle-=90
		var ray: = RayCast2D.new()
		var length:=ray_length
		# double length of rays within 50 degrees forward
		# useful for straights
		if abs(angle+90)<ray_angle_threshold:
			length*=2
		ray.set_target_position(
			Vector2(length * cos(deg_to_rad(angle)), length * sin(deg_to_rad(angle)))
		)
		ray.set_name("node_" + str(len(rays))+'_jump')
		ray.enabled = false
		ray.collide_with_areas = collide_with_areas
		ray.collide_with_bodies = collide_with_bodies
		ray.collision_mask = 1<<2
		add_child(ray)
		jump_rays.append(ray)


## Computes and returns the flattened array of raycast observations.
## [br]
## [b]Output structure:[/b]
## [br]
## Each ray contributes a block of 5 floats:
## [br]
## - [b]Is Colliding:[/b] 1.0 if colliding, 0.0 otherwise.
## [br]
## - [b]Hit Distance:[/b] Distance to collision point.
## [br]
## - [b]Ray length:[/b] Length of the ray cast.
## [br]
## - [b]Collision Type:[/b] 0.0 for normal walls, 1.0 for jumpable walls.
## [br]
## - [b]Ray angle:[/b] Angle of the ray cast wrt the origin.
## [br]
## Returns a [PackedFloat32Array].
func get_observation() -> PackedFloat32Array:
	return self.calculate_raycasts()


func calculate_raycasts() -> PackedFloat32Array:
	_update_ray_group(rays, 0)
	_update_ray_group(jump_rays, _wall_count)
	return _obs_buffer

func _update_ray_group(ray_arr: Array[RayCast2D], base_index: int) -> void:
	for i: int in len(ray_arr):
		var ray: RayCast2D = ray_arr[i]
		ray.force_raycast_update()
		var offset: int = (base_index + i) * 5

		if ray.is_colliding():
			var hit_point: Vector2 = ray.get_collision_point()
			_obs_buffer[offset] = 1.0
			_obs_buffer[offset + 1] = ray.global_position.distance_to(hit_point)

		else:
			_obs_buffer[offset] = 0.0
			_obs_buffer[offset + 1] = _obs_buffer[offset + 2]


#func _calculate_ray_arrays(ray_arr:Array[RayCast2D],angles:Array[float],layer:float)->PackedFloat32Array:
	#var result:= PackedFloat32Array()
	#result.resize(len(ray_arr)*5)
	#var offset:int
	#var max_dist: float
	#for i: int in (len(ray_arr)):
		#var ray: RayCast2D = ray_arr[i]
		#ray.force_raycast_update()
		#offset = i * 5
		#max_dist = ray.target_position.length()
		#result[offset + 2] = max_dist
		#result[offset+4]=angles[i]
		#
		#if ray.is_colliding():
			#var hit_point: Vector2 = ray.get_collision_point()
			#
			#result[offset] = 1.0 # True
			#result[offset + 1] = ray.global_position.distance_to(hit_point)
			#result[offset + 3] = layer
		#else:
			#result[offset] = 0.0 # False
			#result[offset + 1] = max_dist
			#result[offset + 3] = 0.0
	#return result
