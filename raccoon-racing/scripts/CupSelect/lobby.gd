extends Control
class_name MainLobby

@onready var lbltext: Label = $LobbyText/MainText
@onready var lobbytext_button: Button = $LobbyText/Button
@onready var lobby_screen: Control = $LobbyScreen
@onready var cup_screen: UICupSelection = $"../CupScreen"
var InLobbyScreen:bool=false
var IsLocked:bool=false
@onready var join_screen: Control = $LobbyScreen/JoinScreen
@onready var lobby_scene: LobbyScene = $LobbyScreen/LobbyScreen
@onready var infolbl: Label = $LobbyScreen/JoinScreen/Infolbl
@onready var leavelobbybtn: Button = $LobbyScreen/LobbyScreen/LeaveLobby/Button
@onready var leavelobbytxt: Label = $LobbyScreen/LobbyScreen/LeaveLobby/MainText
@onready var hosttxt: Label = $LobbyScreen/JoinScreen/HostButton/MainText
@onready var jointxt: Label = $LobbyScreen/JoinScreen/JoinButton/MainText
@onready var code: Button = $LobbyScreen/LobbyScreen/Code
@onready var lobbycodeinput: LineEdit = $LobbyScreen/JoinScreen/TextEdit
@onready var lantext: Label = $LobbyScreen/JoinScreen/LanButton/MainText
@export var lobby_script: LobbyScene
@onready var discoverbase: Panel = $LobbyScreen/JoinScreen/JoinButton/Discover/base
@onready var discoveranims: AnimationPlayer = $LobbyScreen/JoinScreen/JoinButton/Discover/base/AnimationPlayer
@onready var discovericon: Control = $LobbyScreen/JoinScreen/JoinButton/Discover
@onready var togglelan_button: CheckButton = $LobbyScreen/JoinScreen/LanButton/ToggleButton
var LanToggled:bool=true
var names:Array[String]=[
	"prova",
	"Rocko","Vixen","Mambo","Pingo","Hudson","Banzai"
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	show()
	lobby_screen.hide()
	cup_screen.show()
	join_screen.show()
	lobby_scene.hide()
	infolbl.hide()
	_on_toggled_lan(LanToggled)
	togglelan_button.button_pressed=LanToggled
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
		##get out of lobby
		if InLobbyScreen:
			InLobbyScreen=false
			lobbytext_button.focus_neighbor_left='../../../CupScreen/BackButton'
			lobbytext_button.focus_neighbor_top='../../../CupScreen/Cups/Cup8/Button'
			lbltext.add_theme_color_override("font_color",Color.WHITE)
			lobby_screen.hide()
			cup_screen.show()
			cup_screen.HandleShiny(GameData.currentCup)
			cup_screen.EnableCupFocus()
		##enter lobby
		else:
			ShowLobbyScreen()


func ShowLobbyScreen()->void:
	InLobbyScreen=true
	lobbytext_button.focus_neighbor_left=NodePath("")
	lobbytext_button.focus_neighbor_top=NodePath("")
	lbltext.add_theme_color_override("font_color",Color.YELLOW)
	cup_screen.hide()
	lobby_screen.show()
	cup_screen.hide_diff_screen()
	cup_screen.DisableCupFocus()


func _on_hostbutton_pressed() -> void:
	ButtonSounds.PlaySound("click")
	if not LanToggled:
		infolbl.show()
	NetworkManager.lobby_host(LanToggled)


func _on_joinbutton_pressed(_code:String='') -> void:
	ButtonSounds.PlaySound("click")
	if not LanToggled:
		infolbl.show()
	NetworkManager.lobby_join(lobbycodeinput.text,LanToggled)

func HostLobby(_code:String)->void:
	var hostid:int=multiplayer.get_unique_id()
	NetworkManager.NetworkID=hostid
	NetworkManager.PlayerID=0
	PopulateLocalPlayers()
	lobby_script.UpdateIconsNames()
	set_multiplayer_authority(hostid)
	GameData.IsMultiplayer=true
	LobbyTransition()

func LobbyJoined()->void:
	await get_tree().create_timer(1.0).timeout
	RegisterPlayer.rpc_id(1,GameData.currentCharacter[0])

@rpc("any_peer","call_remote","reliable")
func RegisterPlayer(newcharid:int)->void:
	if not NetworkManager.is_host: 
		return
	var sender_network_id: int = multiplayer.get_remote_sender_id()
	var newid:int=GameData.PlayersArr.size()
	var newplayer:Player=Player.new(newid,Player.control_type.MULTIPLAYER)
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
	SyncCup.rpc(GameData.currentCup)
	lobby_scene.GiveLobbyInfo()
	
@rpc("authority","call_remote","reliable")
func PlayerRegistered(charids:Array[int],playernames:Array[String],networkids:Array[int],_playerID:int)->void:
	var my_peer_id: int = multiplayer.get_unique_id()
	GameData.PlayersArr.clear()
	for i in range(charids.size()):
		var net_id: int = networkids[i]
		var control: Player.control_type = Player.control_type.HUMAN if net_id == my_peer_id else Player.control_type.MULTIPLAYER
		var newplayer:Player=Player.new(i,Player.control_type.MULTIPLAYER)
		newplayer.charid=charids[i]
		newplayer.OnlineName=playernames[i]
		newplayer.NetworkID = net_id
		newplayer.current_control=control
		GameData.PlayersArr.append(newplayer)
		if net_id == my_peer_id:
			NetworkManager.PlayerID = i
	if not IsLocked and not NetworkManager.is_host:
		LobbyTransition()
		IsLocked=true
		GameData.IsMultiplayer=true
	lobby_script.UpdateIconsNames()
	

func LobbyTransition()->void:
	join_screen.hide()
	lobby_scene.show()
	code.text=NetworkManager.current_lobby
	InputModeManager.ReApplyFocus()
	cup_screen.back_button.visible=false
	if LanToggled:
		NetworkManager.StartLanBroadcast()
	
func _on_leavelobbybutton_mouse_entered() -> void:
	ButtonSounds.PlaySound('hover')
	leavelobbytxt.add_theme_color_override("font_color",Color.YELLOW)


func _on_leavelobbybutton_mouse_exited() -> void:
	leavelobbytxt.add_theme_color_override("font_color",Color.WHITE)

##delete all multiplayer related variables
func _on_button_pressed() -> void:
	ButtonSounds.PlaySound("click")
	NetworkManager.leave_lobby()
	ClearNetworkVars()

func ClearNetworkVars()->void:
	GameData.IsMultiplayer=false
	GameData.PlayersArr=[]
	if not Game.IsSplitScreen:
		get_tree().change_scene_to_file("res://Assets/Scenes/Screens/ui_cup.tscn")
	else:
		get_tree().change_scene_to_file("res://Assets/Scenes/Screens/ui_char_selection.tscn")


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

func _on_toggled_lan(toggled:bool)->void:
	ButtonSounds.PlaySound('click')
	if toggled:
		lobbycodeinput.placeholder_text='Enter ip or press discover'
		lantext.add_theme_color_override("font_color",Color.YELLOW)
		LanToggled=true
		discovericon.show()
	else:
		lobbycodeinput.placeholder_text='Enter lobby id'
		lantext.add_theme_color_override("font_color",Color.WHITE)
		LanToggled=false
		discovericon.hide()


func _on_startbutton_pressed() -> void:
	print('[LOBBY]Start button pressed.')
	if lobby_scene.ControlsCheck():
		print('[LOBBY]All players have controls assigned. Starting game.')
		GameData.SetPlayersCount()
		CreateAIPlayers()
		Start.rpc()
	else:
		print('[LOBBY]Some players dont have controls assigned. Cannot start game.')
		ButtonSounds.PlaySound('warning')

@rpc('authority','call_local','reliable')
func Start()->void:
	GameData.currentDifficulty=min(GameData.cupWon[GameData.currentCup]+1,3)
	GameData.currentStep=0
	GameData.UpdateInfo()
	UiOverAnimation.playanim()
	await UiOverAnimation.animated_sprite_2d.animation_finished
	MusicPlayer.FadeOutAndStop(2.5)
	GameData.PopulateOrderArrays()
	UiLoadingScreen.ChangeScene()
	#get_tree().change_scene_to_file("res://Assets/Scenes/Screens/ui_loading_screen.tscn")


func CreateAIPlayers()->void:
	var available_ids:Array[int] = [1, 2, 3, 4, 5, 6]
	for player:Player in GameData.PlayersArr:
		available_ids.erase(player.charid)
	for i in range(GameData.PlayersArr.size(),4,1):
		var new_id:int
		available_ids.shuffle()
		new_id=available_ids.pop_front()
		var aiplayer:Player=AIPlayer.new(i,Player.control_type.AI)
		aiplayer.OnlineName=lobby_scene.names[i]
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
	
func hide_loading() -> void:
	visible=false

func PopulateLocalPlayers()->void:
	for i:int in range(GameData.currentCharacter.size()):
		var charid:int=GameData.currentCharacter[i]
		var newplayer:Player=Player.new(i,Player.control_type.HUMAN)
		newplayer.charid=charid
		newplayer.OnlineName=names[newplayer.charid]
		GameData.PlayersArr.append(newplayer)

func _on_detect_mouse_entered() -> void:
	ButtonSounds.PlaySound('hover')
	discoverbase.self_modulate=Color(1,0.5,1,1)


func _on_detect_mouse_exited() -> void:
	discoverbase.self_modulate=Color.WHITE


func _on_detect_pressed() -> void:
	ButtonSounds.PlaySound('click')
	if NetworkManager.IsDiscovering():
		NetworkManager.CleanDiscovery()
		NetworkManager.ResetType()
		discoveranims.play('RESET')
	else:
		NetworkManager.discover_lan_host()
		NetworkManager.SetLanType()
		discoveranims.play('Wifi')


func _on_lantext_mouse_entered() -> void:
	if LanToggled:
		lantext.add_theme_color_override("font_color",Color.WHITE)
	else:
		lantext.add_theme_color_override("font_color",Color.YELLOW)
	


func _on_lantext_mouse_exited() -> void:
	if LanToggled:
		lantext.add_theme_color_override("font_color",Color.YELLOW)
	else:
		lantext.add_theme_color_override("font_color",Color.WHITE)
	


func _on_lantextbutton_pressed() -> void:
	togglelan_button.button_pressed=not togglelan_button.button_pressed


func ResyncLobby() -> void:
	if not NetworkManager.is_host:
		return
	var charids:Array[int]=[]
	var playernames:Array[String]=[]
	var network_ids:Array[int]=[]
	for i in range(GameData.PlayersArr.size()):
		var player:Player = GameData.PlayersArr[i]
		player.PlayerID = i
		charids.append(player.charid)
		playernames.append(player.OnlineName)
		network_ids.append(player.NetworkID)
	PlayerRegistered.rpc(charids, playernames, network_ids, NetworkManager.PlayerID)
	SyncCup.rpc(GameData.currentCup)
	lobby_scene.UpdateIconsNames()
