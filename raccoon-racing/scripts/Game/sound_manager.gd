extends AudioStreamPlayer
class_name GameSoundManager

var audio_streams:Dictionary[String, AudioStream]


func _ready() -> void:
	audio_streams = {
		"levelstart": preload("res://Assets/Sounds/2322_snd_levelstart.mp3"),
		"ready3": preload("res://Assets/Sounds/2371_snd_Ready3.mp3"),
		"ready2": preload("res://Assets/Sounds/2372_snd_Ready2.mp3"),
		"ready1": preload("res://Assets/Sounds/2373_snd_Ready1.mp3"),
		"go":preload("res://Assets/Sounds/2374_snd_Go.mp3")
	}
## Plays a specific sound effect based on the provided identifier.
## [br][br]
## [b]Supported sound types:[/b]
## [br]
## - [code]"levelstart"[/code]
## [br]
## - [code]"ready3"[/code]
## [br]
## - [code]"ready2"[/code]
## [br]
## - [code]"ready1"[/code]
## [br]
## - [code]"go"[/code]
func PlaySound(sound: String)->void:
	var new_stream:Variant = audio_streams.get(sound)
	
	if new_stream:
		stream = new_stream
		play()
	else:
		push_warning("Sound '" + sound + "' not found in audio_streams dictionary")
