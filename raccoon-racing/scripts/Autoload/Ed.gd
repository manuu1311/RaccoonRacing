extends Node
class_name Ed

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func AddLine(x1:float,y1:float,x2:float,y2:float)->EdLine:
	return EdLine.new()

func ReTidyFace()->void:
	pass


func getHitFace(point:Vector2)->Vector2:
	return Vector2(NAN,NAN)
