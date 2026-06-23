extends CanvasLayer

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


func playanim()->void:
	animated_sprite_2d.play()
#reset to the first frame for transparency
func reset_anim_frame()->void:
	animated_sprite_2d.frame=0
	
	
