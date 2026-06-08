extends Sprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#fade effect
	#wait 2 seconds
	await get_tree().create_timer(2.0).timeout
	
	# gradually fade
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	
	# clear once fade has finished
	tween.finished.connect(queue_free)
	
