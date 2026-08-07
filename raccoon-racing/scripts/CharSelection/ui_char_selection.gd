extends Control
class_name UICharSelection

@onready var back_button: TextureButton = $BackButton
var PlayersNum:int
var selected_player_icons:Array[TextureRect]=[]
@onready var playerlbltext: Label = $"../SplitScreen/lbl"
##which player is currently selecting
var CurrentPlayerChoice:int=0
var CharactersChosen:Array[CharacterIcon]=[]
var textures:Array[Texture]=[
	preload("res://icon.svg"),
	preload("res://Assets/Animations/CharSelection/characters/rockopic.png"),
	preload("res://Assets/Animations/CharSelection/characters/vixenpic.png"),
	preload("res://Assets/Animations/CharSelection/characters/mambopic.png"),
	preload("res://Assets/Animations/CharSelection/characters/pingopic.png"),
	preload("res://Assets/Animations/CharSelection/characters/hudsonpic.png"),
	preload("res://Assets/Animations/CharSelection/characters/banzaipic.png")
	]
@onready var startbutton: Button = $"../SplitScreen/StartGame/StartButton"
@onready var playercount_slider: HSlider = $"../SplitScreen/HSlider"
@onready var startbutton_txt: Label = $"../SplitScreen/StartGame/MainText"
@onready var split_screen: Control = $"../SplitScreen"


func _ready() -> void:
	GameData.PlayersArr.clear()
	InputModeManager.ReApplyFocus()
	PlayersNum=1
	Game.IsSplitScreen=false
	startbutton.get_parent_control().visible=false
	for node:TextureRect in $"../SplitScreen/HBoxContainer".get_children():
		selected_player_icons.append(node)
		node.visible=false
	#disable split screen for android
	if OS.has_feature('android'):
		Game
		split_screen.visible=false
		

func _on_back_button_pressed() -> void:
	if CurrentPlayerChoice<1:
		ButtonSounds.PlaySound('click')
		get_tree().change_scene_to_file('res://Assets/Scenes/Screens/ui_main_menu.tscn')
	else:
		CurrentPlayerChoice-=1
		CharactersChosen[CurrentPlayerChoice].greyin()
		CharactersChosen.pop_back()
		selected_player_icons[CurrentPlayerChoice].visible=false
		if CurrentPlayerChoice==0:
			SwapSliderStart(true)
			
func SwapSliderStart(sliderappear:bool)->void:
	playercount_slider.visible=sliderappear
	startbutton.get_parent_control().visible=not sliderappear
	

func _on_back_button_mouse_entered() -> void:
	ButtonSounds.PlaySound('hover')
	back_button.position.y-=3


func _on_back_button_mouse_exited() -> void:
	back_button.position.y+=3


func _on_player_slider_value_changed(value: float) -> void:
	ButtonSounds.PlaySound('click')
	var newval:int=int(value)
	PlayersNum=newval
	playerlbltext.text='Players: '+str(newval)
	if newval>1:
		Game.IsSplitScreen=true
	else:
		Game.IsSplitScreen=false


func CharacterSelected(icon:CharacterIcon)->void:
	if icon not in CharactersChosen and PlayersNum>CharactersChosen.size():
		if CharactersChosen.size()==0:
			SwapSliderStart(false)
		ButtonSounds.PlaySound('click')
		CharactersChosen.append(icon)
		selected_player_icons[CurrentPlayerChoice].texture=textures[icon.id]
		selected_player_icons[CurrentPlayerChoice].visible=true
		CurrentPlayerChoice+=1
		icon.greyout()
	else:
		ButtonSounds.PlaySound('warning')


func _on_start_button_mouse_entered() -> void:
	if CharactersChosen.size()==PlayersNum:
		ButtonSounds.PlaySound('hover')
		startbutton_txt.add_theme_color_override("font_color",Color.YELLOW)


func _on_start_button_mouse_exited() -> void:
	startbutton_txt.add_theme_color_override("font_color",Color.WHITE)


func _on_start_button_pressed() -> void:
	if CharactersChosen.size()==PlayersNum:
		Game.LocalPlayers=PlayersNum
		GameData.currentCharacter.clear()
		for icon:CharacterIcon in CharactersChosen:
			GameData.currentCharacter.append(icon.id)
		ButtonSounds.PlaySound('click')
		UiOverAnimation.playanim()
		await  UiOverAnimation.animated_sprite_2d.animation_finished
		get_tree().change_scene_to_file('res://Assets/Scenes/Screens/ui_cup.tscn')
	else:
		ButtonSounds.PlaySound('warning')
