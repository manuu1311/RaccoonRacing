extends Node2D
class_name Car


@onready var fl: AnimatedSprite2D = $Visual/Car/Wheels/FL
@onready var fr: AnimatedSprite2D = $Visual/Car/Wheels/FR
@onready var rl: AnimatedSprite2D = $Visual/Car/Wheels/RL
@onready var rr: AnimatedSprite2D = $Visual/Car/Wheels/RR
@onready var exhaust_1: Sprite2D = $Visual/Hovercraft/Exhausts/Exhaust1
@onready var exhaust_2: Sprite2D = $Visual/Hovercraft/Exhausts/Exhaust2
@onready var car: Node2D = $Visual/Car
@onready var hovercraft: Node2D = $Visual/Hovercraft
@onready var bottom_effect: Node2D = $Visual/BottomEffect
@onready var top_effect: Node2D = $Visual/TopEffect
@onready var input_handler: InputHandler = $InputHandler
@onready var rollback_synchronizer: RollbackSynchronizer = $RollbackSynchronizer
#character id,to set sprites
var player:Player
var CharID:int=0
var playerID:int=0
@onready var body: Area2D = $Visual/Body
@onready var visual: Node2D = $Visual
@onready var character: Sprite2D = $Visual/Char
var map:Map
@export var playering:bool=true
@onready var sounds: CarSounds = $Sounds
#smoke effects
var smoke_1:Resource=preload("res://Assets/Scenes/Screens/misc/smoke1.tscn")
var smoke_2:Resource=preload("res://Assets/Scenes/Screens/misc/smoke2.tscn")
var carView:Resource
var carViewInstance:Sprite2D
@onready var current_vehicle: GameData.VehicleType=GameData.current_vehicle
@onready var prop_effector: PropEffector = $PropEffector
var friction:float=0
var shrinkscale:float=1
#state: drifting
var bs:bool=false
#turn drifting threshold
var bsWheelLength :int= 80
#speed drifting threshold
var bsSpeed:int=9
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
#car rotation speed
var DefaultRotationWheel: float=1
#car maximum rotation
var DefaultmaxRotationWheel: float=4
#is on ice?
var isAtIce: bool=false
#locked state
var isLock:bool=true
#sleeping
var isSleep:bool
#car power
var horse:float
var carhorse:float=0.3
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
#wall bounce spring
var wallSpring:float
#collision points
var collisionPoints:Array[Node2D]
#player params
var isInvincible:bool=false
var isSmallState:bool=false
var isResetting:bool=false
var IsUseShield:bool=false
var isFcsCar:bool
var controller:CarController
var isfresh:bool
var NowPointId:int
var NowPorpId:int
var StartTick:int=9999999
##ai variables 
var AiNowPushButtonTimeNow:int
var AiNowPushButtonTime:int
var AiNowPushButton:int
var HasProp:bool=false
var AiUsePropTime:int=0

func setup(gamemap:Map,id:int,control:bool,playerinst:Player) -> void:
    map=gamemap
    playerID=id
    player=playerinst
    isFcsCar=control

func _ready() -> void:
    horse=carhorse
    input_handler.setup(player,controller)
    RollbackSyncSetup()
    if isHovercraft():
        car.hide()
        hovercraft.show()
    else:
        car.show()
        hovercraft.hide()
    steer_normal()
    current_vehicle=GameData.current_vehicle
    #get collision points from the car scene
    PopulateCollisions()
    DeferredSetup.call_deferred()


func RollbackSyncSetup()->void:
    rollback_synchronizer.add_input(controller, "forward")
    rollback_synchronizer.add_input(controller, "brake")
    rollback_synchronizer.add_input(controller, "left")
    rollback_synchronizer.add_input(controller, "right")
    rollback_synchronizer.add_input(controller, "special")
    rollback_synchronizer.add_state(self, "AiUsePropTime")
    rollback_synchronizer.add_state(self, "AiNowPushButtonTime")
    rollback_synchronizer.add_state(self, "AiNowPushButton")
    rollback_synchronizer.add_state(self, "HasProp")
    rollback_synchronizer.add_state(self, "AiNowPushButtonTimeNow")
    rollback_synchronizer.add_state(self, "jumpCurrheight")
    rollback_synchronizer.add_state(self, "jumpPrevheight")
    rollback_synchronizer.add_state(self, "bsex")
    rollback_synchronizer.add_state(self, "isBack")
    rollback_synchronizer.add_state(self, "isAtIce")
    rollback_synchronizer.add_state(self, "isInvincible")
    rollback_synchronizer.add_state(self, "isSmallState")
    rollback_synchronizer.add_state(self, "IsUseShield")
    rollback_synchronizer.add_state(self, "isLock")
    rollback_synchronizer.add_state(self, "horse")
    rollback_synchronizer.add_state(self, "shrinkscale")
    rollback_synchronizer.add_state(self, "maxRotationWheel")
    rollback_synchronizer.add_state(self, "carRotationWheel")
    rollback_synchronizer.add_state(self, "NowPointId")
    rollback_synchronizer.add_state(self, "NowPorpId")
    rollback_synchronizer.process_settings()

func DeferredSetup()->void:
    #add car view to minimap
    if isFcsCar:
        carView=preload("res://Assets/Scenes/Screens/maps/CarView.tscn")
    else:
        carView=preload("res://Assets/Scenes/Screens/maps/CarViewOpp.tscn")
    var view_sprite:Sprite2D = map.minimap
    carViewInstance = carView.instantiate()
    view_sprite.add_child(carViewInstance)
    #set variables
    wallSpring=map.Wallspring
    rollGratingNum=map.RollGratingNum
    glideGratingNum=map.GlideGratingNum
    grassGratingNum=map.GrassGratingNum
    SetSprites()
    
    
func PopulateCollisions()->void:
    var collisions_node:Node2D = $Visual/CollisionPoints
    for child:Node in collisions_node.get_children():
        if child is Node2D:
            collisionPoints.append(child)

func steer_left()->void:
    character.position=Vector2(4.5,-5)
    character.rotation=deg_to_rad(-23.5)
    if isHovercraft():
        exhaust_1.position=Vector2(-14,32)
        exhaust_1.rotation=deg_to_rad(20)
        exhaust_2.position=Vector2(8.75,32)
        exhaust_2.rotation=deg_to_rad(20)
    else:
        fr.position=Vector2(16.25,-9.7)
        fr.rotation=deg_to_rad(-23.5)
        fl.position=Vector2(-15.25,-9.7)
        fl.rotation=deg_to_rad(-23.5)
    
func steer_right()->void:
    character.position=Vector2(-4.5,-5)
    character.rotation=deg_to_rad(23.5)
    if isHovercraft():
        exhaust_1.position=Vector2(-8.75,32)
        exhaust_1.rotation=deg_to_rad(-20)
        exhaust_2.position=Vector2(14,32)
        exhaust_2.rotation=deg_to_rad(-20)
    else:
        fr.position=Vector2(15.25,-9.7)
        fr.rotation=deg_to_rad(23.5)
        fl.position=Vector2(-16.25,-9.7)
        fl.rotation=deg_to_rad(23.5)
        
    
func steer_normal()->void:
    character.position=Vector2(0,-4)
    character.rotation=0
    if isHovercraft():
        exhaust_1.position=Vector2(-11,33)
        exhaust_1.rotation=deg_to_rad(0)
        exhaust_2.position=Vector2(11,33)
        exhaust_2.rotation=deg_to_rad(0)
    else:
        fr.position=Vector2(16.25,-12.7)
        fr.rotation=0
        fl.position=Vector2(-15.25,-12.7)
        fl.rotation=0
        

#start wheel spinning
func all_wheel()->void:
    fl.play()
    fr.play()
    rl.play()
    rr.play()
    
func stop_wheel()->void:
    fl.stop()
    fr.stop()
    rl.stop()
    rr.stop()
        

func Forward()->void:
    all_wheel()
    if isHovercraft():
        if isfresh:
            sounds.playHCRunSound()
    if(not bs and friction > bsWheelLength and speed.length() > bsSpeed):
        bs = true;
        if isfresh:
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
    all_wheel()
    if(not bs and bsex <= 0):
        speed += -Vector2(horse, 0).rotated(rotation-PI/2)*0.5
    if abs(get_angle_diff())<40 or isLock:
        spawn_smoke("smoke1",true)
        spawn_smoke("smoke1",false)

func Clearward()->void:
      if isHovercraft():
        if isfresh:
            sounds.stopHCRunSound()



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


func Update(is_fresh:bool)->void:
    isfresh=is_fresh
    if isHovercraft():
        Water()
    if(not isLock):
        UpdateCarPos()
        
    UpdateViewMap()
    UpdateSpeed()
    Jumping()
    #sounds.Loopsounds()
    var dir_modifier: float = 1.0 if bsf else -1.0
    if(bs):
        rotation_degrees += 1 * speed.length()*dir_modifier
    if(bsex > 0):
        rotation_degrees += min(bsex,50) * dir_modifier
        bsex-=1
    if(friction > 40 and speed.length() > 2):
        if(speed.length() > bsSpeed):
            if(friction > 60):
                if isfresh:
                    sounds.playTurnBsSound(0)
            else:
                if isfresh:
                    sounds.playTurnBsSound(1)
        spawn_smoke("smoke1",moveAngCar < 0)
        if(friction > 70):
            spawn_smoke("smoke1",moveAngCar > 0)
    elif(speed.length() < 0.5):
        stop_wheel()
    else:
        all_wheel()

#get difference beteween speed angle and sprite angle
func get_angle_diff()->float:
    return rad_to_deg(angle_difference(speed.angle(), rotation-PI/2))

#spawn smoke particle
func spawn_smoke(type:String, lr:bool)->void:
    if not isfresh:
        return
    if(not isHovercraft() and jumpCurrheight < 1):
        var smokeinst:Node2D
        if type=='smoke1':
            smokeinst=smoke_1.instantiate() as Node2D
        else:
            smokeinst=smoke_2.instantiate() as Node2D
        get_parent().add_child(smokeinst)
        if(lr):
            #spawn in third point, with some offset
            smokeinst.global_position=collisionPoints[2].global_position+Vector2(-5,-7)
        else:
            #spawn in fourth point, with some offset
            smokeinst.global_position=collisionPoints[3].global_position+Vector2(-5,-7)
        smokeinst.scale=scale
        smokeinst.rotation = rotation


    
#manage water-related particles
func Water()->void:
    var targetpos:Vector2
    var smokeinst:Node2D
    var tempscale:float
    if(jumpCurrheight < 1):
        smokeinst=smoke_2.instantiate() as Node2D
        get_parent().add_child(smokeinst)
        if(randi()%2 == 1):
            targetpos=collisionPoints[3].position+Vector2(-7.5,21.5)
        else:
            targetpos=collisionPoints[2].position+Vector2(-11.5,21.5)
        
        tempscale=(randi_range(30, 69)) / 100.0*scale.x
        smokeinst.scale=Vector2(tempscale,tempscale)
        targetpos=to_global(targetpos+Vector2(randi_range(-4, 4),0))
        smokeinst.global_position.x=targetpos.x
        smokeinst.global_position.y=targetpos.y
        smokeinst.rotation=rotation
        #is it true?
        smokeinst.z_index=0

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


func UpdateViewMap()->void:
    carViewInstance.position=map.offset+global_position*map.ScaledTimes
    carViewInstance.rotation=rotation-PI/2

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
        if isfresh:
            sounds.playFastSound()
            sounds.playHCJumpSound()
            sounds.playJumpSound()
        
func Jump(height:float)->void:
    jumpPrevheight = jumpCurrheight
    jumpCurrheight += height
    if isfresh:
        sounds.playHCJumpSound()
    
    
    
func Jumping()->void:
    var temp_height:float = jumpCurrheight
    jumpCurrheight += jumpCurrheight - jumpPrevheight + downWeight
    if(jumpCurrheight > 1):
        z_index=airLayer
    else:
        z_index=1
    if(jumpCurrheight < jumpFloorHeight):
        if(jumpFloorHeight - jumpCurrheight > 0.5):
            if isfresh:
                sounds.playHCEndJumpSound()
            
        jumpCurrheight = (- jumpCurrheight) * jumpSpring
        jumpPrevheight = (- temp_height) * jumpSpring
    else:
        jumpPrevheight = temp_height
    jumpFloorHeight = 0 
    var visual_scale:float = 1.0 + (jumpCurrheight * 0.0175)
    visual.scale = Vector2(visual_scale*shrinkscale, visual_scale*shrinkscale)



func GetHitCar()->void:
    var overlapping_areas:Array[Area2D] = body.get_overlapping_areas()
    for area:Area2D in overlapping_areas:
        if area.is_in_group("Body"):
            #calculate collisions
            var caropp:Car=area.get_parent().get_parent() as Car
            #not sure
            if playerID < caropp.playerID:
                BeAttacked(caropp,isfresh)

   
 
func GetGrassStatus(tx:float, ty:float)->void:
    if(jumpCurrheight > heightOverWall) or isResetting:
        return 
        
    var numGrassHits:int = 0
    #each point in the car
    var point:int = 1
    var lineCollided:EdLine
    #calculate which points collide with grass
    while(point < 5):
        #point to global
        var pt:Vector2 = collisionPoints[point-1].position
        #_loc3_ = this.ToPointNow(this.Dmc["point" + _loc2_]._x,this.Dmc["point" + _loc2_]._y);
        pt+=Vector2(tx,ty)
        lineCollided=map.edm.getHitFace(pt)
        if(lineCollided!=null):
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
    if(jumpCurrheight> heightOverWall or isResetting):
        return 
        
    var pointid:int = 1
    var pointpos:Vector2
    var point: Node2D
    var collided: EdLine
    while(pointid < 5):
        point=collisionPoints[pointid-1]
        pointpos=point.position+Vector2(tx,ty)
        collided=map.edevent.getHitFace(pointpos)
        if(collided!=null):
            map.GetHitEventStatus(collided.getId(),playerID,isfresh)
            return
        pointid+=1
    

#maybe returns wall angle?
func GetHitStatusAng(tx:float,ty:float)->float:
    for point:Node2D in collisionPoints:
        var pointpos:Vector2=point.position
        pointpos+=Vector2(tx,ty)
        var lineCollided:EdLine = map.ed.getHitFace(pointpos)
        if(lineCollided!=null):
            for jumpCoord:int in map.canBeJumpWall:
                if (jumpCurrheight>heightOverWall and jumpCoord==lineCollided.getId()):
                    return NAN
            return (lineCollided.GetAngle())
    return NAN
    
    
#flash's 0 deg should be equal to godot's 90 deg
func GetHitStatus(tx:float, ty:float)->void:
    var wallAngledeg:float =GetHitStatusAng(tx,ty)
    #no wall detected
    if(is_nan(wallAngledeg)):
        return 
    if isfresh:
        sounds.playbumpsound()
    var speedangle:float=speed.angle()
    var wallAngle :float= deg_to_rad(wallAngledeg)
    var speedwallangle:float=wrapf(
        -2*rad_to_deg(speedangle-wallAngle),
        -180.0,
        180.0
    )
    #-pi/2 to account for godot's angle system
    var poswallangle:float=wrapf(
        rad_to_deg(wallAngle-rotation-PI/2),
        -180.0,
        180.0
    )
    var speedwallangle90:float=fmod(rad_to_deg(speedangle-wallAngle),180.0)
    if speedwallangle90>90:
        speedwallangle90=180-speedwallangle90
    if speedwallangle90<-90:
        speedwallangle90+=180
    speedwallangle90=abs(speedwallangle90)
    if(poswallangle >= 0 and poswallangle < 45 or poswallangle < -135):
        rotation_degrees+=(speed.length()+1)*0.02/wallSpring
    if(poswallangle < 0 and poswallangle > -45 or poswallangle > 135):
        rotation_degrees-=(speed.length()+1)*0.02/wallSpring
    var loc1:float=wrapf(
        rad_to_deg(speedangle-wallAngle),
        -180.0,
        180
    )
    if(not (loc1>0 and loc1<180)):
        if(abs(speedwallangle) < 60):
            speedwallangle *=0.5
        speed=speed.rotated(deg_to_rad(speedwallangle))
    var wall_hit_factor:float = 1.0 - wallSpring * (speedwallangle90 * abs(abs(poswallangle) - 90) / 90.0)
    wall_hit_factor = clamp(wall_hit_factor, -5.0, 5.0)
    speed *= wall_hit_factor
    speed+=(Vector2(0.1,0).rotated(deg_to_rad(wallAngledeg+90)))
    stepx = int(speed.x * 10.0) / 10.0
    stepy = int(speed.y * 10.0) / 10.0
    tempx = position.x + stepx
    tempy = position.y + stepy


func BeAttacked(who: Car,_is_fresh:bool=true)->void:
    if(who.jumpCurrheight > heightOverWall or jumpCurrheight > heightOverWall):
        return 
    if(isResetting or who.isResetting):
        return 
    if isfresh:
        sounds.playbumpsound()
    var isInvincibletemp:bool = isInvincible
    var enemyInvincible:bool = who.isInvincible;
    if(isSmallState):
        enemyInvincible = true
    if(who.isSmallState):
        isInvincibletemp = true
   
    var enemySpeed:Vector2
    if(not (isInvincibletemp and not enemyInvincible)):
        enemySpeed = who.speed
    var mySpeed:Vector2
    if(not(not isInvincibletemp and enemyInvincible)):
        mySpeed = speed
    #distance between cars
    var dist:Vector2=global_position-who.global_position
    var distsq:float = dist.length_squared()
    var spring:float = 0.005
    if(distsq < 2000):
        spring = 0.005 + 0.05 * (2000 - distsq) / 2000
    #push vector
    var pushvector:Vector2 = dist*spring
    #if enemy is invincible and im not: massive knockback
    if(not isInvincibletemp and enemyInvincible):
        speed = enemySpeed+pushvector*40
        bs = true
        if isfresh:
            sounds.playBsSound()
    #if im invincible and enemy is not: give massive knockback
    elif(isInvincibletemp and not enemyInvincible):
        who.speed = mySpeed-pushvector*40
        who.bs = true
        if isfresh:
            sounds.playBsSound()
    #no one is invincible
    else:
        speed = enemySpeed+pushvector
        who.speed = mySpeed-pushvector

func Reset(newpos:Vector2,newangle:float)->void:
    global_position=newpos
    rotation=newangle
    scale=Vector2(1,1)
    visual.scale=Vector2(1,1)
    jumpCurrheight=0
    jumpPrevheight=0
    Update(isfresh);

func SetOnIce()->void:
    if isInvincible:
        return
    isAtIce=true
    maxRotationWheel = DefaultmaxRotationWheel* 1.2;
    carRotationWheel = DefaultRotationWheel * 1.2;
    glideGratingNum = 0;
    rollGratingNum = 0;
    grassGratingNum = 0;
    wallSpring = 0.5;
    
func OutOfIce()->void:
    maxRotationWheel = DefaultmaxRotationWheel
    carRotationWheel = DefaultRotationWheel 
    isAtIce=false
    wallSpring=map.Wallspring
    rollGratingNum=map.RollGratingNum
    glideGratingNum=map.GlideGratingNum
    grassGratingNum=map.GrassGratingNum

func SetSprites()->void:
    var basepath:String="res://Assets/Images/Vehicles/Cars/"
    var charname:String
    if CharID==1:
        charname='raccoon'
    elif CharID==2:
        charname='cat'
    elif CharID==3:
        charname='bear'
    elif CharID==4:
        charname='penguin'
    elif CharID==5:
        charname='dog'
    elif CharID==6:
        charname='panda'
    var base: Sprite2D = $Visual/Car/Base
    base.texture=load(basepath+charname+'/base.png')
    var hc: Sprite2D = $Visual/Hovercraft/Base
    hc.texture=load(basepath+charname+'/hovercraft.png')
    exhaust_1.texture=load(basepath+charname+'/hcback.png')
    exhaust_2.texture=load(basepath+charname+'/hcback.png')
    character.texture=load(basepath+charname+'/char.png')
    


#is race type hovercraft?
func isHovercraft()->bool:
    return current_vehicle==GameData.VehicleType.HOVERCRAFT
