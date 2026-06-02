extends Node2D
class_name Car

@onready var visual: Node2D = $Visual
@onready var fl: AnimatedSprite2D = $Visual/Wheels/FL
@onready var fr: AnimatedSprite2D = $Visual/Wheels/FR
@onready var character: Sprite2D = $Visual/Char
@onready var camera: Camera2D = $Camera
var map:Map
@onready var player: Player = $Player
@onready var sounds: CarSounds = $Sounds

var current_vehicle: GameData.VehicleType
var friction:float=0
#state: drifting
var bs:bool=false
#turn drifting threshold
var bsWheelLength :int= 80
#speed drifting threshold
var bsSpeed:int=4
#speed
var speed:Vector2=Vector2.ZERO
#speed angle relative to sprite angle (i guess) 
#>0:turning right, <0: turning left
var moveAngCar: float=0
#sliding angle, >1: right, 0: left
var bsf: bool=0
#threshold for stopping sliding
var bsClearSpeed:int=3
#sliding timer
var bsex:int=0
#car rotation speed
var carRotationWheel: float=1
#car maximum rotation
var maxRotationWheel: float=4
#is on ice?
var isAtIce: bool=false
#locked state
var isLock:bool=false
#car power
var horse:float=0.3
#is the car upside down?
var isBack:bool
#step movement in frame
var stepx:float=1
var stepy:float=1
#temporary new position, before checking collisions
var tempx:float=0
var tempy:float=0
#height from the ground, flying if >1
var jumpCurrheight:float=0
#previous jump height
var jumpPrevheight:float
#rolling resistance
var rollGratingNum:float
#gliding resistance
var glideGratingNum:float
#grass resistance
var grassGratingNum:float
#jump threshold (i guess?)
var heightOverWall:int = 10
#jump floor height
var jumpFloorHeight: int=0
#jump bounciness
var jumpSpring:float=0.5
#jump speed
var jumpspeed:float = 0.05
#gravity
var downWeight:float=-0.1
#z layer for jumping
var airLayer: int=10
#collision points
var collisionPoints:Array[Vector2]

func _ready() -> void:
    #TODO: register only playering player
    Game.focusCar(self)
    steer_normal()
    current_vehicle=GameData.current_vehicle
    #TODO:actual values
    #rollGratingNum=map.rollGratingNum
    #glideGratingNum=map.glideGratingNum
    #grassGratingNum=map.grassGratingNum
    glideGratingNum = 0.0002
    rollGratingNum = 0.02
    grassGratingNum = 0.01


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

    
    
func _process(_delta: float) -> void:
    var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

    # Handle Steering (X-axis)
    if input_dir.x > 0:
        TurnLRight()
    elif input_dir.x < 0:
        TurnLeft()
    else:
        CancelTurn()

    # Handle Throttle/Brake (Y-axis)
    if input_dir.y < 0:
        Forward()  # In Godot 2D, negative Y is UP
    elif input_dir.y > 0:
        Backward()
    else:
        Clearward()
    Update()
        

func Forward()->void:
    #TODO: is this necessary?
    #this.AllWheel();
    if isHovercraft():
        sounds.playHCRunSound()
    if(not bs and friction > bsWheelLength and speed.length() > bsSpeed):
        bs = true;
        sounds.playBsSound()
        bsf = moveAngCar > 0;

    if(speed.length() < bsClearSpeed):
        bs = false
        
    if(not bs and bsex <= 0):
        if (isAtIce):
            speed += Vector2(horse,0).rotated(rotation-PI/2) * 0.5
        else:
            speed += Vector2(horse,0).rotated(rotation-PI/2)

    # if difference is too large: spawn smoke
    if abs(get_angle_diff())> 140 or isLock:
        spawn_smoke('smoke1',true)  
        spawn_smoke('smoke1',false) 

func Backward()->void:
    #is this necessary?
    #this.AllWheel()
    if(not bs and bsex <= 0):
        speed += -Vector2(horse, 0).rotated(rotation-PI/2)*0.5
    if abs(get_angle_diff())<40 or isLock:
        spawn_smoke("smoke1",true)
        spawn_smoke("smoke1",false)

func Clearward()->void:
      if isHovercraft():
        pass
        #TODO: stop engine sound
        #this.stopHCRunSound();



func TurnLeft()->void:
    if(not isLock):
        if(not isBack):
            if abs(get_angle_diff())<145:
                rotation_degrees += -min(speed.length() * carRotationWheel,maxRotationWheel)
            #facing downwards:
            else:
               isBack = true;
               rotation_degrees += min(speed.length() * carRotationWheel / 2,maxRotationWheel)
        elif abs(get_angle_diff())<60: 
            isBack = false;
            rotation_degrees += - min(speed.length() * carRotationWheel,maxRotationWheel)
        else:
            rotation_degrees += min(speed.length() * carRotationWheel / 2,maxRotationWheel)
        steer_left()

func TurnLRight()->void:
    if(not isLock):
        if(not isBack):
            if abs(get_angle_diff())<145:
                rotation_degrees += min(speed.length() * carRotationWheel,maxRotationWheel)
            #facing downwards:
            else:
               isBack = true;
               rotation_degrees += -min(speed.length() * carRotationWheel / 2,maxRotationWheel)
        elif abs(get_angle_diff())<60: 
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
    sounds.Loopsounds()
    var dir_modifier: float = 1.0 if not bsf else -1.0
    if(bs):
        rotation_degrees += 1 * speed.length()*dir_modifier
    if(bsex > 0):
        rotation_degrees += min(bsex,50) * dir_modifier
        bsex-=1
    if(friction > 40 and speed.length() > 2):
        if(speed.length() > bsSpeed):
            if(friction > 60):
                sounds.playTurnBsSound(0)
            else:
                sounds.playTurnBsSound(1)
        spawn_smoke("smoke1",moveAngCar > 0)
        if(friction > 70):
            spawn_smoke("smoke1",moveAngCar < 0)
    elif(speed.length() > 0.5):
        pass
        #TODO: necessary?
        #AllWheel()


#get difference beteween speed angle and sprite angle
func get_angle_diff()->float:
    return rad_to_deg(angle_difference(speed.angle(), rotation-PI/2))

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
    GetHitCar()
    stepx=snapped(speed[0],0.1)
    stepy=snapped(speed[1],0.1)
    tempx = position.x + stepx
    tempy = position.y + stepy
    GetGrassStatus(tempx,tempy)
    GetHitEvent(tempx,tempy)
    GetHitStatus(tempx,tempy)
    position.x = tempx
    position.y = tempy

#update camera:is it necessary??
func UpdateViewMap()->void:
    pass

func UpdateSpeed()->void:
    var dir:int
    if(jumpCurrheight < 1):
        moveAngCar = (get_angle_diff())
        friction = abs(moveAngCar)
        if(friction > 90):
            friction = 180 - friction;
        var dragFactor:float=rollGratingNum + int(friction) * glideGratingNum
        speed *= max(0.0, 1.0 - dragFactor)
        if(moveAngCar < 90 and moveAngCar > 0 or moveAngCar < -90):
            dir = -1;
        else:
            dir = 1;
        #calculate magnitude and direction of force
        var slide_magnitude: float = speed.length() * (glideGratingNum * int(90 - friction))
        var slide_force: Vector2 = speed.orthogonal() * dir
        slide_force = slide_force.normalized() * slide_magnitude

        #apply the force
        speed += slide_force


#jump mechanic related to speed
func JumpBySpeed(height:float)->void:
    if(jumpCurrheight < heightOverWall):
        jumpCurrheight += height * speed.length() * jumpspeed;
        sounds.playFastSound()
        sounds.playHCJumpSound()
        sounds.playJumpSound()
        
func Jump(height:float)->void:
    jumpPrevheight = jumpCurrheight
    jumpCurrheight += height
    sounds.playHCJumpSound()
    
    
    
func Jumping()->void:
    var temp_height:float = jumpCurrheight
    jumpCurrheight += jumpCurrheight - jumpPrevheight + downWeight
    if(jumpCurrheight > 1):
        z_index=airLayer
    #TODO: should it be removed?
    else:
        z_index=0
    if(jumpCurrheight < jumpFloorHeight):
        if(jumpFloorHeight - jumpCurrheight > 0.5):
            sounds.playHCEndJumpSound()
            
        jumpCurrheight = (- jumpCurrheight) * jumpSpring
        jumpPrevheight = (- temp_height) * jumpSpring
    else:
        jumpPrevheight = temp_height
    jumpFloorHeight = 0 
    var visual_scale = 1.0 + (jumpCurrheight * 0.0175)
    visual.scale = Vector2(visual_scale, visual_scale)



func GetHitCar()->void:
    for other_player in Game.players:
        if(other_player.playerID != player.playerID):
            pass
            #if point collides with other players' points
            #if(this.Dmc.body.hitTest(this.game.Players[_loc2_].myCar.Dmc.body)):
                #calculate collisions
                #this.BeAttacked(this.game.Players[_loc2_].myCar)

   
 
func GetGrassStatus(tx:float, ty:float)->void:
    if(jumpCurrheight > heightOverWall) or player.isResetting:
        return 
        
    var numGrassHits:int = 0
    #each point in the car
    var point:int = 1
    #TODO: result of gethitface, where is it in swf?
    var isCollision
    #TODO:remove
    return
    #calculate which points collide with grass
    while(point < 5):
        #point to global
        var global_pt:Vector2 = to_global(collisionPoints[point])
        #_loc3_ = this.ToPointNow(this.Dmc["point" + _loc2_]._x,this.Dmc["point" + _loc2_]._y);
        global_pt+=Vector2(tx,ty)
        #TODO: find the actual function
        isCollision=map.getHitFace(global_pt)
        #_loc4_ = this.map.edm.GetHitFace(_loc6_,_loc5_)
        if(isCollision != null):
            numGrassHits += 1
        point += 1
    #if no point collides: return
    if(numGrassHits == 0):
            return
    #else, slow down       
    speed *= (1.0 - grassGratingNum * numGrassHits)
    stepx = snapped(speed.x, 0.1)
    stepy = snapped(speed.y, 0.1)
    tempx = position.x + stepx;
    tempy = position.y + stepy;
    
    
func GetHitEvent(tx:float, ty:float)->void:
    pass
func GetHitStatus(tx:float, ty:float)->void:
    pass

#is race type hovercraft?
func isHovercraft()->bool:
    return current_vehicle==GameData.VehicleType.HOVERCRAFT
