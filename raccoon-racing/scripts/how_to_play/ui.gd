extends CanvasLayer
class_name HowToPlayAnimator

@onready var animation: AnimatedSprite2D = $Control/Animation
@onready var back_button: TextureButton = $Control/BackButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation.frame=0
	for i in 2:
		await get_tree().process_frame
	animation.play()


func _on_back_button_mouse_entered() -> void:
	ButtonSounds.PlaySound('hover')
	back_button.position.y-=4

func _on_back_button_mouse_exited() -> void:
	back_button.position.y+=4


func _on_back_button_pressed() -> void:
	ButtonSounds.PlaySound('click')
	get_tree().change_scene_to_file('res://Assets/Scenes/Screens/ui_main_menu.tscn')
	
