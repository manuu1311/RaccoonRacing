@tool
extends Polygon2D


func _ready():
	var path := get_parent() as Path2D
	if path:
		polygon = path.curve.get_baked_points()
