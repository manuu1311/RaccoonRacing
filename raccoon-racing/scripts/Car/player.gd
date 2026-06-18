extends Node2D
class_name  Player

var car: Car
var PlayerID:int
#TODO: should be set by game manager
##character id 1-6
var charid:int=1
enum control_type{HUMAN,AI,MULTIPLAYER,RLTRAINING,RL}
var current_control:control_type
##position in the race, int
var current_race_position:int
var alldistance:int
var prop:PropManager
var PropBoxRunTimerId:int=-1
var CanUseProp:bool=false
var IsUsingProp:bool=false

func _init(id:int,control:control_type) -> void:
    PlayerID=id
    current_control=control
    prop=PropManager.new(self)
    

func SetCar(carinst:Car)->void:
    car=carinst
    car.prop_hud.prop_visible.connect(ResetUse)

func IsPlayering()->bool:
    return current_control==control_type.HUMAN
    
    
func Update()->void:
    car.Update()
    prop.run() 
    UpdatePoint()
  

func UpdatePoint()->void:
    pass

 
func RunPropBox(x:float,y:float)->void:
    car.sounds.GetProp()
    if not car.prop_hud.itemready:
        car.prop_hud.propmove(x,y)
    if prop.NowPorpId!=0:
        return
    GetProp(GetPropPer())
    car.prop_hud.StartPropBox(1.5,prop.NowPorpId)


            

func GetProp(propid:int)->void:
    prop.NowPorpId=propid

func ClearPropBox(id:int)->void:
    car.prop_hud.PropUsed(id)


func GetPropPer()->int:
    return 1
    #return randi_range(0,8)

func ResetUse()->void:
    CanUseProp=true

func UseProp()->void:
    if(IsPlayering() && not car.isSleep and CanUseProp and !IsUsingProp):
        prop.UseProp()
        CanUseProp=false
