extends Node2D
class_name IceTrailInMap

@onready var area_2d: Area2D = $Area2D
@onready var collision_polygon_2d: CollisionPolygon2D = $Area2D/CollisionPolygon2D
@onready var polygon_2d: Polygon2D = $Area2D/Polygon2D
@onready var state_synchronizer: StateSynchronizer = $StateSynchronizer

var car:Car
var poly:PackedVector2Array=PackedVector2Array()
var rng := RandomNumberGenerator.new()
var left_by_slot: Dictionary = {} # slot:int -> Vector2
var right_by_slot: Dictionary = {}
var max_slot: int = -1
var usetime:int=NetworkTime.seconds_to_ticks(2.0)
var lifetime:int=NetworkTime.seconds_to_ticks(6.0)
var left:Vector2=Vector2(-45,50)
var right:Vector2=Vector2(45,50)
var jitterstrength:float=25
var tickinterval:int=2
var growtick:int
var fadetick:int
var spawntick:int
var carsintrail:Array[Car]
var last_point_pos: Vector2 = Vector2.ZERO
var has_last_point: bool = false
var min_forward_progress: float = 4.0 

func _ready() -> void:
	area_2d.area_entered.connect(_on_enter)
	area_2d.area_exited.connect(_on_exit)
	spawntick=NetworkTime.tick
	growtick=spawntick+usetime
	fadetick=spawntick+lifetime
	global_position =car.global_position + car.transform.y * 70
	poly.append(Vector2.ZERO)
	StateSyncSetup()
	


func StateSyncSetup()->void:
	state_synchronizer.add_state(self, "poly")


func _process(_delta: float) -> void:
	var curtick:int=NetworkTime.tick
	if curtick>fadetick:
		queue_free()
	if curtick>growtick:
		return
	if curtick%tickinterval!=0:
		return
	if curtick<growtick:
		add_point()

func add_point() -> void:
	if not car:
		return

	@warning_ignore("integer_division")
	var slot: int = (NetworkTime.tick - spawntick) / tickinterval

	# forward-progress check, keyed off the previous *slot*, not a mutable running var
	if left_by_slot.has(slot - 1):
		var prev_pos: Vector2 = to_global(left_by_slot[slot - 1]).lerp(to_global(right_by_slot[slot - 1]), 0.5)
		var progress: float = (car.global_position - prev_pos).dot(car.transform.y)
		if progress < min_forward_progress:
			return

	var lrsign: int = 1 if slot % 2 == 0 else -1

	rng.seed = spawntick * 100000 + slot

	var left_jitter := rng.randf_range(0.0, jitterstrength) * lrsign
	var right_jitter := rng.randf_range(0.0, jitterstrength) * lrsign

	var left_offset: Vector2 = left + Vector2(left_jitter, 0.0)
	var right_offset: Vector2 = right + Vector2(right_jitter, 0.0)

	left_by_slot[slot] = to_local(car.global_position + left_offset.rotated(car.rotation))
	right_by_slot[slot] = to_local(car.global_position + right_offset.rotated(car.rotation))
	max_slot = max(max_slot, slot)

	_update_polygon()

func _update_polygon() -> void:
	poly = PackedVector2Array()
	poly.append(Vector2.ZERO)
	for s in range(0, max_slot + 1):
		if left_by_slot.has(s):
			poly.append(left_by_slot[s])
	for s in range(max_slot, -1, -1):
		if right_by_slot.has(s):
			poly.append(right_by_slot[s])

	polygon_2d.polygon = poly
	if poly.size() >= 3:
		collision_polygon_2d.polygon = poly


func _on_enter(body: Area2D) -> void:
	if body.is_in_group("Body"):
		var carinst :Car= _get_car_from_body(body)
		if car:
			carsintrail.append(carinst)
			carinst.SetOnIce()

func _on_exit(body: Area2D) -> void:
	var carinst :Car= _get_car_from_body(body)
	if carinst in carsintrail:
		carsintrail.erase(carinst)
		carinst.OutOfIce()

func _get_car_from_body(body: Area2D) -> Car:
	if body and body.get_parent() and body.get_parent().get_parent():
		return body.get_parent().get_parent() as Car
	return null
	
	
func _rollback_spawn() -> void:
	collision_polygon_2d.disabled=false

func _rollback_despawn() -> void:
	collision_polygon_2d.disabled=true
	for c in carsintrail:
		c.OutOfIce()
	carsintrail.clear()
