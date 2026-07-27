extends Node2D
class_name IceTrailInMap

@onready var area_2d: Area2D = $Area2D
@onready var polygon_2d: Polygon2D = $Area2D/Polygon2D
@onready var state_synchronizer: StateSynchronizer = $StateSynchronizer

const MAX_TRAIL_SLOTS = 100
var base_slot: int = 0 
var car: Car
var poly: PackedVector2Array = PackedVector2Array()
var rng := RandomNumberGenerator.new()

var left_by_slot: Dictionary = {}
var right_by_slot: Dictionary = {}
var segment_shapes: Dictionary = {} # Changed from Array to Dictionary

var max_slot: int = -1
var usetime: int = NetworkTime.seconds_to_ticks(2.0)
var lifetime: int = NetworkTime.seconds_to_ticks(8.0)
var left: Vector2 = Vector2(-45, 50)
var right: Vector2 = Vector2(45, 50)
var jitterstrength: float = 20.0
var tickinterval: int = 5
var growtick: int
var fadetick: int
var spawntick: int
var carsintrail: Array[Car] = []
var last_point_pos: Vector2 = Vector2.ZERO
var has_last_point: bool = false
var min_forward_progress: float = 4.0 
var center_by_slot: Dictionary = {}
var half_width: float = 0.0

func _ready() -> void:
	area_2d.area_entered.connect(_on_enter)
	area_2d.area_exited.connect(_on_exit)
	
	spawntick = NetworkTime.tick
	growtick = spawntick + usetime
	fadetick = spawntick + lifetime
	
	if car:
		global_position = car.global_position + car.transform.y * 70
		var start_left: Vector2  = to_local(car.global_position + left.rotated(car.rotation))
		var start_right: Vector2 = to_local(car.global_position + right.rotated(car.rotation))
		left_by_slot[-1]  = start_left
		right_by_slot[-1] = start_right
		max_slot = -1
	if GameData.IsMultiplayer:
		StateSyncSetup()

func StateSyncSetup() -> void:
	if state_synchronizer:
		state_synchronizer.add_state(self, "poly")

func _process(_delta: float) -> void:
	var curtick: int = NetworkTime.tick
	if curtick > fadetick:
		queue_free()
		return
		
	if curtick > growtick:
		return
		
	if curtick % tickinterval != 0:
		return
		
	if curtick < growtick:
		add_point()

func Despawn() -> void:
	for shape: CollisionPolygon2D in segment_shapes.values():
		if is_instance_valid(shape):
			shape.disabled = true
	for c in carsintrail:
		if is_instance_valid(c):
			c.OutOfIce()
	carsintrail.clear()


func add_point() -> void:
	if not car:
		return

	@warning_ignore("integer_division")
	var slot: int = (NetworkTime.tick - spawntick) / tickinterval

	var base_left: Vector2  = car.global_position + left.rotated(car.rotation)
	var base_right: Vector2 = car.global_position + right.rotated(car.rotation)
	var center: Vector2 = base_left.lerp(base_right, 0.5)

	center_by_slot[slot] = center

	# car's local left-right axis, purely rotation-based
	var right_axis: Vector2 = Vector2.RIGHT.rotated(car.rotation)

	rng.seed = spawntick * 100000 + slot
	var left_jitter: float  = abs(rng.randfn(0.0, 18.0)) + 12.0
	var right_jitter: float = abs(rng.randfn(0.0, 18.0)) + 12.0

	left_by_slot[slot]  = to_local(base_left  - right_axis * left_jitter)
	right_by_slot[slot] = to_local(base_right + right_axis * right_jitter)

	max_slot = max(max_slot, slot)

	var prev_slot: int = slot - 1
	if left_by_slot.has(prev_slot) and right_by_slot.has(prev_slot):
		_create_segment(prev_slot, slot)

	_update_visual_polygon()


func _update_visual_polygon() -> void:
	poly = PackedVector2Array()
	var first_slot: int = base_slot - 1

	if not left_by_slot.has(first_slot):
		return

	poly.append(left_by_slot[first_slot])

	for s in range(base_slot, max_slot + 1):
		if left_by_slot.has(s):
			poly.append(left_by_slot[s])

	for s in range(max_slot, base_slot - 1, -1):
		if right_by_slot.has(s):
			poly.append(right_by_slot[s])

	if right_by_slot.has(first_slot):
		poly.append(right_by_slot[first_slot])

	if poly.size() > 0:
		poly.append(poly[0])

	polygon_2d.polygon = poly

func _create_segment(prev_slot: int, curr_slot: int) -> void:
	var points := PackedVector2Array([
		left_by_slot[prev_slot],
		left_by_slot[curr_slot],
		right_by_slot[curr_slot],
		right_by_slot[prev_slot]
	])

	var shape := CollisionPolygon2D.new()
	shape.polygon = points
	area_2d.add_child(shape)
	segment_shapes[curr_slot] = shape
	#recalculate collision
	area_2d.monitoring = false
	area_2d.monitoring = true

func _remove_oldest_slot() -> void:
	var old_slot: int = base_slot
	if segment_shapes.has(old_slot):
		if is_instance_valid(segment_shapes[old_slot]):
			segment_shapes[old_slot].queue_free()
		segment_shapes.erase(old_slot)
		
	if left_by_slot.has(old_slot - 1):
		left_by_slot.erase(old_slot - 1)
		right_by_slot.erase(old_slot - 1)
		
	base_slot += 1

func _on_enter(body: Area2D) -> void:
	if body.is_in_group("Body"):
		var carinst: Car = _get_car_from_body(body)
		if carinst and not carsintrail.has(carinst):
			carsintrail.append(carinst)
			carinst.SetOnIce()

func _on_exit(body: Area2D) -> void:
	var carinst: Car = _get_car_from_body(body)
	if carinst in carsintrail:
		carsintrail.erase(carinst)
		carinst.OutOfIce()

func _get_car_from_body(body: Area2D) -> Car:
	if body and body.get_parent() and body.get_parent().get_parent():
		return body.get_parent().get_parent() as Car
	return null
