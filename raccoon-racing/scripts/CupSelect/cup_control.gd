extends Control
class_name UICupSelection

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	UiOverAnimation.reset_anim_frame()




func _on_button_pressed() -> void:
	pass # Replace with function body.



func _on_back_button_pressed() -> void:
	ButtonSounds.PlaySound('click')
	get_tree().change_scene_to_file('res://Assets/Scenes/Screens/ui_char_selection.tscn')


func _on_back_button_mouse_entered() -> void:
	ButtonSounds.PlaySound('hover')
	$BackButton.position.y-=3


func _on_back_button_mouse_exited() -> void:
	$BackButton.position.y+=3
