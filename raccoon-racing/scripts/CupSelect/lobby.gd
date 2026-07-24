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
@export var lobby_script: LobbyScene
var names:Array[String]=[
	"prova",
	"Rocko","Vixen","Mambo","Pingo","Hudson","Banzai"
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	lobby_screen.hide()
	cup_screen.show()
	join_screen.show()
	lobby_scene.hide()
	infolbl.hide()
	cup_screen.CupSelected.connect(_on_cup_selected)
	NetworkManager.signal_lobby_created.connect(HostLobby)
	NetworkManager.signal_lobby_joined.connect(LobbyJoined)
	NetworkManager.signal_host_left.connect(_on_button_pressed)
	NetworkManager.signal_client_disconnected.connect(_on_peer_disconnected)
	NetworkManager.signal_peer_left.connect(_on_peer_disconnected)

func _on_cup_selected()->void:
	SyncCup.rpc(GameData.currentCup)
	lobby_script.UpdateCupInfo()

@rpc('authority','call_remote','reliable')
func SyncCup(cup:int)->void:
	GameData.currentCup=cup
	lobby_script.UpdateCupInfo()

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
			cup_screen.hide_diff_screen()


func _on_hostbutton_pressed() -> void:
	ButtonSounds.PlaySound("click")
	infolbl.show()
	NetworkManager.lobby_host()


func _on_joinbutton_pressed(_code:String='') -> void:
	ButtonSounds.PlaySound("click")
	infolbl.show()
	NetworkManager.lobby_join(lobbycodeinput.text)

func HostLobby(_code:String)->void:
	var hostid:int=multiplayer.get_unique_id()
	NetworkManager.NetworkID=hostid
	var host_player: Player = Player.new(0, Player.control_type.HUMAN)
	NetworkManager.PlayerID=0
	host_player.charid = GameData.currentCharacter
	host_player.OnlineName=names[host_player.charid]
	GameData.PlayersArr.append(host_player)
	lobby_script.UpdateIconsNames()
	set_multiplayer_authority(hostid)
	GameData.IsMultiplayer=true
	LobbyTransition()

func LobbyJoined()->void:
	await get_tree().create_timer(1.0).timeout
	RegisterPlayer.rpc_id(1,GameData.currentCharacter)

@rpc("any_peer","call_remote","reliable")
func RegisterPlayer(newcharid:int)->void:
	if not NetworkManager.is_host: 
		return
	var sender_network_id: int = multiplayer.get_remote_sender_id()
	var newid:int=GameData.PlayersArr.size()
	var newplayer:Player=Player.new(newid,Player.control_type.HUMAN)
	newplayer.charid=newcharid
	newplayer.OnlineName=names[newcharid]
	newplayer.NetworkID = sender_network_id
	GameData.PlayersArr.append(newplayer)
	lobby_script.UpdateIconsNames()
	var charids:Array[int]=[]
	var playernames:Array[String]=[]
	var network_ids: Array[int] = []
	for player:Player in GameData.PlayersArr:
		charids.append(player.charid)
		playernames.append(player.OnlineName)
		network_ids.append(player.NetworkID)
	PlayerRegistered.rpc(charids,playernames,network_ids,newid)
	
@rpc("authority","call_remote","reliable")
func PlayerRegistered(charids:Array[int],playernames:Array[String],networkids:Array[int],playerID:int)->void:
	GameData.PlayersArr.clear()
	for i in range(charids.size()):
		var newplayer:Player=Player.new(i,Player.control_type.HUMAN)
		newplayer.charid=charids[i]
		newplayer.OnlineName=playernames[i]
		newplayer.NetworkID = networkids[i]
		GameData.PlayersArr.append(newplayer)
	if not IsLocked and not NetworkManager.is_host:
		NetworkManager.PlayerID=playerID
		LobbyTransition()
		IsLocked=true
		GameData.IsMultiplayer=true
	lobby_script.UpdateIconsNames()
	

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
	GameData.IsMultiplayer=false
	GameData.PlayersArr=[]
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

func _on_peer_disconnected()->void:
	_on_button_pressed()


func _on_startbutton_pressed() -> void:
	print('Start button pressed, starting game')
	GameData.SetPlayersCount()
	CreateAIPlayers()
	Start.rpc()

@rpc('authority','call_local','reliable')
func Start()->void:
	GameData.currentDifficulty=GameData.cupWon[GameData.currentCup]
	GameData.currentStep=0
	GameData.UpdateInfo()
	UiOverAnimation.playanim()
	await UiOverAnimation.animated_sprite_2d.animation_finished
	MusicPlayer.FadeOutAndStop(2.5)
	GameData.PopulateOrderArrays()
	get_tree().change_scene_to_file("res://Assets/Scenes/Screens/ui_loading_screen.tscn")


func CreateAIPlayers()->void:
	var available_ids:Array[int] = [1, 2, 3, 4, 5, 6]
	for player:Player in GameData.PlayersArr:
		available_ids.erase(player.charid)
	for i in range(GameData.PlayersArr.size(),4,1):
		var new_id:int
		available_ids.shuffle()
		new_id=available_ids.pop_front()
		var aiplayer:Player=AIPlayer.new(i,Player.control_type.AI)
		GameData.PlayersArr.append(aiplayer)
		aiplayer.AiReflect=lobby_script.difficulty
		aiplayer.charid=new_id
		CreateNewAIPlayer.rpc(i,new_id)

@rpc('authority','call_remote','reliable')
func CreateNewAIPlayer(playerid:int,charid:int)->void:
	var aiplayer:Player=AIPlayer.new(playerid,Player.control_type.AI)
	GameData.PlayersArr.append(aiplayer)
	aiplayer.AiReflect=lobby_script.difficulty
	aiplayer.charid=charid
