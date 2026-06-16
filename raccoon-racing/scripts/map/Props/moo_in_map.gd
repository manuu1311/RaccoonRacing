extends Node2D
class_name MoveObject

var friction:float
var CarMoveAngofCarAng:float
var IsHitCar:bool
var IsHitWall:bool
var speed:Vector2
var bsEx:float
var map:Map
var stepx:float
var stepy:float
var tempx:float;
var tempy:float;
var moveAngCar:float
var collisions:Array[Marker2D]

@onready var body: Area2D = $Body


func setup(mapinst:Map,ishitcar:bool,ishitwall:bool)->void:
    #change sprite
    if GameData.currentMap==0:
        $Visual.texture=preload("res://Assets/Images/maps/Props/frisbee.png")
        scale=Vector2(0.65,0.65)
        modulate=Color(1,1,0.66,1)
        for i in range(4):
            collisions.append(get_node("Collisions/CollisionPoint"+str(i+1)))
    else:
        $Visual.texture=preload("res://Assets/Images/maps/Props/moo.png")
        scale=Vector2(1.0,1.0)
        collisions.append(get_node("Collisions/CollisionPoint0"))
    map=mapinst
    IsHitCar=ishitcar
    IsHitWall=ishitwall
    bsEx=0
    friction=0
    stepx=0
    stepy=0
    tempx=0
    tempy=0
    speed=Vector2.ZERO
    

func _process(_delta: float) -> void:
    UpdateCarPos();
    UpdateSpeed();
    if(bsEx > 0):
        rotation_degrees += min(bsEx,30);
        bsEx = bsEx - 1;
   
func UpdateCarPos()->void:
    GetHitCar();
    stepx = int(speed.x * 10) / 10;
    stepy = int(speed.y * 10) / 10;
    tempx = position.x + stepx;
    tempy = position.y + stepy;
    GetHitStatus(tempx,tempy);
    position = Vector2(tempx,tempy)

func GetHitCar()->void:
    var overlapping_areas:Array[Area2D] = body.get_overlapping_areas()
    for area:Area2D in overlapping_areas:
        if area.is_in_group("Body"):
            #calculate collisions
            var caropp:Car=area.get_parent().get_parent() as Car
            BeAttacked(caropp)
            
func BeAttacked(Who:Car)->void:
    if(Who.isResetting):
        return 
    var enemyspeed:Vector2
    if(IsHitCar):
        if(Who.jumpCurrheight > Who.heightOverWall):
            return 
        Who.sounds.playbumpsound();
        enemyspeed = Who.speed;
        var dist:Vector2=global_position-Who.global_position
        var distsq:float = dist.length_squared()
        var spring:float = 0.005
        if(distsq < 2000):
            spring = 0.005 + 0.05 * (2000 - distsq) / 2000
        var pushvector:Vector2=dist*spring
        speed = enemyspeed+pushvector*15
        bsEx = 120;

func GetHitStatus(tx:float,ty:float)->void:
    var wallAngledeg:float =GetHitStatusAng(tx,ty)
    #no wall detected
    if(is_nan(wallAngledeg)):
        return 
    var _loc4_;
    var _loc2_;
    var _loc5_;
    if IsHitWall:
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
            rotation_degrees+=(speed.length()+1)*0.1/map.Wallspring
        if(poswallangle < 0 and poswallangle > -45 or poswallangle > 135):
            rotation_degrees-=(speed.length()+1)*0.1/map.Wallspring
        var loc1:float=wrapf(
            rad_to_deg(speedangle-wallAngle),
            -180.0,
            180
        )
        if(not (loc1>0 and loc1<180)):
            if(abs(speedwallangle) < 60):
                speedwallangle *=0.5
            speed=speed.rotated(deg_to_rad(speedwallangle))

        speed*=(1-map.Wallspring/2*(speedwallangle90*abs(abs(poswallangle)-90)/90))
        speed+=(Vector2(0.1,0).rotated(deg_to_rad(wallAngledeg+90)))
        stepx = int(speed.x * 10.0) / 10.0
        stepy = int(speed.y * 10.0) / 10.0
        tempx = position.x + stepx
        tempy = position.y + stepy

func GetHitStatusAng(tx:float, ty:float)->float:
    for collpoint:Marker2D in collisions:
        var _loc3_:Vector2 = collpoint.position
        var _loc5_:float = tx + _loc3_.x;
        var _loc4_:float = ty + _loc3_.y;
        var _loc2_:EdLine = map.ed.getHitFace(Vector2(_loc5_,_loc4_));
        if(_loc2_ != null):
            return _loc2_.GetAngle();
    return NAN


func UpdateSpeed()->void:
    var dir:int
    moveAngCar = (get_angle_diff())
    friction = abs(moveAngCar)
    if(friction > 90):
        friction = 180 - friction;
    var dragFactor:float=(0.02 + int(friction) * 0.0008)
    speed *= max(0.0, 1.0 - dragFactor/2)
    if(moveAngCar < 90 and moveAngCar > 0 or moveAngCar < -90):
        dir = -1;
    else:
        dir = 1;
    #calculate magnitude and direction of force
    var slide_magnitude: float = speed.length() * (0.0008 * int(90 - friction))
    var slide_force: Vector2 = speed.orthogonal() * dir
    slide_force = slide_force.normalized() * slide_magnitude
    #apply the force
    speed += slide_force

func get_angle_diff()->float:
    return rad_to_deg(angle_difference(speed.angle(), rotation-PI/2))
    
    
