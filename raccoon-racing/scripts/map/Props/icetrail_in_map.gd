extends Node2D
class_name IceTrailInMap

@onready var area_2d: Area2D = $Area2D
@onready var collision_polygon_2d: CollisionPolygon2D = $Area2D/CollisionPolygon2D
@onready var polygon_2d: Polygon2D = $Area2D/Polygon2D
@export var lifetime: float = 20.0
@export var radius_x: float = 25.0   
@export var radius_y: float = 50.0   
@export var jitter: float = 7.0


var bodies_on_patch: Array[Area2D] = []

func _ready() -> void:
	_generate_shape()
	area_2d.area_entered.connect(_on_enter)
	area_2d.area_exited.connect(_on_exit)

	await get_tree().create_timer(lifetime).timeout
	for body:Area2D in bodies_on_patch:
		var caropp:Car=body.get_parent().get_parent() as Car
		caropp.OutOfIce()
	queue_free()


func _generate_shape() -> void:
	var verts := PackedVector2Array()
	for i in range(8):
		var angle := i * TAU / 8.0
		var rx := radius_x + randf_range(-jitter, jitter)
		var ry := radius_y + randf_range(-jitter, jitter)
		verts.append(Vector2(cos(angle) * rx, sin(angle) * ry))
	collision_polygon_2d.polygon = verts
	polygon_2d.polygon = verts


func _on_enter(body:Area2D)->void:
	if body.is_in_group("Body"):
		bodies_on_patch.append(body)
		var caropp:Car=body.get_parent().get_parent() as Car
		caropp.SetOnIce()

func _on_exit(body:Area2D)->void:
	if body in bodies_on_patch:
		bodies_on_patch.erase(body)
		var caropp:Car=body.get_parent().get_parent() as Car
		caropp.OutOfIce()
