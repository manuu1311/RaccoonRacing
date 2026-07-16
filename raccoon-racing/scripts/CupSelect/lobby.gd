extends Control

@onready var lbltext: Label = $LobbyText/MainText
@onready var lobby_screen: Control = $LobbyScreen
@onready var cup_screen: UICupSelection = $"../CupScreen"
var InLobbyScreen:bool=false
var IsLocked:bool=false
@onready var join_screen: Control = $LobbyScreen/JoinScreen
@onready var lobby_scene: Control = $LobbyScreen/LobbyScreen
@onready var infolbl: Label = $LobbyScreen/JoinScreen/Infolbl
@onready var leavelobbybtn: Button = $LobbyScreen/LobbyScreen/LeaveLobby/Button
@onready var leavelobbytxt: Label = $LobbyScreen/LobbyScreen/LeaveLobby/MainText
@onready var hosttxt: Label = $LobbyScreen/JoinScreen/HostButton/MainText
@onready var jointxt: Label = $LobbyScreen/JoinScreen/JoinButton/MainText
@onready var code: Button = $LobbyScreen/LobbyScreen/Code
@onready var lobbycodeinput: LineEdit = $LobbyScreen/JoinScreen/TextEdit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	lobby_screen.hide()
	cup_screen.show()
	join_screen.show()
	lobby_scene.hide()
	infolbl.hide()
	NetworkManager.signal_lobby_created.connect(HostLobby)
	NetworkManager.signal_lobby_joined.connect(LobbyTransition)
	

func _on_lobby_mouse_entered() -> void:
	#print('lobby enter')
	ButtonSounds.PlaySound('hover')
	var color:Color
	if InLobbyScreen:
		color=Color.WHITE
	else:
		color=Color.YELLOW
	lbltext.add_theme_color_override("font_color",color)


func _on_lobby_mouse_exited() -> void:
	#print('lobby exit')
	var color:Color
	if InLobbyScreen:
		color=Color.YELLOW
	else:
		color=Color.WHITE
	lbltext.add_theme_color_override("font_color",color)


func _on_lobby_pressed() -> void:
	#print('lobby pressed')
	if IsLocked:
		ButtonSounds.PlaySound("warning")
		return
	else:
		ButtonSounds.PlaySound("click")
		if InLobbyScreen:
			InLobbyScreen=false
			lbltext.add_theme_color_override("font_color",Color.WHITE)
			lobby_screen.hide()
			cup_screen.show()
		else:
			InLobbyScreen=true
			lbltext.add_theme_color_override("font_color",Color.YELLOW)
			cup_screen.hide()
			lobby_screen.show()


func _on_hostbutton_pressed() -> void:
	ButtonSounds.PlaySound("click")
	infolbl.show()
	NetworkManager.lobby_host()


func _on_joinbutton_pressed() -> void:
	ButtonSounds.PlaySound("click")
	infolbl.show()
	NetworkManager.lobby_join(lobbycodeinput.text)

func HostLobby()->void:
	LobbyTransition()

func LobbyTransition()->void:
	join_screen.hide()
	lobby_scene.show()
	code.text=NetworkManager.current_lobby
	
func _on_leavelobbybutton_mouse_entered() -> void:
	ButtonSounds.PlaySound('hover')
	leavelobbytxt.add_theme_color_override("font_color",Color.YELLOW)


func _on_leavelobbybutton_mouse_exited() -> void:
	leavelobbytxt.add_theme_color_override("font_color",Color.WHITE)

##delete all multiplayer related variables
func _on_button_pressed() -> void:
	ButtonSounds.PlaySound("click")
	get_tree().change_scene_to_file("res://Assets/Scenes/Screens/ui_cup.tscn")


func _on_joinbutton_mouse_entered() -> void:
	ButtonSounds.PlaySound('hover')
	jointxt.add_theme_color_override("font_color",Color.YELLOW)


func _on_joinbutton_mouse_exited() -> void:
	jointxt.add_theme_color_override("font_color",Color.WHITE)


func _on_button_mouse_entered() -> void:
	ButtonSounds.PlaySound('hover')
	hosttxt.add_theme_color_override("font_color",Color.YELLOW)


func _on_hostbutton_mouse_exited() -> void:
	hosttxt.add_theme_color_override("font_color",Color.WHITE)


func _on_lobbycode_pressed() -> void:
	DisplayServer.clipboard_set(code.text)
