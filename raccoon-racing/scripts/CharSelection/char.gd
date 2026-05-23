extends TextureRect

@onready var shiny: TextureRect = $Shiny
@onready var label: TextureRect = $Label
@onready var lock: TextureRect = $"../Lock"
@onready var infotext: Label = $"../Infotext"
@export var hovertext: Texture2D
@export var normaltext: Texture2D
@export var id: int
var locked: bool 
@export var unlockInfo: String

#greyed out icon transform
var r_g_b: float = 102.0 / 256.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	locked=GameData.characterLocks[id]
	infotext.text=unlockInfo
	infotext.hide()
	shiny.hide()
	label.texture=normaltext
	if locked:
		greyout()
	else:
		lock.hide()





func _on_mouse_entered() -> void:
	ButtonSounds.PlaySound('hover')
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
	if locked:
		ButtonSounds.PlaySound('warning')
	else:
		ButtonSounds.PlaySound('click')
		GameData.currentCharacter=id
		UiOverAnimation.playanim()
		await  UiOverAnimation.animated_sprite_2d.animation_finished
		get_tree().change_scene_to_file('res://Assets/Scenes/Screens/ui_cup.tscn')

func greyout():
	self.modulate = Color(r_g_b, r_g_b, r_g_b, 1)
func greyin():
	self.modulate = Color(1,1,1, 1)
