extends CanvasLayer

@onready var trophy: Sprite2D = $Won/Text/Trophy/Trophy
@onready var won: Node2D = $Won
@onready var lost: Node2D = $Lost
@onready var maintext: Label = $Won/Text/Challenge/maintext
@onready var record: Node2D = $Won/Text/Trophy/Cuptime/Record
@onready var no_record: Node2D = $Won/Text/Trophy/Cuptime/NoRecord
@onready var chartext: Label = $Won/Text/Unlocks/Char/maintext
@onready var cuptest: Label = $Won/Text/Unlocks/Cup/maintext
var nextdiff:Array[String]=[
	'Can you also beat this cup in normal mode?',
	'Can you also beat this cup in normal mode?',
	'Do you think you can beat your own score again?'
]
var cups:Array[Texture]=[
	preload("res://Assets/Animations/UISelect/cups/bronze.png"),
	preload("res://Assets/Animations/UISelect/cups/silver.png"),
	preload("res://Assets/Animations/UISelect/cups/gold.png")
]

func _ready() -> void:
	##player won:
	if GameData.PlayersArr[GameData.Ranking[0]].car==GameData.FocusCar:
		lost.hide()
		won.show()
		WonSetup()
	else:
		won.hide()
		lost.show()
		LossSetup()

func WonSetup()->void:
	trophy.texture=cups[GameData.currentDifficulty]
	maintext.text=nextdiff[GameData.currentDifficulty]
	#is it a new record?
	if GameData.CupTimes[GameData.currentCup][GameData.currentDifficulty]==0 or GameData.CupTimes[GameData.currentCup][GameData.currentDifficulty]>GameData.CurrentCupTime:
		#if so, store the new time and show the right effect
		GameData.CupTimes[GameData.currentCup][GameData.currentDifficulty]=GameData.CurrentCupTime
		record.show()
		no_record.hide()
	else:
		record.hide()
		no_record.show()
		
func LossSetup()->void:
	pass
