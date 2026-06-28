extends Map


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	ScaledTimes=0.02857142857142857
	offsethc=Vector2(-22.8,12)*ScaledTimes
	offsetcar=Vector2(-22.8,12)*ScaledTimes
	JumpWallGroupNum = 10
	JumpWallNum = 200;
	WallGroupNum = 10;
	WallNum = 200;
	GrassNum = 0;
	GroupGrassNum = 0;
	GroupGrassGroupNum = 0;
	PointNum = 50;
	PropboxNum = 70;
	JumpNum = 10;
	AddspeedNum = 10;
	BsNum = 10;
	GlideGratingNum = 0.0002;
	RollGratingNum = 0.02;
	GrassGratingNum = 0.01;
	Wallspring = 0.02;
	MapBy = 2035;
	MapTy = -2010;
	MapLx = -2100;
	MapRx = 2075;
	IsHovercraft=GameData.current_vehicle==GameData.VehicleType.HOVERCRAFT
	ed=Ed.new()
	edm=Ed.new()
	edevent=Ed.new()
	InitMap()
	if(IsHovercraft):
		LinePointArr = [8,26,27]
		WanPointArr = [0,2,3,4,7,8,10,11,13,17,19,22,26,29,3]
		PropPointArr = [3,8,12,23,31]
	else:
		LinePointArr =  [0,1,2,12,13,26,34,35,39,40,42]
		WanPointArr =  [0,3,4,12,18,19,24,25,28,29,30,31,32,33,34,38,41]
		PropPointArr = [0,6,12,18,24,29,37,40]
