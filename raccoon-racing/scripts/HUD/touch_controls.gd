extends CanvasLayer

@onready var virtual_joystick_dx: VirtualJoystickDX = $Control/LeftSide/VirtualJoystickDX
@onready var right: Control = $Control/LeftSide/Right
@onready var left: Control = $Control/LeftSide/Left

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	UpdateMode()
	if not GyroController.mode_updated_signal.is_connected(UpdateMode):
		GyroController.mode_updated_signal.connect(UpdateMode)
	GameData

func UpdateMode()->void:
	if GameData.mode_joystick:
		virtual_joystick_dx.visible=true
		virtual_joystick_dx.set_process(true)
		right.visible=false
		left.visible=false
	else:
		virtual_joystick_dx.visible=false
		virtual_joystick_dx.set_process(false)
		right.visible=true
		left.visible=true
