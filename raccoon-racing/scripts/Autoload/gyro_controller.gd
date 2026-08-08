extends CanvasLayer

var enabled :bool= false
var neutral_tilt :float= 0.0
var deadzone_degrees :float= 10.0


var gyro_pressed_left :bool= false
var gyro_pressed_right :bool= false

@onready var gyro_arrow: TextureRect = $Anchor/Panel/GyroArrow
@onready var gyro_arrow_2: TextureRect = $Anchor/Panel/GyroArrow2
@onready var gyro_slider: HSlider = $Anchor/GyroSlider
@onready var anchor: Control = $Anchor
@onready var right: TextureRect = $Anchor/Right
@onready var left: TextureRect = $Anchor/Left

func _ready() -> void:
	if not OS.has_feature('android'):
		set_process(false)
		visible=false
		return
	anchor.visible=false
	GameData.LoadPrefs()
	enabled=GameData.use_gyro
	if not enabled:
		DisableGyro()
	deadzone_degrees=GameData.gyro_deadzone
	gyro_slider.value=deadzone_degrees

func _process(_delta:float)->void:
	if not enabled:
		return
	
	if anchor.visible:
		ColorfulActions()
	
	var tilt:float = Input.get_accelerometer().x - neutral_tilt
	var threshold:float = 9.8 * sin(deg_to_rad(deadzone_degrees))

	var want_right:bool = tilt > threshold
	var want_left:bool = tilt < -threshold

	if want_right and not gyro_pressed_right:
		Input.action_press("steer_right")
		gyro_pressed_right = true
	elif not want_right and gyro_pressed_right:
		Input.action_release("steer_right")
		gyro_pressed_right = false

	if want_left and not gyro_pressed_left:
		Input.action_press("steer_left")
		gyro_pressed_left = true
	elif not want_left and gyro_pressed_left:
		Input.action_release("steer_left")
		gyro_pressed_left = false

func calibrate()->void:
	neutral_tilt = Input.get_accelerometer().x

func ColorfulActions()->void:
	if Input.is_action_pressed('Steer right'):
		right.self_modulate=Color(1,1,0,1)
	else:
		right.self_modulate=Color.WHITE
	if Input.is_action_pressed('Steer left'):
		left.self_modulate=Color(1,1,0,1)
	else:
		left.self_modulate=Color.WHITE


func EnableGyro()->void:
	set_process(true)
	gyro_arrow.visible=true
	gyro_arrow_2.visible=true

func DisableGyro()->void:
	set_process(false)
	gyro_arrow.visible=false
	gyro_arrow_2.visible=false


func _on_gyro_base_pressed() -> void:
	enabled=not enabled
	GameData.use_gyro=enabled
	if enabled:
		calibrate()
		EnableGyro()
	else:
		DisableGyro()


func _on_gyro_slider_value_changed(value: float) -> void:
	deadzone_degrees=value
	GameData.gyro_deadzone=value


func _on_hide_button_pressed() -> void:
	anchor.visible=not anchor.visible
