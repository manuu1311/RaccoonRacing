extends Node

#for which character, is he unlocked?
#0:rocko 1:vixen 2:mambo
#3:pingo 4:hudson 5:banzai
var characterLocks: Array[bool]=[0,0,1,1,1,1]
#current character chosen
var currentCharacter: int=-1
#cup info: lock
var cupLocks: Array[bool]=[0,0,0,0,1,1,1,1]
#cup info: which cups were won, in which difficulty
#0: not won, 1:easy, 2:normal, 3:hard
var cupWon: Array[int]=[0,0,0,0,0,0,0,0]
#current cup chosen
var currentCup: int = -1
#current difficulty chosen
var currentDifficulty: int=-1
var currentMap:int=1
#car/hovercraft mode
enum VehicleType { CAR, HOVERCRAFT }
var current_vehicle: VehicleType = VehicleType.CAR
var PlayersArr:Array[Player]=[]
var OrderInfo:Array[int]=[]

#TODO: actually edit the players
func _ready() -> void:
	PlayersArr.append(Player.new(0,Player.control_type.HUMAN))
	OrderInfo.append(0)
	PlayersArr.append(AIPlayer.new(1,Player.control_type.AI))
	OrderInfo.append(1)
	PlayersArr.append(AIPlayer.new(2,Player.control_type.AI))
	OrderInfo.append(2)
	PlayersArr.append(AIPlayer.new(3,Player.control_type.AI))
	OrderInfo.append(3)

#update character locks, to unlock new characters after each cup
func CheckCharacterLocks()->void:
	#mambo: cup 1,2 easy
	if cupWon[0]>0 and cupWon[1]>0:
		characterLocks[2]=0
	#pingo: cup 2,4 easy
	if cupWon[1]>0 and cupWon[3]>0:
		characterLocks[3]=0
	#hudson: cup 5,6 easy
	if cupWon[4]>0 and cupWon[5]>0:
		characterLocks[4]=0
	#banzai: all cups normal
	var check: bool = true
	for cup in cupWon:
		if cup<2:
			check=false
			break
	if check:
		characterLocks[5]=0
#update cup locks, to unlock new cups
func CheckCupLocks()->void:
	#cup 5: 1,3 easy
	if cupWon[0]>0 and cupWon[2]>0:
		cupLocks[4]=0
	#cup 6: 2,4 easy
	if cupWon[1]>0 and cupWon[3]>0:
		cupLocks[5]=0
	#cup 7: 1 to 6 normal
	var check: bool = true
	for i in range(6):
		var cup: int=cupWon[i]
		if cup<2:
			check=false
			break
	if check:
		cupLocks[6]=0
	#cup 8: 7 normal
	if cupWon[6]>1:
		cupLocks[7]=0

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
		
		
