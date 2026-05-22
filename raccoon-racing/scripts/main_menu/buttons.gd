extends Node
class_name UIbuttons


func _on_mouse_entered() -> void:
	ButtonSounds.PlaySound('hover')
	
func _on_mouse_click() -> void:
	ButtonSounds.PlaySound('click')
