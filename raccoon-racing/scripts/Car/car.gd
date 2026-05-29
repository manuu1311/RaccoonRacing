extends Node2D

@onready var fl: AnimatedSprite2D = $Visual/Wheels/FL
@onready var fr: AnimatedSprite2D = $Visual/Wheels/FR
@onready var character: Sprite2D = $Visual/Char
@onready var camera: Camera2D = $Camera
var map:Map

var current_vehicle: GameData.VehicleType
var friction:float=0.5
#state: drifting
var bs:bool
#turn drifting threshold
var bsWheelLength :int= 80
#speed drifting threshold
var bsSpeed:int=4
#speed
var speed:Vector2
#speed angle relative to sprite angle (i guess) 
#>0:turning right, <0: turning left
var moveAngCar: int
#sliding angle, >1: right, 0: left
var bsf: bool
#threshold for stopping sliding
var bsClearSpeed:int
#sliding timer
var bsex:int
#car rotation speed
var carRotationWheel: float
#car maximum rotation
var maxRotationWheel: float
#is on ice?
var isAtIce: bool
#locked state
var isLock:bool
#car power
var horse:float
#is the car upside down?
var isBack:float

func steer_left()->void:
    fr.position=Vector2(16.25,-9.7)
    fr.rotation=deg_to_rad(-23.5)
    fl.position=Vector2(-15.25,-9.7)
    fl.rotation=deg_to_rad(-23.5)
    character.position=Vector2(4.5,-5)
    character.rotation=deg_to_rad(-23.5)
    
func steer_right()->void:
    fr.position=Vector2(15.25,-9.7)
    fr.rotation=deg_to_rad(23.5)
    fl.position=Vector2(-16.25,-9.7)
    fl.rotation=deg_to_rad(23.5)
    character.position=Vector2(-4.5,-5)
    character.rotation=deg_to_rad(23.5)
    
func steer_normal()->void:
    fr.position=Vector2(16.25,-12.7)
    fr.rotation=0
    fl.position=Vector2(-15.25,-12.7)
    fl.rotation=0
    character.position=Vector2(0,-4)
    character.rotation=0
    
func _ready() -> void:
    steer_normal()
    current_vehicle=GameData.current_vehicle
    
    
func _physics_process(_delta: float) -> void:
    #-1 for left, 1 for right, 0 for none
    var direction := Input.get_axis("ui_left", "ui_right")
    
    if direction > 0:
        steer_right()
    elif direction < 0:
        steer_left()
    else:
        steer_normal()
        

func Forward()->void:
    #TODO: is this necessary?
    #this.AllWheel();
    if isHovercraft():
        pass
        #TODO: add sound
        #this.playHCRunSound();
    if(not bs and friction > bsWheelLength and speed.length() > bsSpeed):
        bs = true;
        #TODO:add sound
        #this.playBsSound();
        bsf = moveAngCar > 0;

    if(speed.length() < bsClearSpeed):
        bs = false
        
    if(not bs and bsex <= 0):
        if (isAtIce):
            speed += Vector2(horse, 0).rotated(rotation) * 0.5
        else:
            speed += Vector2(horse, 0).rotated(rotation)

    # if difference is too large: spawn smoke
    if get_angle_diff()> deg_to_rad(140) or isLock:
        spawn_smoke('smoke1',true)  
        spawn_smoke('smoke1',false) 

func Backward()->void:
    #is this necessary?
    #this.AllWheel()
    if(not bs and bsex <= 0):
        speed += -Vector2(horse, 0).rotated(rotation)*0.5
    if get_angle_diff()<deg_to_rad(40) or isLock:
        spawn_smoke("smoke1",true)
        spawn_smoke("smoke1",false)

func TurnLeft()->void:
    if(not isLock):
        if(not isBack):
            if get_angle_diff()<deg_to_rad(145):
                rotation_degrees += -min(speed.length() * carRotationWheel,maxRotationWheel)
            #facing downwards:
            else:
               isBack = true;
               rotation_degrees += min(speed.length() * carRotationWheel / 2,maxRotationWheel)
        elif get_angle_diff()<deg_to_rad(60): 
            isBack = false;
            rotation_degrees += - min(speed.length() * carRotationWheel,maxRotationWheel)
        else:
            rotation_degrees += min(speed.length() * carRotationWheel / 2,maxRotationWheel)
        steer_left()

func TurnLRight()->void:
    if(not isLock):
        if(not isBack):
            if get_angle_diff()<deg_to_rad(145):
                rotation_degrees += min(speed.length() * carRotationWheel,maxRotationWheel)
            #facing downwards:
            else:
               isBack = true;
               rotation_degrees += -min(speed.length() * carRotationWheel / 2,maxRotationWheel)
        elif get_angle_diff()<deg_to_rad(60): 
            isBack = false;
            rotation_degrees += min(speed.length() * carRotationWheel,maxRotationWheel)
        else:
            rotation_degrees += -min(speed.length() * carRotationWheel / 2,maxRotationWheel)
        steer_right()

func CancelTurn()->void:
    steer_normal()


func Update():
    if isHovercraft():
        Water()
    if(not isLock):
        UpdateCarPos()
        
    UpdateViewMap()
    UpdateSpeed()
    Jumping()
    Loopsounds()
    var dir_modifier: float = 1.0 if not bsf else -1.0
    if(bs):
        rotation_degrees += 1 * speed.length()*dir_modifier
    if(bsex > 0):
        rotation_degrees += min(bsex,50) * dir_modifier
        bsex-=1
    if(friction > 40 and speed.length() > 2):
        if(speed.length() > bsSpeed):
            if(friction > 60):
                pass
                #TODO: add sound
                #this.playTurnBsSound(0)
            else:
                pass
                #TODO: add sound
                #this.playTurnBsSound(1);
        spawn_smoke("smoke1",moveAngCar > 0)
        if(friction > 70):
            spawn_smoke("smoke1",moveAngCar < 0)
    elif(speed.length() > 0.5):
        pass
        #TODO: necessary?
        #AllWheel()


#get difference beteween speed angle and sprite angle
func get_angle_diff()->float:
    return angle_difference(speed.angle(), rotation)

#spawn smoke particle
func spawn_smoke(type:String, direction:bool)->void:
    pass

#start wheel animation
func StartWheel()->void:
    pass
    
#manage water-related physics
func Water()->void:
    pass

#update car position
func UpdateCarPos()->void:
    pass

#update camera:is it necessary??
func UpdateViewMap()->void:
    pass

func UpdateSpeed()->void:
    pass

func Jumping()->void:
    pass

func Loopsounds()->void:
    pass

#is race type hovercraft?
func isHovercraft()->bool:
    return current_vehicle==GameData.VehicleType.HOVERCRAFT
