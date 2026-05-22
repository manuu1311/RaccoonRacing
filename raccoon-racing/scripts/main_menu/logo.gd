extends CanvasLayer
class_name Logo

@onready var wheel_player: AnimationPlayer = $WheelPlayer
@onready var animation_player: AnimationPlayer = $ShiningPlayer
@onready var first_bar: ColorRect = $Text/FirstBar
@onready var second_bar: ColorRect = $Text/SecondBar


func _ready() -> void:
	first_bar.position.x=-128
	second_bar.position.x=-128

func play_anim() -> void:
	animation_player.play('LogoShine')
	#sync with background animation
	animation_player.seek(0.6)
	wheel_player.play('WheelRotate')
