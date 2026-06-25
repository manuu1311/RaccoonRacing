extends AudioStreamPlayer

var audio_streams:Dictionary[String, AudioStream]
var fade_tween: Tween

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


func FadeOutAndStop(fade_duration: float = 0.5) -> void:
	if not playing:
		return
		
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
		
	fade_tween = create_tween()
	fade_tween.tween_property(self, "volume_db", -40.0, fade_duration)
	fade_tween.tween_callback(stop)
