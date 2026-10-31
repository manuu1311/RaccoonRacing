extends Player
class_name RLPlayer

var ai_points:Array[Vector2]
var current_point_id:int
var next_point_id:int
var next_point_id_2:int
var point_update_range:int=200
var point_update_range_squared:int

# Called when the node enters the scene tree for the first time.
func _init(id:int,control:control_type) -> void:
	super(id,control)
	point_update_range_squared=point_update_range**2


func SetCar(carinst:Car)->void:
	super(carinst)
	ai_points=car.map.ai_points
	current_point_id=0
	AIPlayer


func UpdatePoint() -> void:
	if !IsPlayering():
		return
	super()
		
	# go to next point
	if (ai_points[current_point_id].distance_squared_to(car.global_position)
				<point_update_range_squared):
		current_point_id=next_point_id
		next_point_id=next_point_id_2
		if next_point_id_2 + 1 < ai_points.size():
			next_point_id_2+=1
		else:
			next_point_id_2=0
		

func RunPropBox(x:float,y:float)->void:
	if hud==null:
		await car.get_tree().create_timer(1.5).timeout
		car.HasProp=true
		car.CanUseProp=true
		var id:int=GetPropPer()
		GetProp(id)
		return
	if not car.playering:
		return
	if hud!=null:
		car.sounds.GetProp()
		if not hud.PropItemReady():
			hud.propmove(x,y)
	if car.NowPorpId!=0:
		return
	GetProp(GetPropPer())
	car.CanUseProp=true
	if hud!=null and car:
		hud.StartPropBox(1.5,car.NowPorpId)
