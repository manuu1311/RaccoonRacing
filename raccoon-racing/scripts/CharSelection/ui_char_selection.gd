extends Control
class_name UICharSelection

@onready var back_button: TextureButton = $BackButton

func _on_back_button_pressed() -> void:
	ButtonSounds.PlaySound('click')
	get_tree().change_scene_to_file('res://Assets/Scenes/Screens/ui_main_menu.tscn')


func _on_back_button_mouse_entered() -> void:
	ButtonSounds.PlaySound('hover')
	back_button.position.y-=3


func _on_back_button_mouse_exited() -> void:
	back_button.position.y+=3
