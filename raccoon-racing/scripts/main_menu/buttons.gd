extends Node
class_name UIbuttons

@export var audio_streams:Array[AudioStream]
@onready var audio_player: AudioStreamPlayer2D = $AudioPlayer

func _on_mouse_entered() -> void:
	audio_player.stream=audio_streams[0]
	audio_player.play()
	
func _on_mouse_click() -> void:
	audio_player.stream=audio_streams[1]
	audio_player.play()
