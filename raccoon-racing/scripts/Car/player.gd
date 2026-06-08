extends Node2D
class_name  Player

var playerID:int=0
var isResetting:bool=false
#star invincibility (why on player?)
var isInvincible:bool=false
#TODO: what is this?
var isSmallState:bool=false
@onready var sounds: CarSounds = $"../Sounds"
@onready var car: Car = $".."
@export var playering:bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    Game.register(self)
    #TODO: playering should be set by general game script
    if playering:
        FocusPlayer()
  
    
func _process(_delta: float) -> void:
    #TODO: use actual ai flag
    if not playering:
        car.Update()
        return
    var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

    # Handle Steering (X-axis)
    if input_dir.x > 0:
        car.TurnLRight()
    elif input_dir.x < 0:
        car.TurnLeft()
    else:
        car.CancelTurn()

    # Handle Throttle/Brake (Y-axis)
    if input_dir.y < 0:
        car.Forward()  # In Godot 2D, negative Y is UP
    elif input_dir.y > 0:
        car.Backward()
    else:
        car.Clearward()
    car.Update()
    
    
    

func FocusPlayer():
    playering=true
    car.playering=true
    Game.focusCar(car)
