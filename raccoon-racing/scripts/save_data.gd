class_name SaveData
extends Resource

@export var characterLocks: Array[bool] = [false, false, true, true, true, true]
@export var cupLocks: Array[bool] = [false, false, false, false, true, true, true, true]
@export var cupWon: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0]

@export var BestTimes: Array[Array] = [
	[0, 0],
	[0, 0], [0, 0],
	[0, 0], [0, 0]
]

@export var CupTimes: Array[Array] = [
	[0, 0, 0], [0, 0, 0],
	[0, 0, 0], [0, 0, 0],
	[0, 0, 0], [0, 0, 0],
	[0, 0, 0], [0, 0, 0],
]
