extends TextureRect

@onready var shiny: TextureRect = $Shiny
@onready var label: TextureRect = $Label
@onready var lock: TextureRect = $"../Lock"
@onready var infotext: Label = $"../Infotext"
@export var hovertext: Texture2D
@export var normaltext: Texture2D
@export var id: int
@export var locked: bool 
@export var unlockInfo: String

#greyed out icon transform
var r_g_b: float = 102.0 / 256.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	infotext.hide()
	shiny.hide()
	label.texture=normaltext
	if locked:
		greyout()
	else:
		lock.hide()





func _on_mouse_entered() -> void:
	if locked:
		greyout()
		infotext.show()
	else:
		shiny.show()
		label.texture=hovertext
	
	
	


func _on_mouse_exited() -> void:
	if locked:
		infotext.hide()
	else:
		shiny.hide()
		label.texture=normaltext


func _on_pressed() -> void:
	print('pressed')

func greyout():
	self.modulate = Color(r_g_b, r_g_b, r_g_b, 1)
func greyin():
	self.modulate = Color(1,1,1, 1)
