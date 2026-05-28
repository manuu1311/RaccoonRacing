extends AudioStreamPlayer2D

var audio_streams:Dictionary[String, AudioStream]


func _ready() -> void:
	audio_streams = {
		"hover": preload("res://Assets/Sounds/2366_snd_ButtonOver.mp3"),
		"click": preload("res://Assets/Sounds/2368_snd_ButtonRelease.mp3"),
		"warning": preload("res://Assets/Sounds/2365_snd_ButtonWarning.mp3"),
		"secret": preload("res://Assets/Sounds/2332_snd_Ice.mp3")
	}
## Plays a specific UI sound effect based on the provided identifier.
## [br][br]
## [b]Supported sound types:[/b]
## [br]
## - [code]"hover"[/code]
## [br]
## - [code]"click"[/code]
## [br]
## - [code]"warning"[/code]
func PlaySound(sound: String)->void:
	var new_stream = audio_streams.get(sound)
	
	if new_stream:
		stream = new_stream
		play()
	else:
		push_warning("Sound '" + sound + "' not found in audio_streams dictionary")
