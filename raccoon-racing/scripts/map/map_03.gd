extends Map


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	offsethc=Vector2(-3.3,-67)*ScaledTimes
	offsetcar=-Vector2(67,80)*ScaledTimes
	ScaledTimes=0.02857142857142857
	SetBoundaries()
	JumpWallGroupNum = 10
	JumpWallNum = 200;
	WallGroupNum = 10;
	WallNum = 200;
	GrassNum = 200;
	GroupGrassNum = 200;
	GroupGrassGroupNum = 10;
	PointNum = 50;
	PropboxNum = 70;
	JumpNum = 10;
	AddspeedNum = 10;
	BsNum = 10;
	GlideGratingNum = 0.0001;
	RollGratingNum = 0.02;
	GrassGratingNum = 0.01;
	Wallspring = 0.02;
	MapBy = 2100;
	MapTy = -2058;
	MapLx = -2088;
	MapRx = 2108;
	IsHovercraft=GameData.current_vehicle==GameData.VehicleType.HOVERCRAFT
	ed=Ed.new()
	edm=Ed.new()
	edevent=Ed.new()
	InitMap()
	if(IsHovercraft):
		LinePointArr = [0,5,6,11,13,21,22,23,24]
		WanPointArr = [1,2,3,4,7,8,10,11,12,15,17,18,19,20,21,22,23]
		PropPointArr = [1,5,8,12,19,23]
	else:
		LinePointArr =  [0,5,8,9,12,13,15,17,18,19,20,21]
		WanPointArr =  [0,1,2,3,6,7,10,11,14,16,18,22]
		PropPointArr = [0,3,5,8,13,15,18,20,22]



func SetBoundaries()->void:
	boundaries=[-2537,-2449,2537,2449]
