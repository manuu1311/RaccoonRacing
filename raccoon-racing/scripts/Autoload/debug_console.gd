extends CanvasLayer

@onready var panel: Panel = $Panel
@onready var output: RichTextLabel = $Panel/Vbox/Output
@onready var input: LineEdit = $Panel/Vbox/Input

var tweakable_variables:Array[String]=[
	'should_predict',
	'extrapolation_frames'
]
var should_predict:bool=true
var extrapolation_frames:int=3

func _ready() -> void:
	panel.visible = false
	input.text_submitted.connect(_on_command_submitted)
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Debug Console"):
		toggle_console()
		get_viewport().set_input_as_handled()

func is_open() -> bool:
	return panel.visible

func toggle_console() -> void:
	panel.visible = not panel.visible
	if panel.visible:
		input.grab_focus()
		input.clear()

func log_line(text: String) -> void:
	output.append_text(text + "\n")

func _on_command_submitted(text: String) -> void:
	if text.strip_edges() == "":
		return
	log_line("> " + text)
	execute_command(text)
	input.clear()

func execute_command(text: String) -> void:
	var parts := text.split(" ", false)
	if parts.is_empty():
		return
	match parts[0].to_lower():
		"set": cmd_set(parts)
		"list": cmd_list()
		_: log_line("Unknown command: " + parts[0])

func cmd_set(parts: Array) -> void:
	if parts.size() < 3:
		log_line("Usage: set <variable> <value>")
		return
	var var_name: String = parts[1]
	var raw_value: String = parts[2]

	if not var_name in tweakable_variables:
		log_line("No such variable: " + var_name)
		return
	match var_name:
		'should_predict':
			var newvalue:bool=_convert_bool(raw_value)
			#SetPredict.rpc(newvalue)
			log_line("%s = %s" % [var_name, str(newvalue)])
		'extrapolation_frames':
			var newvalue:int=int(raw_value)
			SetFrames.rpc(newvalue)
			log_line("%s = %s" % [var_name, str(newvalue)])


func cmd_list() -> void:
	log_line('should_predict: bool, extrapolation_frames: int')

func _convert_bool(raw: String)->bool:
		return raw.to_lower() in ["true", "1", "yes", "on"]

@rpc("any_peer",'call_local','reliable')
func SetPredict(newval:bool)->void:
	should_predict=newval
	for player:Player in GameData.PlayersArr:
		pass
		#player.car.should_predict=should_predict
		
@rpc("any_peer",'call_local','reliable')
func SetFrames(newval:int)->void:
	extrapolation_frames=newval
	for player:Player in GameData.PlayersArr:
		player.car.extrapolation_frames=extrapolation_frames
