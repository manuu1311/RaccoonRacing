extends Node

#for which character, is he unlocked?
#0:rocko 1:vixen 2:mambo
#3:pingo 4:hudson 5:banzai
var characterLocks: Array[bool]=[0,0,1,1,1,1]
#current character chosen
var currentCharacter: int=1
#cup info: lock
var cupLocks: Array[bool]=[0,0,0,0,1,1,1,1]
#cup info: which cups were won, in which difficulty
#0: not won, 1:easy, 2:normal, 3:hard
var cupWon: Array[int]=[0,0,0,0,0,0,0,0]
#current cup chosen
var currentCup: int = 0
##curent cup step
var currentStep:int=0
##array info for each cup:
##[mapid,lapnum,type] for each map
var cupInfo:Array[Array]=[
	[[1,3,VehicleType.CAR],[2,2,VehicleType.CAR]],
	[[1,3,VehicleType.HOVERCRAFT],[2,2,VehicleType.HOVERCRAFT]],
	[[3,2,VehicleType.CAR],[1,3,VehicleType.CAR]],
	[[3,2,VehicleType.HOVERCRAFT],[1,3,VehicleType.HOVERCRAFT]],
	[[4,3,VehicleType.CAR],[2,2,VehicleType.CAR],[3,2,VehicleType.CAR]],
	[[4,3,VehicleType.HOVERCRAFT],[3,2,VehicleType.HOVERCRAFT],[2,2,VehicleType.HOVERCRAFT]],
	[[2,3,VehicleType.CAR],[1,2,VehicleType.HOVERCRAFT],[3,2,VehicleType.CAR],[4,3,VehicleType.HOVERCRAFT]],
	[[2,4,VehicleType.HOVERCRAFT],[1,3,VehicleType.CAR],[3,3,VehicleType.HOVERCRAFT],[4,4,VehicleType.CAR]]
]
#current difficulty chosen
##0-1-2
var currentDifficulty: int=2
var currentMap:int=1
var currentLaps:int=3
#car/hovercraft mode
enum VehicleType { CAR, HOVERCRAFT }
var current_vehicle: VehicleType = VehicleType.CAR
var PlayersArr:Array[Player]=[]
var OrderInfo:Array[int]=[]
var Ranking:Array[int]=[]
var FocusCar:Car
var FocusPlayer:Player
##array to store info about best lap times in the 4 circuits
var BestTimes:Array[Array]=[
	[0,0],
	[0,0],[0,0],
	[0,0],[0,0]
	]
var AiLevel:Array[Array]
##current time in the cup, useful for calculating total time at 
##the end of the cup. added after each race finish
var CurrentCupTime:int=0
##current race time
var CurrentRaceTime:int=0
##[cup,difficulty]:best time for "cup" in the chosen "difficulty"
var CupTimes:Array[Array]=[
	[0,0,0],[0,0,0],
	[0,0,0],[0,0,0],
	[0,0,0],[0,0,0],
	[0,0,0],[0,0,0],
]

const SAVE_PATH = "user://savegame.tres"
var save_data: SaveData
var debug_save_file: SaveData=preload("res://Assets/test_save.tres")

func _ready() -> void:
	print(debug_save_file)
	load_game()
	AiLevel=[
		[[18,100,false],[20,100,false],[22,200,false]],
		[[15,80,true],[18,80,false],[20,80,false]],
		[[10,30,true],[12,40,true],[15,60,true]],
	]


func save_game() -> void:
	# 1. Update the resource with your current game session data
	save_data.cupWon = cupWon
	save_data.BestTimes = BestTimes
	save_data.CupTimes = CupTimes
	
	# 2. Save the resource to the device
	var result = ResourceSaver.save(save_data, SAVE_PATH)
	if result == OK:
		print("Game Saved Successfully!")

func load_game() -> void:
	print('Save path: ',ProjectSettings.globalize_path(SAVE_PATH))
	# 2. Check if you dragged a custom resource into the inspector for testing
	if OS.has_feature("editor") and debug_save_file != null:
		save_data = debug_save_file
		print("Loaded data directly from Editor Inspector!")
	# 3. Otherwise, fall back to normal local device saves
	elif ResourceLoader.exists(SAVE_PATH):
		save_data = ResourceLoader.load(SAVE_PATH)
		print("Game Loaded from user storage!")
	else:
		save_data = SaveData.new()
		print("New Save File Created!")
		
	# Sync values
	cupWon = save_data.cupWon
	BestTimes = save_data.BestTimes
	CupTimes = save_data.CupTimes
	characterLocks=save_data.characterLocks
	cupLocks=save_data.cupLocks

#update character locks, to unlock new characters after each cup
func CheckCharacterLocks()->int:
	#mambo: cup 1,3 easy
	if cupWon[0]>0 and cupWon[2]>0:
		if characterLocks[2]:
			characterLocks[2]=0
			return 3
	#pingo: cup 2,4 easy
	if cupWon[1]>0 and cupWon[3]>0:
		if characterLocks[3]:
			characterLocks[3]=0
			return 4
	#hudson: cup 5,6 easy
	if cupWon[4]>0 and cupWon[5]>0:
		if characterLocks[4]:
			characterLocks[4]=0
			return 5
	#banzai: all cups normal
	var check: bool = true
	for cup in cupWon:
		if cup<2:
			check=false
			break
	if check:
		if characterLocks[5]:
			characterLocks[5]=0
			return 6
	return 0
#update cup locks, to unlock new cups
func CheckCupLocks()->int:
	#cup 5: 1,3 easy
	if cupWon[0]>0 and cupWon[2]>0:
		if cupLocks[4]:
			cupLocks[4]=0
			return 5
	#cup 6: 2,4 easy
	if cupWon[1]>0 and cupWon[3]>0:
		if cupLocks[5]:
			cupLocks[5]=0
			return 6
	#cup 7: 1 to 6 normal
	var check: bool = true
	for i in range(6):
		var cup: int=cupWon[i]
		if cup<2:
			check=false
			break
	if check:
		if cupLocks[6]:
			cupLocks[6]=0
			return 7
	#cup 8: 7 normal
	if cupWon[6]>1:
		if cupLocks[7]:
			cupLocks[7]=0
			return 8
	return 0

func PopulatePlayers()->void:

	var newplayer:Player
	newplayer=Player.new(0,Player.control_type.HUMAN)
	PlayersArr.append(newplayer)
	OrderInfo.append(0)
	Ranking.append(0)
	newplayer=AIPlayer.new(1,Player.control_type.AI)
	PlayersArr.append(newplayer)
	newplayer.AiReflect=AiLevel[currentDifficulty-1][0][0]
	OrderInfo.append(1)
	Ranking.append(1)
	newplayer=AIPlayer.new(2,Player.control_type.AI)
	PlayersArr.append(newplayer)
	newplayer.AiReflect=AiLevel[currentDifficulty-1][1][0]
	OrderInfo.append(2)
	Ranking.append(2)
	newplayer=AIPlayer.new(3,Player.control_type.AI)
	PlayersArr.append(newplayer)
	newplayer.AiReflect=AiLevel[currentDifficulty-1][2][0]
	OrderInfo.append(3)
	Ranking.append(3)
	
#testing function
func SetMidGameData()->void:
	#won cup 1 in normal, cup 2 in easy, cup 3 in easy
	cupWon[0]=2
	cupWon[2]=1
	cupWon[1]=1
	#update character and cup locks
	CheckCharacterLocks()
	CheckCupLocks()
#complete all cups in hard
func UnlockAll()->void:
	for i in range(len(cupWon)):
		cupWon[i]=3
	CheckCharacterLocks()
	CheckCupLocks()
		
	  
	
func StoreWin()->void:
	CupTimes[currentCup][currentDifficulty-1]=CurrentCupTime
	CurrentCupTime=0
	save_game()
	  
##record new win in cup with current difficulty
func RecordWin()->void:
	if cupWon[currentCup]<currentDifficulty:
		cupWon[currentCup]=currentDifficulty
		

func UpdateInfo()->void:
	currentMap=cupInfo[currentCup][currentStep][0]
	currentLaps=cupInfo[currentCup][currentStep][1]
	current_vehicle=cupInfo[currentCup][currentStep][2]

func ClearPlayers()->void:
	PlayersArr=[]
	Ranking=[]
	OrderInfo=[]

func format_time(msec_total: int) -> String:
	var total_seconds: int = int(msec_total / 1000)
	
	var minutes: int = total_seconds / 60
	var seconds: int = total_seconds % 60
	# Divide by 10 to turn 0-999ms into 0-99cs (2 digits)
	var milliseconds: int = int(msec_total) % 1000 / 10 
	
	return "%02d:%02d:%02d" % [minutes, seconds, milliseconds]
