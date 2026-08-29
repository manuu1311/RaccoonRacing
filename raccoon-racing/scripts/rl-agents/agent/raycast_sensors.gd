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

var rays := []


func _update()->void:
	print('updating..')
	if Engine.is_editor_hint():
		print('hinting')
		if debug_draw:
			_spawn_nodes()
		else:
			for ray in get_children():
				if ray is RayCast2D:
					remove_child(ray)


func _ready() -> void:
	_spawn_nodes()


func _spawn_nodes()->void:
	for ray:RayCast2D in rays:
		ray.queue_free()
	rays = []

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



func get_observation() -> Array:
	return self.calculate_raycasts()


func calculate_raycasts() -> PackedFloat32Array:
	var result:= PackedFloat32Array()
	var offset:int
	var max_dist: float
	for i: int in len(rays):
		var ray: RayCast2D = rays[i]
		ray.force_raycast_update()
		offset = i * 4
		max_dist = ray.target_position.length()
		result[offset + 2] = max_dist
		
		if ray.is_colliding():
			var hit_point: Vector2 = ray.get_collision_point()
			var collider: CollisionObject2D = ray.get_collider()
			
			result[offset] = 1.0 # True
			result[offset + 1] = ray.global_position.distance_to(hit_point)
			#normal wall
			if collider.collision_layer==1<<1:
				result[offset + 3] = 0.0
			#jump wall
			else:
				result[offset + 3] = 1.0
		else:
			result[offset] = 0.0 # False
			result[offset + 1] = max_dist
			result[offset + 3] = 0.0
	return result


func _get_raycast_distance(ray: RayCast2D) -> float:
	if !ray.is_colliding():
		return 0.0

	var distance := (global_position - ray.get_collision_point()).length()
	distance = clamp(distance, 0.0, ray_length)
	return (ray_length - distance) / ray_length
