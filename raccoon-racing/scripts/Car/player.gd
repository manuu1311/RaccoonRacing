extends Node2D
class_name  Player

var isResetting:bool=false
#star invincibility (why on player?)
var isInvincible:bool=false
#TODO: what is this?
var isSmallState:bool=false
var car: Car
var PlayerID:int
enum control_type{HUMAN,AI,MULTIPLAYER,RLTRAINING,RL}
var current_control:control_type
##position in the race, int
var current_race_position:int
##different playering and ais(for difficulty i guess?)
var player_type:int

func _init(id:int,control:control_type) -> void:
    PlayerID=id
    current_control=control

func IsPlayering()->bool:
    return current_control==control_type.HUMAN
    
    
func RunPropBox(x:float,y:float)->void:
    car.sounds.GetProp()
    #if(this.prop.NowPorpId != 0):
        #return 
    #var _loc2_ = 1500;
    #var _loc3_ = this.GetPropPer();
    #if(this.PorpBoxRunTimerId)
    #{
        #as.Timer.DelTimer(this.PorpBoxRunTimerId);
    #}
    #this.PorpBoxRunTimerId = as.Timer.AddTimer(this,"GetProp",_loc2_,_loc3_);
    #this.game.uiManage.StartPropBox(_loc2_,_loc3_);
    #this.game.uiManage.propmove(x,y);
