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

#unlock all characters
func UnlockAllChars():
	for i in range(len(characterLocks)):
		characterLocks[i]=false

#unlock all characters
func UnlockAllCups():
	#unlock all cups
	for i in range(len(cupLocks)):
		cupLocks[i]=false
	#set all cups won in hard
	for i in range(len(cupWon)):
		cupWon[i]=3
	


#testing function
func MidGameData():
	#won cup 1 in normal, cup 2 in easy, cup 3 in easy
	cupWon[0]=2
	cupWon[2]=1
	cupWon[1]=1
	
