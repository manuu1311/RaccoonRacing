extends Player
class_name RLPlayer

var ai_points:Array[Vector2]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


func SetCar(carinst:Car)->void:
	super(carinst)
	ai_points=car.map.ai_points
	Map
