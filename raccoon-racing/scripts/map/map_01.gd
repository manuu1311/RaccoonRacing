#extends "res://scripts/map/map.gd"
extends Map

"""
offset info: 
	car: +116,+341->3.867, 11.367
"""


func _ready() -> void:
	super()
	#exporting: 0.06666666666666666
	#ScaledTimes=0.03333333333333333
	ScaledTimes= 0.03476
	SetBoundaries()
	offsethc=Vector2(1.5,0)
	offsetcar=Vector2(-4.233,-11.67)
	JumpWallGroupNum = 10
	JumpWallNum = 100;
	WallGroupNum = 10;
	WallNum = 100;
	GrassNum = 0;
	GroupGrassNum = 0;
	GroupGrassGroupNum = 0;
	PointNum = 50;
	PropboxNum = 20;
	JumpNum = 10;
	AddspeedNum = 10;
	BsNum = 10;
	GlideGratingNum = 0.0002;
	RollGratingNum = 0.02;
	GrassGratingNum = 0.01;
	Wallspring = 0.02;
	MapBy = 1700;
	MapTy = -1700;
	MapLx = -1700;
	MapRx = 1700;
	IsHovercraft=GameData.current_vehicle==GameData.VehicleType.HOVERCRAFT
	ed=Ed.new()
	edm=Ed.new()
	edevent=Ed.new()
	InitMap()
	if(IsHovercraft):
		LinePointArr = [0,2,3,4,5,8,9,11,17]
		WanPointArr = [0,1,2,4,7,8,11,13,14,15,16,17]
		PropPointArr = [1,8,13]
	else:
		LinePointArr =  [0,2,3,4,5,6,7,8,9,15,17,19,21,23]
		WanPointArr =  [0,1,8,9,10,11,12,14,16,18,20,22,23,24]
		PropPointArr = [1,4,8,9,10,11,12,14,16,18,20,22,23]



func SetBoundaries()->void:
	boundaries=[-1980,-2115,1960,2030]
