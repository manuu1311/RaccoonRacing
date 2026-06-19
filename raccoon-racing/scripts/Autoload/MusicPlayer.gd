extends AudioStreamPlayer

var audio_streams:Dictionary[String, AudioStream]


func _ready() -> void:
	audio_streams = {
			"main": preload("res://Assets/Sounds/2323_snd_mains.mp3"),
			"map1": preload("res://Assets/Sounds/2327_snd_map1.mp3"),
			"map2": preload("res://Assets/Sounds/2326_snd_map2.mp3"),
			"map3": preload("res://Assets/Sounds/2325_snd_map3.mp3"),
			"map4": preload("res://Assets/Sounds/2324_snd_map4.mp3"),
			"invincible":preload("res://Assets/Sounds/2319_snd_invincilble.mp3")
		}

func PlayMusic(music: String)->void:
	var new_stream:Variant = audio_streams.get(music)
	
	if new_stream:
		stream = new_stream
		stream.loop = true
		play()
	else:
		push_warning("Music '" + music + "' not found in audio_streams dictionary")
