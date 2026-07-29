extends Control
class_name LobbyScene

#TODO: allow host to change difficulties
var difficulties:Array=[10]
##difficulty taken for game start
var difficulty:int=10
@export var names:Array[String]
var textures:Array[Texture]=[
	preload("res://icon.svg"),
	preload("res://Assets/Animations/CharSelection/characters/rockopic.png"),
	preload("res://Assets/Animations/CharSelection/characters/vixenpic.png"),
	preload("res://Assets/Animations/CharSelection/characters/mambopic.png"),
	preload("res://Assets/Animations/CharSelection/characters/pingopic.png"),
	preload("res://Assets/Animations/CharSelection/characters/hudsonpic.png"),
	preload("res://Assets/Animations/CharSelection/characters/banzaipic.png")
	]
@export var rects:Array[TextureRect]
@export var labels:Array[LineEdit]
@onready var startctrl: Control = $StartGame
@onready var starttxt: Label = $StartGame/MainText
@onready var cuptxt: Label = $CupInfo/Cup
@onready var lobbycodetext: Label = $Text
@onready var mainlobby: MainLobby = $"../.."
@onready var aipropbtn: CheckBox = $AIPropUse/btn

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	UpdateIconsNames()


func UpdateCode()->void:
	if NetworkManager.IsLobbySealed:
		lobbycodetext.text='Lobby sealed'
	elif NetworkManager.IsLan():
		lobbycodetext.text='Lobby IP'
	else:
		lobbycodetext.text='Lobby code'
		
func UpdateIconsNames()->void:
	if NetworkManager.is_host:
		startctrl.show()
	else:
		startctrl.hide()
	#online players connected
	for i in range(GameData.PlayersArr.size()):
		var player:Player=GameData.PlayersArr[i]
		rects[i].texture=textures[player.charid]
		labels[i].text=player.OnlineName
		if player.PlayerID!=NetworkManager.PlayerID:
			labels[i].editable=false
			# Disconnect previous signals if they exist so they don't stack up
			if labels[i].text_submitted.is_connected(_on_name_submitted):
				labels[i].text_submitted.disconnect(_on_name_submitted)
			if labels[i].focus_exited.is_connected(_on_name_focus_exited):
				labels[i].focus_exited.disconnect(_on_name_focus_exited)
		else:
			labels[i].editable=true
			if not labels[i].text_submitted.is_connected(_on_name_submitted):
				labels[i].text_submitted.connect(_on_name_submitted)
			if not labels[i].focus_exited.is_connected(_on_name_focus_exited):
				# We bind the LineEdit instance so we can read its text when focus leaves
				labels[i].focus_exited.connect(_on_name_focus_exited.bind(labels[i]))
	#bots
	for i in range(GameData.PlayersArr.size(),4,1):
		rects[i].texture=textures[0]
		labels[i].text=names[i]
		labels[i].editable=false


func UpdateCupInfo()->void:
	cuptxt.text='CUP '+str(GameData.currentCup+1)

func SendNameUpdate(new_name: String) -> void:
	if NetworkManager.is_host:
		ChangeNameRequest(new_name,NetworkManager.PlayerID)
	else:
		ChangeNameRequest.rpc_id(1, new_name,NetworkManager.PlayerID)

@rpc("any_peer", "call_remote", "reliable")
func ChangeNameRequest(new_name: String,id:int) -> void:
	if not NetworkManager.is_host: 
		return
		
	# Find the player in our host list and update their name
	for player in GameData.PlayersArr:
		if player.PlayerID == id:
			player.OnlineName = new_name
			break
			
	# Broadcast the update to everyone else
	BroadcastNameUpdate.rpc(id, new_name)
	UpdateIconsNames()

@rpc("authority", "call_remote", "reliable")
func BroadcastNameUpdate(player_id: int, new_name: String) -> void:
	# Clients update their local match data
	for player in GameData.PlayersArr:
		if player.PlayerID == player_id:
			player.OnlineName = new_name
			break
	UpdateIconsNames()


func _on_name_submitted(new_text: String) -> void:
	# Player hit Enter. Remove focus from the LineEdit to look clean
	var current_focus:Control = get_viewport().gui_get_focus_owner()
	if current_focus:
		current_focus.release_focus() 
	# Send the name up to your network controller (adjust node path if needed)
	SendNameUpdate(new_text)

func _on_name_focus_exited(line_edit: LineEdit) -> void:
	# Player clicked away or unfocused. Submit whatever text is currently inside
	SendNameUpdate(line_edit.text)


func _on_startbutton_mouse_entered() -> void:
	starttxt.add_theme_color_override("font_color",Color.YELLOW)


func _on_startbutton_mouse_exited() -> void:
	starttxt.add_theme_color_override("font_color",Color.WHITE)


func _on_aiprop_check_button_toggled(toggled_on: bool) -> void:
	if NetworkManager.is_host:
		AIPropCheck.rpc(toggled_on)

@rpc('authority','call_local','reliable')
func AIPropCheck(value:bool)->void:
	GameData.AICanUseProp=value
	aipropbtn.set_pressed_no_signal(value)

##send remote client info about the lobby
func GiveLobbyInfo()->void:
	if is_multiplayer_authority():
		_on_aiprop_check_button_toggled(aipropbtn.button_pressed)
		mainlobby.SyncCup(GameData.currentCup)
