extends CanvasLayer

@onready var cups: Control = $Cups
@onready var continue_button: Control = $Buttons/ContinueButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if GameData.IsMultiplayer and not NetworkManager.is_host:
		continue_button.hide()
	for i in range(8):
		UpdateTime(i)


func UpdateTime(num:int)->void:
	var controlparent:Control=cups.get_child(num) as Control
	var easytime:Label=controlparent.get_node("Easy")
	var normaltime:Label=controlparent.get_node("Normal")
	var hardtime:Label=controlparent.get_node("Hard")
	var cupinfo:int=GameData.cupWon[num]
	if cupinfo>=1:
		easytime.text=GameData.format_time(GameData.CupTimes[num][0])
	if cupinfo>=2:
		normaltime.text=GameData.format_time(GameData.CupTimes[num][1])
	if cupinfo>=3:
		hardtime.text=GameData.format_time(GameData.CupTimes[num][2])

func _on_button_mouse_entered() -> void:
	continue_button.position.y-=3


func _on_button_mouse_exited() -> void:
	continue_button.position.y+=3


func _on_button_pressed() -> void:
	MusicPlayer.stop()
	if GameData.IsMultiplayer:
		LobbyScene.rpc()
	else:
		get_tree().change_scene_to_file("res://Assets/Scenes/Screens/ui_main_menu.tscn")

@rpc('authority','call_local','reliable')
func LobbyScene()->void:
	get_tree().change_scene_to_file("res://Assets/Scenes/Screens/ui_cup.tscn")
