extends Control
class_name UICupSelection

@onready var bg_filter: TextureRect = $BGFilter
@onready var cups: Control = $Cups
@onready var buttons: DifficultyButtons = $Buttons
@onready var back_button: TextureButton = $BackButton
var choosing_diff:bool=false
signal CupSelected
@onready var tofocus_btn: Button = $Buttons/EasyBTN/Button
@onready var lobby: MainLobby = $"../Lobby"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#connect each cup
	for i in range(8):
		var button_path:String = "Cups/Cup" + str(i+1) +"/Button"
		var cup_button:Button = get_node(button_path) as Button
		cup_button.pressed.connect(_on_cup_pressed.bind(i))
	hide_diff_screen()
	UiOverAnimation.reset_anim_frame()
	InputModeManager.ReApplyFocus()
	if Game.IsSplitScreen or GameData.IsMultiplayer:
		call_deferred('TransitionToLobby')


func TransitionToLobby()->void:
	lobby.ShowLobbyScreen()
	#lobby.LobbyTransition()
	if not GameData.IsMultiplayer:
		lobby._on_toggled_lan(true)
		lobby._on_hostbutton_pressed()
	elif not NetworkManager.is_host:
		lobby.IsLocked=true


func EnableCupFocus()->void:
	for i in range(8):
		var button_path:String = "Cups/Cup" + str(i+1) +"/Button"
		var cup_button:Button = get_node(button_path) as Button
		cup_button.add_theme_stylebox_override("Focus",StyleBoxEmpty.new())

func DisableCupFocus()->void:
	for i in range(8):
		var button_path:String = "Cups/Cup" + str(i+1) +"/Button"
		var cup_button:Button = get_node(button_path) as Button
		cup_button.remove_theme_stylebox_override("Focus")

func _on_back_button_pressed() -> void:
	ButtonSounds.PlaySound('click')
	if choosing_diff:
		hide_diff_screen()
		choosing_diff=false
	else:
		get_tree().change_scene_to_file('res://Assets/Scenes/Screens/ui_char_selection.tscn')


func _on_back_button_mouse_entered() -> void:
	ButtonSounds.PlaySound('hover')
	$BackButton.position.y-=3


func _on_back_button_mouse_exited() -> void:
	$BackButton.position.y+=3


func _on_diff_pressed(diff: int) -> void:
	if buttons.locks[diff-1]:
		ButtonSounds.PlaySound('warning')
	else:
		ButtonSounds.PlaySound('click')
		GameData.currentDifficulty=diff
		GameData.currentStep=0
		GameData.UpdateInfo()
		UiOverAnimation.playanim()
		await UiOverAnimation.animated_sprite_2d.animation_finished
		MusicPlayer.FadeOutAndStop(2.5)
		GameData.PopulatePlayers()
		print('Network tick rate: ',NetworkTime.tickrate)
		NetworkTime.start()
		UiLoadingScreen.ChangeScene()
		#get_tree().change_scene_to_file("res://Assets/Scenes/Screens/ui_loading_screen.tscn")
		


func hide_diff_screen()->void:
	bg_filter.hide()
	buttons.hide()
	var backbtn:Control=$BackButton
	backbtn.focus_neighbor_top='../Cups/Cup7/Button'
	backbtn.focus_neighbor_right='../../Lobby/LobbyText/Button'
	backbtn.focus_neighbor_bottom='../Cups/Cup1/Button'
	
func show_diff_screen()->void:
	bg_filter.show()
	buttons.show()
	var backbtn:Control=$BackButton
	backbtn.focus_neighbor_bottom='../Buttons/EasyBTN/Button'
	backbtn.focus_neighbor_top='../Buttons/HardBTN/Button'
	
##handle selected cup shiny (for multiplayer)
func HandleShiny(id:int)->void:
	if not GameData.IsMultiplayer:
		return
	var shinypath:String = "Cups/Cup" + str(GameData.currentCup+1)+'/Img/Shiny'
	var shiny:TextureRect=get_node_or_null(shinypath)
	shiny.hide()
	var newshinypath:String = "Cups/Cup" + str(id+1)+'/Img/Shiny'
	var newshiny:TextureRect=get_node_or_null(newshinypath)
	newshiny.show()
	

func _on_cup_pressed(id: int) -> void:
	if GameData.cupLocks[id]:
		ButtonSounds.PlaySound('warning')
	else:
		ButtonSounds.PlaySound('click')
		HandleShiny(id)
		GameData.currentCup=id
		if GameData.IsMultiplayer and NetworkManager.is_host:
			CupSelected.emit()
		else:
			choosing_diff=true
			buttons.updateLocks(GameData.currentCup)
			show_diff_screen()
			if InputModeManager.mode==InputModeManager.Mode.CONTROLLER:
				tofocus_btn.grab_focus()
			
