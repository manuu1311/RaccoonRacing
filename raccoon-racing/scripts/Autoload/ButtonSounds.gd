extends AudioStreamPlayer2D

var audio_streams:Dictionary[String, AudioStream]

func _ready() -> void:
	audio_streams = {
		"hover": preload("res://Assets/Sounds/2366_snd_ButtonOver.mp3"),
		"click": preload("res://Assets/Sounds/2368_snd_ButtonRelease.mp3"),
	}

func PlaySound(sound: String)->void:
	var new_stream = audio_streams.get(sound)
	
	if new_stream:
		stream = new_stream
		play()
	else:
		push_warning("Sound '" + sound + "' not found in audio_streams dictionary")
