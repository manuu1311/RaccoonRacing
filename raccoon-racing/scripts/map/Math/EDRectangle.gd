extends EdLine
class_name EdRectangle


func _init(x: float, y: float, width: float, height: float, Ang: float = 0.0) -> void:
	var loc3 := Vector2(-width / 2.0, -height / 2.0)
	loc3 = loc3.rotated(deg_to_rad(Ang))
	
	var loc5 := Vector2(x + loc3.x, y + loc3.y)
	
	loc3.x = width / 2.0
	loc3.y = -height / 2.0
	loc3 = loc3.rotated(deg_to_rad(Ang))
	
	var loc4 := Vector2(x + loc3.x, y + loc3.y)
	
	@warning_ignore("narrowing_conversion")
	LineWidth = height
	super(loc4.x, loc4.y, loc5.x, loc5.y)
