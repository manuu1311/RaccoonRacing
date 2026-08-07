extends CanvasLayer


@onready var main_panel: Control = $MainPanel
@onready var hide_button: Button = $HideButton
@onready var fps: Label = $MainPanel/fps
@onready var latency: Label = $MainPanel/latency
@onready var frame: Label = $MainPanel/frame


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide_button.pressed.connect(_on_hide_pressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	fps.text = "fps: %.0f" % Engine.get_frames_per_second()
	#rtt/2*1000
	latency.text = "latency: %d ms" % (NetworkTime.remote_rtt * 500)
	var process_time_ms:float = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var physics_time_ms:float = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var total_cpu_ms:float = process_time_ms + physics_time_ms
	frame.text='frame: %d ms' %total_cpu_ms
	
func _on_hide_pressed()->void:
	main_panel.visible=not main_panel.visible
