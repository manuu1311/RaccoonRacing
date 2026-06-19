extends MoveObject
class_name MissileInMap

var onhitstatfun:Callable
var onhitcarfun:Callable
var petrolength:int=0
var petrowidth:int=0
var horse:Vector2
var WheelLengthNum:float=0.5
var MaxWheelLength:int=10
var SpeedHorse:int=1
const effect:Resource=preload("res://Assets/Scenes/Screens/PropEffects/Petro.tscn")
@onready var bottom_effect: Node2D = $BottomEffect


func _ready() -> void:
    horse=Vector2(SpeedHorse,0)

func reset(x:float,y:float,r:float)->void:
      global_position=Vector2(x,y)
      rotation=r
      Update();

func _process(_delta: float) -> void:
    return

func Update()->void:
    UpdateCarPos();
    UpdateSpeed();
    
    
func DoAction(action:int)->void:
    match(action):
         0:
            Forward()
         2:
            TurnLeft();
         3:
            TurnRight();

func Forward()->void:
    speed+=horse.rotated(rotation-PI/2)
func TurnLeft()->void:
    rotation_degrees += - min(
        speed.length() * WheelLengthNum,MaxWheelLength
        )

func TurnRight()->void:
    rotation_degrees += + min(
        speed.length() * WheelLengthNum,MaxWheelLength
        )

func AddPetro()->void:
    var boost: Node2D = effect.instantiate() as Node2D
    
    boost.rotation=rotation
    boost.global_position=global_position
    boost.global_position += Vector2(0,randf_range(-5.0, 5.0)).rotated(boost.rotation)
    var base_scale := (randi() % 60 + 40) * 0.7 / 100.0
    boost.scale = Vector2.ONE * base_scale
    bottom_effect.add_child(boost)
    #boost.top_level = true
