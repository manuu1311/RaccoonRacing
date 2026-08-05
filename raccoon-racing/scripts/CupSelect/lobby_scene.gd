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
@export var dropdowns:Array[OptionButton]
@export var labels:Array[LineEdit]
@onready var startctrl: Control = $StartGame
@onready var starttxt: Label = $StartGame/MainText
@onready var cuptxt: Label = $CupInfo/Cup
@onready var lobbycodetext: Label = $Text
@onready var mainlobby: MainLobby = $"../.."
@onready var aipropbtn: CheckBox = $AIPropUse/btn
const KEYBOARD_DEVICES := ["Keyboard 1", "Keyboard 2"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	UpdateIconsNames()
	if Game.IsSplitScreen:
		ConnectSignals()

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
		if player.current_control!=Player.control_type.HUMAN:
			labels[i].editable=false
			dropdowns[i].hide()
			# Disconnect previous signals if they exist so they don't stack up
			if labels[i].text_submitted.is_connected(_on_name_submitted):
				labels[i].text_submitted.disconnect(_on_name_submitted)
			if labels[i].focus_exited.is_connected(_on_name_focus_exited):
				labels[i].focus_exited.disconnect(_on_name_focus_exited)
		else:
			labels[i].editable=true
			dropdowns[i].show()
			_populate_dropdown(i)
			if not labels[i].text_submitted.is_connected(_on_name_submitted):
				labels[i].text_submitted.connect(_on_name_submitted.bind(i))
			if not labels[i].focus_exited.is_connected(_on_name_focus_exited):
				# We bind the LineEdit instance so we can read its text when focus leaves
				labels[i].focus_exited.connect(_on_name_focus_exited.bind(labels[i],i))
	#bots
	for i in range(GameData.PlayersArr.size(),4,1):
		rects[i].texture=textures[0]
		labels[i].text=names[i]
		labels[i].editable=false
		dropdowns[i].hide()
	if not Game.IsSplitScreen:
		HideDropdowns()


func UpdateCupInfo()->void:
	cuptxt.text='CUP '+str(GameData.currentCup+1)

func SendNameUpdate(new_name: String,playerid:int) -> void:
	if NetworkManager.is_host:
		ChangeNameRequest(new_name,playerid)
	else:
		ChangeNameRequest.rpc_id(1, new_name,playerid)

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


func _on_name_submitted(new_text: String,playerid:int) -> void:
	# Player hit Enter. Remove focus from the LineEdit to look clean
	var current_focus:Control = get_viewport().gui_get_focus_owner()
	if current_focus:
		current_focus.release_focus() 
	# Send the name up to your network controller (adjust node path if needed)
	SendNameUpdate(new_text,playerid)

func _on_name_focus_exited(line_edit: LineEdit,playerid:int) -> void:
	# Player clicked away or unfocused. Submit whatever text is currently inside
	SendNameUpdate(line_edit.text,playerid)


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

#region device detection

func ConnectSignals()->void:
	if not Input.joy_connection_changed.is_connected(_on_joy_connection_changed):
		Input.joy_connection_changed.connect(_on_joy_connection_changed)
	for i in range(dropdowns.size()):
		dropdowns[i].item_selected.connect(_on_device_dropdown_item_selected.bind(i))

func HideDropdowns()->void:
	for dropdown in dropdowns:
		dropdown.hide()

func _get_available_device_list() -> Array[Dictionary]:
	var devices: Array[Dictionary] = []
	devices.append({'key':'','label':'','type':'','id':-2})
	for kb:String in KEYBOARD_DEVICES:
		devices.append({"key": kb, "label": kb, "type": kb, "id": -1})
	for joy_id in Input.get_connected_joypads():
		devices.append({
			"key": "Joypad %d" % joy_id,
			"label": "Joypad %d (%s)" % [joy_id, Input.get_joy_name(joy_id)],
			"type": "Joypad",
			"id": joy_id,
		})
	return devices	

func _get_taken_device_keys(exclude_slot: int = -1) -> Array[String]:
	var taken: Array[String] = []
	for i in range(GameData.PlayersArr.size()):
		if i == exclude_slot:
			continue
		var player: Player = GameData.PlayersArr[i]
		if player.current_control == Player.control_type.HUMAN and player.input_device_key != "":
			taken.append(player.input_device_key)
	return taken

# --- Populating a single dropdown ---

func _populate_dropdown(i: int,manual_override:bool=false) -> void:
	if i >= GameData.PlayersArr.size():
		return
	var player: Player = GameData.PlayersArr[i]
	if player.current_control != Player.control_type.HUMAN:
		return

	var taken := _get_taken_device_keys(i)
	var devices := _get_available_device_list()
	var current_key := player.input_device_key

	dropdowns[i].clear()
	var select_index := 0
	var idx := 0
	for device in devices:
		dropdowns[i].add_item(device.label)
		dropdowns[i].set_item_metadata(idx, device)
		if device.key in taken and not device.key=='':
			dropdowns[i].set_item_disabled(idx,true)
		else:
			dropdowns[i].set_item_disabled(idx,false)
		if device.key == current_key and device.key!=null:
			select_index = idx
		idx += 1

	if dropdowns[i].item_count == 0:
		dropdowns[i].add_item("No device available")
		dropdowns[i].set_item_disabled(0, true)
		player.input_device_type = ""
		player.input_device_id = -1
		player.input_device_key = ""
		return
	if select_index == 0 and not manual_override:
		select_index = 0
		for idx2 in range(1, devices.size()):
			if not devices[idx2].key in taken:
				select_index = idx2
				break
			
	dropdowns[i].select(select_index)
	_apply_device_selection(i, dropdowns[i].get_item_metadata(select_index))

func _apply_device_selection(i: int, device: Dictionary) -> void:
	var player: Player = GameData.PlayersArr[i]
	player.input_device_type = device.type
	player.input_device_id = device.id
	player.input_device_key = device.key
	#InputManager.assign_device(i + 1, device.type, device.id)

func _refresh_all_device_dropdowns(exclude_slot: int = -1,manual_override:bool=false) -> void:
	for i in range(GameData.PlayersArr.size()):
		if i == exclude_slot:
			_populate_dropdown_preserving_selection(i)
		else:
			_populate_dropdown(i,manual_override)

func _populate_dropdown_preserving_selection(i: int) -> void:
	_populate_dropdown(i,true)

func _on_device_dropdown_item_selected(index: int, slot: int) -> void:
	var device: Dictionary = dropdowns[slot].get_item_metadata(index)
	_apply_device_selection(slot, device)
	_refresh_all_device_dropdowns(slot,true)

func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
	if not connected:
		for i in range(GameData.PlayersArr.size()):
			var player: Player = GameData.PlayersArr[i]
			if player.input_device_type == "Joypad" and player.input_device_id == device_id:
				player.input_device_key = ""
	_refresh_all_device_dropdowns()

#endregion
