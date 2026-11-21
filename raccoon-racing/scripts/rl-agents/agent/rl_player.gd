extends Player
class_name RLPlayer

var agent:CarAgent
var ai_points:Array[Vector2]
var current_point_id:int
var next_point_id:int
var next_point_id_2:int
var point_update_range:int=200
var point_update_range_squared:int
var turbo_start_probability:=0.9
signal new_point_reached()
var box_pending := false
var disruptor_target:=-1
var reset_enabled:=true
var ResetTimer:Timer

# Called when the node enters the scene tree for the first time.
func _init(id:int,control:control_type) -> void:
	super(id,control)
	point_update_range_squared=point_update_range**2

func is_adversarial_agent()->bool:
	return disruptor_target!=-1

func SetCar(carinst:Car)->void:
	super(carinst)
	ai_points=car.map.ai_points
	current_point_id=0
	next_point_id=1
	next_point_id_2=2
	box_pending=false
	agent=(carinst.get_parent() as CarAgent)

func ResetPlayer(order:int)->void:
	super(order)
	agent.reset_agent()
	current_point_id=0
	next_point_id=1
	next_point_id_2=2

func UpdatePoint() -> void:
	if !IsPlayering():
		return
	super()
		
	# go to next point
	if (ai_points[current_point_id].distance_squared_to(car.global_position)
				<point_update_range_squared):
		if reset_enabled:
			ResetTimer.start()
		current_point_id=next_point_id
		next_point_id=next_point_id_2
		if next_point_id_2 + 1 < ai_points.size():
			next_point_id_2+=1
		else:
			next_point_id_2=0
		new_point_reached.emit()
		

func RunPropBox(x:float,y:float)->void:
	if not IsPlayering():
		return
	if car.NowPorpId!=0 or car.HasProp or box_pending:
		return
	if hud==null:
		box_pending=true
		await car.get_tree().create_timer(1.5).timeout
		car.HasProp=true
		car.CanUseProp=true
		var id:int=GetPropPer()
		GetProp(id)
		box_pending=false
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

func Stoprace()->void:
	super()
	if reset_enabled:
		ResetTimer.stop()

func StartRace()->void:
	super()
	if randf() < turbo_start_probability:
		PropValidated=true
		car.StartBoost()
	if reset_enabled:
		if not ResetTimer:
			ResetTimer=Timer.new()
			car.add_child(ResetTimer)
			ResetTimer.one_shot=true
			ResetTimer.wait_time=20		
			ResetTimer.timeout.connect(_reset_car)
		ResetTimer.start()


func _reset_car()->void:
	if reset_enabled:
		var newpos:Vector2 = ai_points[current_point_id - 1];
		car.Reset(newpos,0)
		car.speed=Vector2(0,0)
		ResetTimer.start()
