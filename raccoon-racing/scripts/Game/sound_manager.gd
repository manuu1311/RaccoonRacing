extends AudioStreamPlayer
class_name GameSoundManager

var audio_streams:Dictionary[String, AudioStream]
var fade_tween: Tween

func _ready() -> void:
	audio_streams = {
		"levelstart": preload("res://Assets/Sounds/2322_snd_levelstart.mp3"),
		"ready3": preload("res://Assets/Sounds/2371_snd_Ready3.mp3"),
		"ready2": preload("res://Assets/Sounds/2372_snd_Ready2.mp3"),
		"ready1": preload("res://Assets/Sounds/2373_snd_Ready1.mp3"),
		"go":preload("res://Assets/Sounds/2374_snd_Go.mp3"),
		"finish":preload("res://Assets/Sounds/2320_snd_finish.mp3"),
		"failed":preload("res://Assets/Sounds/2321_snd_failed.mp3")
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
## [br]
## - [code]"finish"[/code]
## [br]
## - [code]"failed"[/code]
func PlaySound(sound: String, fade_duration: float = 0.0) -> void:
	var new_stream: Variant = audio_streams.get(sound)
	
	if not new_stream:
		push_warning("Sound '" + sound + "' not found in audio_streams dictionary")
		return

	# If nothing is playing, just play the new sound instantly at full volume
	if !playing or fade_duration <= 0.0:
		stream = new_stream
		volume_db = 0.0 # Reset to full volume (0 dB is unattenuated)
		play()
		return

	# Kill any ongoing fade tween to prevent conflicts
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()

	# Create a new tween to fade out the current sound
	fade_tween = create_tween()
	
	# Linear audio attenuation works best dipping down to around -40 dB to -60 dB (effectively silent)
	fade_tween.tween_property(self, "volume_db", -40.0, fade_duration)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)
	
	# After the fade-out finishes, switch the stream, reset volume, and play
	fade_tween.tween_callback(func()->void:
		stream = new_stream
		volume_db = 0.0 
		play()
	)
