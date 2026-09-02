extends Node2D
class_name IceTrailInMap

@onready var area_2d: Area2D = $Area2D

# CanvasGroup merges all child alpha into one flat silhouette before applying
# a single group-level transparency, so overlapping patches never double-blend
# into visible seams at the joints.
var visuals: CanvasGroup

var car: Car
var rng := RandomNumberGenerator.new()

# --- timing -----------------------------------------------------------
var usetime: int = NetworkTime.seconds_to_ticks(2.0)
var lifetime: int = NetworkTime.seconds_to_ticks(80.0)
var growtick: int
var fadetick: int
var spawntick: int

# --- shape / offsets ----------------------------------------------------
# tested y with 50, tuned to 75
var left: Vector2 = Vector2(-45, 75)
var right: Vector2 = Vector2(45, 75)

# Max ticks between samples when the car is going roughly straight. Bumped
# from 5 - each patch is now a jittered, textured chunk on its own, so you
# don't need as many of them close together to read as "icy". The adaptive
# angle check below still kicks in on sharp turns regardless of this value.
var tickinterval: int = 15
# Force an extra sample as soon as the car has turned this much since the
# last sample, regardless of tickinterval. This is what keeps every segment
# quad "thin" so it can never fold over itself on a sharp turn.
var max_angle_per_segment: float = deg_to_rad(90.0)
var max_substeps: int = 1  # safety cap so a full spin can't spam nodes

var trail_color: Color = Color.WHITE

# --- jitter / texture -----------------------------------------------------
@export var jitter_min: float = 5.0    
@export var jitter_extra: float = 3.0   
@export var joint_jitter: float = 15.0
var trail_texture: Texture2D=preload('res://Assets/Images/maps/map2/images/icetrail.png')

# --- sampling state -------------------------------------------------------
var next_index: int = 0
var last_sample_tick: int = -1
var last_sample_pos: Vector2 = Vector2.ZERO
var last_sample_rot: float = 0.0

var base_left_by_point: Dictionary = {}   # non-jittered -> collision + center
var base_right_by_point: Dictionary = {}
var vis_left_by_point: Dictionary = {}    # jittered -> visuals only
var vis_right_by_point: Dictionary = {}
var center_by_point: Dictionary = {}

var collision_shapes: Dictionary = {}   # point idx -> CollisionPolygon2D
var visual_shapes: Dictionary = {}      # point idx -> Polygon2D (segment quad)
var joint_shapes: Dictionary = {}       # point idx -> Polygon2D (round joint)

var carsintrail: Array[Car] = []


func _ready() -> void:
	area_2d.area_entered.connect(_on_enter)
	area_2d.area_exited.connect(_on_exit)

	visuals = CanvasGroup.new()
	add_child(visuals)
	visuals.self_modulate = trail_color

	spawntick = NetworkTime.tick
	growtick = spawntick + usetime
	fadetick = spawntick + lifetime

	if car:
		global_position = car.global_position + car.transform.y * 70
		last_sample_tick = spawntick
		last_sample_pos = car.global_position
		last_sample_rot = car.rotation
		_add_point(car.global_position, car.rotation)


func _process(_delta: float) -> void:
	var curtick: int = NetworkTime.tick
	if curtick > fadetick:
		queue_free()
		return

	if curtick > growtick:
		return

	if not car:
		return

	var angle_delta: float = abs(angle_difference(car.rotation, last_sample_rot))
	var ticks_since_sample: int = curtick - last_sample_tick

	if ticks_since_sample < tickinterval and angle_delta < max_angle_per_segment:
		return

	# If the car turned a lot, don't add one point that covers the whole
	# turn - add several, each covering only a small slice of the rotation.
	# That's what turns a pinch/cut into a smooth expanding curve.
	var steps: int = max(1, int(ceil(angle_delta / max_angle_per_segment)))
	steps = min(steps, max_substeps)

	var start_pos: Vector2 = last_sample_pos
	var start_rot: float = last_sample_rot
	for s in range(1, steps + 1):
		var t: float = float(s) / float(steps)
		var pos: Vector2 = start_pos.lerp(car.global_position, t)
		var rot: float = lerp_angle(start_rot, car.rotation, t)
		_add_point(pos, rot)

	# Only re-sync the physics server once per frame, not once per sub-step -
	# toggling this multiple times within the same physics tick is what was
	# causing overlaps to get missed.
	area_2d.monitoring = false
	area_2d.monitoring = true

	last_sample_tick = curtick
	last_sample_pos = car.global_position
	last_sample_rot = car.rotation


func _add_point(pos: Vector2, rot: float) -> void:
	var idx: int = next_index
	next_index += 1

	var base_l: Vector2 = pos + left.rotated(rot)
	var base_r: Vector2 = pos + right.rotated(rot)
	var center: Vector2 = base_l.lerp(base_r, 0.5)

	base_left_by_point[idx] = to_local(base_l)
	base_right_by_point[idx] = to_local(base_r)
	center_by_point[idx] = to_local(center)

	rng.seed = spawntick * 1000000 + idx
	var left_jitter: float = abs(rng.randfn(0.0, jitter_extra)) + jitter_min
	var right_jitter: float = abs(rng.randfn(0.0, jitter_extra)) + jitter_min
	var right_axis: Vector2 = Vector2.RIGHT.rotated(rot)
	var fwd_axis: Vector2 = Vector2.UP.rotated(rot)
	# a little jitter along the travel direction too, not just sideways -
	# pure sideways jitter reads as a "wavy ribbon", adding some forward/back
	# noise breaks that up into something more organic/icy.
	var fwd_jitter_l: float = rng.randfn(0.0, jitter_extra * 0.4)
	var fwd_jitter_r: float = rng.randfn(0.0, jitter_extra * 0.4)

	vis_left_by_point[idx] = to_local(base_l - right_axis * left_jitter + fwd_axis * fwd_jitter_l)
	vis_right_by_point[idx] = to_local(base_r + right_axis * right_jitter + fwd_axis * fwd_jitter_r)

	var prev: int = idx - 1
	if base_left_by_point.has(prev):
		_create_segment(prev, idx)
		_create_joint(idx)


func _create_segment(prev: int, curr: int) -> void:
	# Cheap, non-jittered quad for fast collision detection.
	var shape := CollisionPolygon2D.new()
	shape.polygon = PackedVector2Array([
		base_left_by_point[prev], base_left_by_point[curr],
		base_right_by_point[curr], base_right_by_point[prev],
	])
	area_2d.add_child(shape)
	collision_shapes[curr] = shape

	# Independent, jittered quad for visuals. Because it's its own node
	# (not merged into one outline), it can never bowtie with its
	# neighbours - each patch is always a valid, non-self-intersecting quad.
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		vis_left_by_point[prev], vis_left_by_point[curr],
		vis_right_by_point[curr], vis_right_by_point[prev],
	])
	poly.color = Color.WHITE  # actual tint/alpha comes from visuals.self_modulate
	_apply_stamped_texture(poly, poly.polygon)
	visuals.add_child(poly)
	visual_shapes[curr] = poly


func _create_joint(idx: int) -> void:
	# Whatever the segment quad fails to cover on the inside of a sharp
	# turn, this chunk fills in - it's what makes a hard turn look like
	# the patch is *expanding* instead of getting cut. Built the same way
	# as the Flash version's octagon (8 jittered points around a center),
	# but sized off the trail's current half-width instead of a constant.
	var c: Vector2 = center_by_point[idx] + Vector2(
		rng.randf_range(-joint_jitter, joint_jitter),
		rng.randf_range(-joint_jitter, joint_jitter)
	)
	var l: Vector2 = vis_left_by_point[idx]
	var r: Vector2 = vis_right_by_point[idx]
	var half_size: float = max(l.distance_to(c), r.distance_to(c))

	var x_off: float = c.x
	var y_off: float = c.y
	var j: float = half_size * 0.35  # jitter scales with the patch's own size

	var pts := PackedVector2Array([
		Vector2(x_off - half_size + rng.randf_range(0, j), y_off - half_size + rng.randf_range(0, j)),
		Vector2(x_off - half_size + rng.randf_range(0, j), y_off + rng.randf_range(-j * 0.5, j * 0.5)),
		Vector2(x_off - half_size + rng.randf_range(0, j), y_off + half_size - rng.randf_range(0, j)),
		Vector2(x_off + rng.randf_range(-j * 0.5, j * 0.5), y_off + half_size - rng.randf_range(0, j)),
		Vector2(x_off + half_size - rng.randf_range(0, j), y_off + half_size - rng.randf_range(0, j)),
		Vector2(x_off + half_size - rng.randf_range(0, j), y_off + rng.randf_range(-j * 0.5, j * 0.5)),
		Vector2(x_off + half_size - rng.randf_range(0, j), y_off - half_size + rng.randf_range(0, j)),
		Vector2(x_off + rng.randf_range(-j * 0.5, j * 0.5), y_off - half_size + rng.randf_range(0, j)),
	])

	var poly := Polygon2D.new()
	poly.polygon = pts
	poly.color = Color.WHITE
	_apply_stamped_texture(poly, pts)
	visuals.add_child(poly)
	joint_shapes[idx] = poly


func _apply_stamped_texture(poly: Polygon2D, pts: PackedVector2Array) -> void:
	# Maps UVs to each patch's own bounding box, so every patch stamps one
	# full copy of the texture into itself - this is what the Flash version
	# did, and it's the right approach for a single "chunk" icon texture
	# (as opposed to tiling, which assumes a seamless repeating texture).
	if trail_texture == null or pts.size() == 0:
		return
	poly.texture = trail_texture

	var min_x: float = pts[0].x
	var max_x: float = pts[0].x
	var min_y: float = pts[0].y
	var max_y: float = pts[0].y
	for p in pts:
		min_x = min(min_x, p.x)
		max_x = max(max_x, p.x)
		min_y = min(min_y, p.y)
		max_y = max(max_y, p.y)

	var size := Vector2(max(max_x - min_x, 1.0), max(max_y - min_y, 1.0))
	var tex_size: Vector2 = trail_texture.get_size()
	var uvs := PackedVector2Array()
	for p in pts:
		var rel := Vector2((p.x - min_x) / size.x, (p.y - min_y) / size.y)
		uvs.append(rel * tex_size)
	poly.uv = uvs


func Despawn() -> void:
	for shape: CollisionPolygon2D in collision_shapes.values():
		if is_instance_valid(shape):
			shape.disabled = true
	for c in carsintrail:
		if is_instance_valid(c):
			c.OutOfIce()
	carsintrail.clear()


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
