# InputModeManager.gd — set as an autoload singleton
extends Node

enum Mode { MOUSE, CONTROLLER, EMPTY }

signal mode_changed(mode: Mode)

var mode: Mode = Mode.MOUSE

const JOY_AXIS_DEADZONE := 0.35

func _ready()->void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().scene_changed.connect(_on_scene_changed)

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		_switch_to_controller()
	elif event is InputEventJoypadMotion:
		if abs(event.axis_value) > JOY_AXIS_DEADZONE:
			_switch_to_controller()
	elif event is InputEventMouseMotion:
		# ignore tiny/residual motion, real movement only
		if event.relative.length() > 0.5:
			_switch_to_mouse()
	elif event is InputEventMouseButton:
		_switch_to_mouse()

func _switch_to_controller() -> void:
	if mode == Mode.CONTROLLER:
		return
	mode = Mode.CONTROLLER
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	var vp :Viewport= get_viewport()
	var target :Control= vp.gui_get_hovered_control()
	if target and target.focus_mode != Control.FOCUS_NONE:
		target.grab_focus()
	else:
		_focus_nearest_fallback(vp)
	vp.set_input_as_handled()
	mode_changed.emit(mode)

func _switch_to_mouse() -> void:
	if mode == Mode.MOUSE:
		return
	mode = Mode.MOUSE
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_viewport().gui_release_focus()
	mode_changed.emit(mode)

func _focus_nearest_fallback(vp: Viewport) -> void:
	# no control directly under the cursor (e.g. mouse over blank space) —
	# fall back to whatever currently has focus, or a scene-defined default
	var focused :Control= vp.gui_get_focus_owner()
	if focused:
		return
	for node:Control in get_tree().get_nodes_in_group("default_focus"):
		if node.is_visible_in_tree() and node.focus_mode != Control.FOCUS_NONE:
			node.grab_focus()
			return

func _switch_to_empty()->void:
	mode=Mode.EMPTY

func _on_scene_changed()->void:
	_switch_to_empty()
