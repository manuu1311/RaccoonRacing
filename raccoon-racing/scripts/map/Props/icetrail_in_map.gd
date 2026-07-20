extends Node2D
class_name IceTrailInMap

@onready var area_2d: Area2D = $Area2D
@onready var collision_polygon_2d: CollisionPolygon2D = $Area2D/CollisionPolygon2D
@onready var polygon_2d: Polygon2D = $Area2D/Polygon2D

@export var trail_width: float = 90.0
@export var edge_jitter: float = 6.0          # organic wobble, like the random() offsets in the Flash version
@export var min_point_distance: float = 12.0  # only add a new point once car has moved this far
@export var max_points: int = 80              # cap so it doesn't grow forever
@export var fade_lifetime: float = 4.0        # how long the trail lingers once growth stops

var centers: Array[Vector2] = []
var edge_jitters: Array[float] = []           # stored per-point so edges don't re-wobble every rebuild
var bodies_on_patch: Array[Area2D] = []
var growing: bool = true
var _origin_set: bool = false

func _ready() -> void:
	if polygon_2d.color.a == 0:
		polygon_2d.color = Color(0.6, 0.9, 1.0, 0.6)
	area_2d.area_entered.connect(_on_enter)
	area_2d.area_exited.connect(_on_exit)

# Call every frame while the car is drifting/using ice, passing the car's world position.
func add_point(global_pos: Vector2) -> void:
	if not growing:
		return

	if not _origin_set:
		global_position = global_pos
		_origin_set = true
		centers.append(Vector2.ZERO)
		edge_jitters.append(randf_range(-edge_jitter, edge_jitter))
		return

	var local_pos: Vector2 = to_local(global_pos)
	if centers.is_empty() or local_pos.distance_to(centers.back()) >= min_point_distance:
		centers.append(local_pos)
		edge_jitters.append(randf_range(-edge_jitter, edge_jitter))
		if centers.size() > max_points:
			centers.pop_front()
			edge_jitters.pop_front()
		_rebuild_shape()

# Call when the car stops drifting; trail seals up and starts fading out.
func stop_growing() -> void:
	if not growing:
		return
	growing = false
	get_tree().create_timer(fade_lifetime).timeout.connect(_on_fade_timeout)

func _on_fade_timeout() -> void:
	for body: Area2D in bodies_on_patch:
		if is_instance_valid(body):
			var car := _get_car_from_body(body)
			if car:
				car.OutOfIce()
	queue_free()

func _rebuild_shape() -> void:
	if centers.size() < 2:
		return

	var left := PackedVector2Array()
	var right := PackedVector2Array()

	for i in range(centers.size()):
		var dir_in: Vector2 = Vector2.DOWN
		var dir_out: Vector2 = Vector2.DOWN
		if i > 0:
			dir_in = (centers[i] - centers[i - 1]).normalized()
		if i < centers.size() - 1:
			dir_out = (centers[i + 1] - centers[i]).normalized()
		var dir: Vector2 = dir_in + dir_out
		if dir == Vector2.ZERO:
			dir = dir_out
		dir = dir.normalized()

		var normal := Vector2(-dir.y, dir.x)
		var j: float = edge_jitters[i]
		left.append(centers[i] + normal * (trail_width * 0.5 + j))
		right.append(centers[i] - normal * (trail_width * 0.5 + j))

	right.reverse()
	var poly := PackedVector2Array()
	poly.append_array(left)
	poly.append_array(right)

	collision_polygon_2d.polygon = poly
	polygon_2d.polygon = poly

func _on_enter(body: Area2D) -> void:
	if body.is_in_group("Body"):
		bodies_on_patch.append(body)
		var car := _get_car_from_body(body)
		if car:
			car.SetOnIce()

func _on_exit(body: Area2D) -> void:
	if body in bodies_on_patch:
		bodies_on_patch.erase(body)
		var car := _get_car_from_body(body)
		if car:
			car.OutOfIce()

func _get_car_from_body(body: Area2D) -> Car:
	if body and body.get_parent() and body.get_parent().get_parent():
		return body.get_parent().get_parent() as Car
	return null
	
