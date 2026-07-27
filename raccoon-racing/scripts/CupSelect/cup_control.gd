extends Control
class_name UICupSelection

@onready var bg_filter: TextureRect = $BGFilter
@onready var cups: Control = $Cups
@onready var buttons: DifficultyButtons = $Buttons
var choosing_diff:bool=false
signal CupSelected

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide_diff_screen()
	UiOverAnimation.reset_anim_frame()
	#connect each cup
	for i in range(8):
		var button_path:String = "Cups/Cup" + str(i+1) +"/Button"
		var cup_button:Button = get_node(button_path) as Button
		cup_button.pressed.connect(_on_cup_pressed.bind(i))





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
	
func show_diff_screen()->void:
	bg_filter.show()
	buttons.show()
	
	
	

func _on_cup_pressed(id: int) -> void:
	if GameData.cupLocks[id]:
		ButtonSounds.PlaySound('warning')
	else:
		ButtonSounds.PlaySound('click')
		GameData.currentCup=id
		if GameData.IsMultiplayer and NetworkManager.is_host:
			CupSelected.emit()
		else:
			choosing_diff=true
			buttons.updateLocks(GameData.currentCup)
			show_diff_screen()
