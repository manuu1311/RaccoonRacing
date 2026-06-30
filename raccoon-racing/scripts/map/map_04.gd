extends Map


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	ScaledTimes=0.02857142857142857
	offsetcar=Vector2(76.5,-44.5)*ScaledTimes
	offsethc=Vector2(395,168)*ScaledTimes
	
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
	MapBy = 1237;
	MapTy = -1232;
	MapLx = -2088;
	MapRx = 2090;
	IsHovercraft=GameData.current_vehicle==GameData.VehicleType.HOVERCRAFT
	ed=Ed.new()
	edm=Ed.new()
	edevent=Ed.new()
	InitMap()
	if(IsHovercraft):
		LinePointArr = [2,8,10,14,17]
		WanPointArr = [0,1,3,5,7,9,11,13,15,16]
		PropPointArr = [0,1,8,9,14,16,17]
	else:
		LinePointArr =  [3,13,19]
		WanPointArr =  [0,1,2,4,5,6,7,8,9,10,11,12,14,15,16,17,18,19,20,21,22]
		PropPointArr = [0,2,4,9,13,18,20,21]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
