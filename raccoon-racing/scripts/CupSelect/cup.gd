extends Control

@export var locked: bool
@export var completed: int
@onready var img: TextureRect = $Img
@onready var medals: Control = $Img/Medals
@onready var lock: TextureRect = $Lock
#greyed out icon transform
var r_g_b: float = 102.0 / 256.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Img/Medals/Silver.hide()
	$Img/Medals/Bronze.hide()
	$Img/Medals/Gold.hide()
	$Img/Shiny.hide()
	$Infotext.hide()
	#if locked: hide cups, apply transform
	if locked:
		medals.hide()
		lock.show()
		greyout()
	#if unlocked, show cups
	else:
		lock.hide()
		#completed at least in easy mode
		if completed>=1:
			$Img/Medals/Bronze.show()
		#completed at least in normal mode
		if completed>=2:
			$Img/Medals/Silver.show()
		#completed in hard mode
		if completed>=3:
			$Img/Medals/Gold.show()




func _on_button_mouse_entered() -> void:
	if locked:
		$Infotext.show()
	else:
		$Img/Shiny.show()


func _on_button_mouse_exited() -> void:
	if locked:
		$Infotext.hide()
	else:
		$Img/Shiny.hide()

func greyout():
	img.modulate = Color(r_g_b, r_g_b, r_g_b, 1)
func greyin():
	img.modulate = Color(1,1,1, 1)
