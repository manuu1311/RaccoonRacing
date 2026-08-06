extends CanvasLayer

@onready var trophy: Sprite2D = $Won/Text/Trophy/Trophy
@onready var won: Node2D = $Won
@onready var lost: Node2D = $Lost
@onready var maintext: Label = $Won/Text/Challenge/maintext
@onready var record: Node2D = $Won/Text/Trophy/Cuptime/Record
@onready var no_record: Node2D = $Won/Text/Trophy/Cuptime/NoRecord
@onready var chartext: Label = $Won/Text/Unlocks/Char/maintext
@onready var cuptext: Label = $Won/Text/Unlocks/Cup/maintext
@onready var charicon: Sprite2D = $Won/Text/Unlocks/Char/Icon
@onready var recordshadow: Label = $Won/Text/Trophy/Cuptime/Record/Time/shadow
@onready var recordtime: Label = $Won/Text/Trophy/Cuptime/Record/Time/maintext
@onready var norecordshadow: Label = $Won/Text/Trophy/Cuptime/NoRecord/Time/shadow
@onready var norecordtime: Label = $Won/Text/Trophy/Cuptime/NoRecord/Time/maintext
@onready var continue_buttonwin: Node2D = $Won/ContinueButton
@onready var continuebuttonloss: Node2D = $Lost/Continue
var nextdiff:Array[String]=[
	'Can you also beat this cup in normal mode?',
	'Can you also beat this cup in hard mode?',
	'Do you think you can beat your own score again?'
]
var cups:Array[Texture]=[
	null,
	preload("res://Assets/Animations/UISelect/cups/bronze.png"),
	preload("res://Assets/Animations/UISelect/cups/silver.png"),
	preload("res://Assets/Animations/UISelect/cups/gold.png")
]
var names:Array[String]=[
	"",
	"Rocko","Vixen","Mambo","Pingo","Hudson","Banzai"
]
var textures:Array[Texture]=[
	null,
	preload("res://Assets/Animations/CharSelection/characters/rockopic.png"),
	preload("res://Assets/Animations/CharSelection/characters/vixenpic.png"),
	preload("res://Assets/Animations/CharSelection/characters/mambopic.png"),
	preload("res://Assets/Animations/CharSelection/characters/pingopic.png"),
	preload("res://Assets/Animations/CharSelection/characters/hudsonpic.png"),
	preload("res://Assets/Animations/CharSelection/characters/banzaipic.png")
	]
	
func _ready() -> void:
	if GameData.IsMultiplayer and not NetworkManager.is_host:
		continuebuttonloss.hide()
		continue_buttonwin.hide()
	cuptext.hide()
	chartext.hide()
	charicon.hide()
	##local player won:
	if GameData.PlayersArr[GameData.Ranking[0]].current_control==Player.control_type.HUMAN:
		lost.hide()
		won.show()
		WonSetup()
	else:
		won.hide()
		lost.show()
		LossSetup()
	GameData.CurrentCupTime=0

func WonSetup()->void:
	trophy.texture=cups[GameData.currentDifficulty]
	maintext.text=nextdiff[GameData.currentDifficulty]
	#is it a new record?
	var timetext:String=GameData.format_time(GameData.CurrentCupTime)
	if GameData.CupTimes[GameData.currentCup][GameData.currentDifficulty]==0 or GameData.CupTimes[GameData.currentCup][GameData.currentDifficulty]>GameData.CurrentCupTime:
		#if so, store the new time and show the right effect
		GameData.CupTimes[GameData.currentCup][GameData.currentDifficulty]=GameData.CurrentCupTime
		record.show()
		no_record.hide()
		recordtime.text=timetext
		recordshadow.text=timetext
	else:
		record.hide()
		no_record.show()
		norecordtime.text=timetext
		norecordshadow.text=timetext
		
	#store win and check for character unlocks
	GameData.cupWon[GameData.currentCup]=max(GameData.cupWon[GameData.currentCup],GameData.currentDifficulty)
	var newcup:int=GameData.CheckCupLocks()
	var newchar:int=GameData.CheckCharacterLocks()
	if newcup!=0:
		cuptext.show()
		cuptext.text='Cup '+str(newcup)+' is now available. Good luck!'
	if newchar!=0:
		chartext.show()
		charicon.show()
		charicon.texture=textures[newchar]
		chartext.text='New driver unlocked! You can now play as '+names[newchar]+'!'
	GameData.StoreWin()
	
func LossSetup()->void:
	GameData.CurrentCupTime=0


func OnContinueButtonPressed()->void:
	if GameData.IsMultiplayer and NetworkManager.is_host:
		GameData.ClearAIPlayers()
	else:
		GameData.ClearPlayers()
	ChangeScene.rpc()

@rpc('authority','call_local','reliable')
func ChangeScene()->void:
	get_tree().change_scene_to_file("res://Assets/Scenes/Screens/ui_top_scores.tscn")

func OnButtonHoverWin()->void:
	continue_buttonwin.position.y-=3
func OnButtonHoverExitWin()->void:
	continue_buttonwin.position.y+=3
func OnButtonHoverLoss()->void:
	continuebuttonloss.position.y-=3
func OnButtonHoverExitLoss()->void:
	continuebuttonloss.position.y+=3
