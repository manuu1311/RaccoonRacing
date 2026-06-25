extends CanvasLayer

@onready var continuetext: Label = $Text/ContinueButton/maintext

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	MusicPlayer.PlayMusic("stats")
	#continuetext.add_theme_color_override("font_color",Color.WHITE)


func _on_continue_mouse_entered() -> void:
	continuetext.add_theme_color_override("font_color",Color.YELLOW)


func _on_continue_mouse_exited() -> void:
	continuetext.add_theme_color_override("font_color",Color.WHITE)


func _on_continue_pressed() -> void:
	pass
