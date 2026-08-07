extends CanvasLayer
class_name SpeedHud


@onready var animated_sprite_2d: AnimatedSprite2D = $Control/AnimatedSprite2D
@onready var label: Label = $Control/Label
@onready var laps: Label = $Laps
@onready var time: Label = $Time
@onready var best_time: Label = $BestTime

var timestart: float = 0.0
var totaltimestart:float
var current_lap_time: int = 0
var currentlap: int = 1
var totallaps: int
var updating: bool
var bestlaptime: int = 0
var car:Car
var totaltime:int=0
var raceOver:bool=false

func Setup() -> void:
	timestart = Time.get_ticks_msec()
	totaltimestart = Time.get_ticks_msec()
	totallaps = GameData.currentLaps
	updating = false
	raceOver=false
	
	# Load the existing best time from data
	var id:int
	if GameData.current_vehicle==GameData.VehicleType.CAR:
		id=0
	else:
		id=1
	bestlaptime = GameData.BestTimes[GameData.currentMap][id]
	best_time.text = format_time(bestlaptime)
	
	# Set initial lap text before timer ends
	laps.text = str(currentlap) + "/" + str(totallaps)



func SetCar(carinst:Car)->void:
	car=carinst

func _process(_delta: float) -> void:
	if updating or car.isLock:
		return
	var speed:int
	if car.isLock:
		speed=0
	else:
		speed=int(car.speed.length()*10)
	label.text = str(speed)
	@warning_ignore("integer_division")
	animated_sprite_2d.frame = int(speed / 30)
	
	if raceOver:
		return
	@warning_ignore("narrowing_conversion")
	current_lap_time = Time.get_ticks_msec() - timestart
	@warning_ignore("narrowing_conversion")
	totaltime=Time.get_ticks_msec()-totaltimestart
	time.text = format_time(totaltime)

func format_time(msec_total: float) -> String:
	var total_seconds: int = int(msec_total / 1000)
	
	@warning_ignore("integer_division")
	var minutes: int = total_seconds / 60
	var seconds: int = total_seconds % 60
	# Divide by 10 to turn 0-999ms into 0-99cs (2 digits)
	@warning_ignore("integer_division")
	var milliseconds: int = int(msec_total) % 1000 / 10 
	
	return "%02d:%02d:%02d" % [minutes, seconds, milliseconds]

func on_lap_completed() -> void:
	currentlap += 1
	laps.text = str(currentlap) + "/" + str(totallaps)
	
	# Don't check record on "Lap 1" initialization if it's just your 5-second test timer!
	# (But for real gameplay, see the condition below:)
	if current_lap_time > 0:
		time.text=format_time(current_lap_time)
		# If bestlaptime is 0 (no record yet) OR current lap is faster than previous best
		if bestlaptime == 0 or current_lap_time < bestlaptime:
			bestlaptime = current_lap_time
		var id:int
		if GameData.current_vehicle==GameData.VehicleType.CAR:
			id=0
		else:
			id=1
		GameData.BestTimes[GameData.currentMap][id] = bestlaptime
		best_time.text = format_time(bestlaptime)

	
	# Reset timer for the next lap
	timestart = Time.get_ticks_msec()
	
	updating = true
	await get_tree().create_timer(2).timeout
	updating = false

func stop()->void:
	raceOver=true
