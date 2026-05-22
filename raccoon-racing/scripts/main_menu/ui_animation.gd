extends AnimatedSprite2D
class_name UIAnimator

signal main_anim_complete
@onready var logo: Logo = $"../Logo"
@onready var buttons: UIbuttons = $"../Buttons"

func _ready():
	play("intro")
	buttons.hide()
	logo.hide()
	frame=0
	frame_changed.connect(_on_frame_changed)

func _on_frame_changed():
	if frame == 40:
		pause()
		buttons.show()
		#buttons.show_buttons()
		main_anim_complete.emit()
		logo.show()
		#await get_tree().create_timer(2).timeout
		logo.play_anim()

func _on_button_pressed():
	print('start button pressed')
	buttons.hide()
	logo.hide()
	play()


func _on_how_to_play_button_pressed() -> void:
	print('how to play button pressed')
	buttons.hide()
	logo.hide()
	play()


func _on_high_scores_button_pressed() -> void:
	print('high scores button pressed')
	buttons.hide()
	logo.hide()
	play()
