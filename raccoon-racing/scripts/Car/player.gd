extends Node2D
class_name  Player

var isResetting:bool=false
#star invincibility (why on player?)
var isInvincible:bool=false
#TODO: what is this?
var isSmallState:bool=false
@onready var car: Car
var PlayerID:int
enum control_type{HUMAN,AI,MULTIPLAYER,RLTRAINING,RL}
var current_control:control_type
##position in the race, int
var current_race_position:int

func _init(id:int,control:control_type) -> void:
    PlayerID=id
    current_control=control

func IsPlayering()->bool:
    return current_control==control_type.HUMAN
    
    
func RunPropBox(x:float,y:float)->void:
    pass
