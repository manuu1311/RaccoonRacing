extends CanvasLayer


@onready var main_panel: Control = $MainPanel
@onready var hide_button: Button = $HideButton
@onready var fps: Label = $MainPanel/fps
@onready var latency: Label = $MainPanel/latency


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide_button.pressed.connect(_on_hide_pressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	fps.text = "fps: %.0f" % Engine.get_frames_per_second()
	latency.text = "latency: %d ms" % (NetworkTime.remote_rtt / 2.0 * 1000)
	
func _on_hide_pressed()->void:
	main_panel.visible=not main_panel.visible
