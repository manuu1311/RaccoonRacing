extends CanvasLayer

@onready var virtual_joystick_dx: VirtualJoystickDX = $Control/LeftSide/VirtualJoystickDX
@onready var right: Control = $Control/LeftSide/Right
@onready var left: Control = $Control/LeftSide/Left

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	UpdateMode()
	if not GyroController.mode_updated_signal.is_connected(UpdateMode):
		GyroController.mode_updated_signal.connect(UpdateMode)

func UpdateMode()->void:
	if GameData.mode_joystick:
		virtual_joystick_dx.visible=true
		virtual_joystick_dx.set_process(true)
		right.visible=false
		left.visible=false
		set_process(false)
	else:
		virtual_joystick_dx.visible=false
		virtual_joystick_dx.set_process(false)
		right.visible=true
		left.visible=true
		set_process(true)
		
func _process(_delta: float) -> void:
	if Input.is_action_pressed('Steer right'):
		right.modulate=Color(1,1,0,1)
	else:
		right.modulate=Color.WHITE
	if Input.is_action_pressed('Steer left'):
		left.modulate=Color(1,1,0,1)
	else:
		left.modulate=Color.WHITE
