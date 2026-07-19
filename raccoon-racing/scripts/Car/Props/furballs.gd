extends Prop
class_name FurballsProp

var FurballArr:Array[FurballsInMap]=[]
var Furballs1:Resource;
var PId:int;
var end_tick: int
var ended: bool = false


func _init(playerinst:Player)->void:
	Furballs1=preload("res://Assets/Scenes/Screens/maps/Props/FurballsInMap.tscn")
	super(playerinst)
	proptype = 9;
	FurballArr = []
	player.car.sounds.playCatSSound();
	var _loc4_:int = 0;
	var _loc5_:Vector2;
	end_tick = NetworkTime.tick + int(NetworkTime.tickrate * 30.0)
	for i in range(6):
		var furballinst: FurballsInMap = Furballs1.instantiate() as FurballsInMap
		player.car.map.add_child(furballinst)
		furballinst.setup(player.car.map, false, false)
		furballinst.speed = player.car.speed
		furballinst.petrolength = 10
		furballinst.petrowidth = 0.5
		furballinst.player = player

		var offset: Vector2 = Vector2(0, 25).rotated(deg_to_rad(i * 360.0 / 6.0))  # fixed: was discarded before
		var pos: Vector2 = player.car.global_position + offset
		furballinst.reset(pos.x, pos.y, player.car.rotation + deg_to_rad(60.0 * i))
		furballinst.pid = i
		FurballArr.append(furballinst)
	
	
func run_tick(tick: int, is_fresh: bool) -> void:
	if ended:
		return
	if tick >= end_tick:
		ended = true
		if is_fresh:
			_expire()

func _expire() -> void:
	if is_instance_valid(player.car):
		player.prop.Delprop(self)
		for furball in FurballArr:
			if is_instance_valid(furball):
				furball.queue_free()
		FurballArr.clear()

func delme()->void:
	await player.car.get_tree().create_timer(30).timeout
	if is_instance_valid(player.car):
		player.prop.Delprop(self)
	
	
func del()->void:
	for furball in FurballArr:
		if is_instance_valid(furball):
			furball.queue_free()
	FurballArr.clear()
