extends Node2D
class_name  Player

var car: Car
var PlayerID:int
#TODO: should be set by game manager
##character id 1-6
var charid:int=6
enum control_type{HUMAN,AI,MULTIPLAYER,RLTRAINING,RL}
var current_control:control_type
var alldistance:int=0
var prop:PropManager
var PropBoxRunTimerId:int=-1
var CanUseProp:bool=false
var IsUsingProp:bool=false
var NowPointId:int
var OrderId:int
var LapsLock:bool=true
var Laps:int=1
var distance:int
var hud:HUDManager
var AiReflect:int
var ScorePoints:int=0
signal racefinished

func _init(id:int,control:control_type) -> void:
    PlayerID=id
    #TODO: manage ordering
    OrderId=id
    current_control=control
    prop=PropManager.new(self)
    

func SetCar(carinst:Car)->void:
    car=carinst
    
func SetHud(hudinst:HUDManager,carinst:Car)->void:
    hud=hudinst
    hud.setup()
    hud.SetCar(carinst)
    

func IsPlayering()->bool:
    return car.playering

func Update()->void:
    UpdatePoint()
    car.Update()
    prop.run()
    
    
func StartRace()->void:
    car.playering = true;
    car.isLock = false;
    if(car.speed.length() > 2):
        car.speed=Vector2.ZERO;
    elif(car.speed.length() > 0.5):
        CanUseProp=true
        prop.NowPorpId = 8;
        UseProp();
    
func UpdatePoint() -> void:
    if !IsPlayering():
        return
        
    var _loc4_: Vector2
    if NowPointId + 1 < car.map.Points.size():
        _loc4_ = car.map.Points[NowPointId + 1]
    else:
        _loc4_ = car.map.Points[0]

    # _loc6_ in flash: distance from car to NEXT waypoint
    var tonext: float = _loc4_.distance_to(car.global_position)
    # _loc5_ in flash: total distance between current waypoint and next waypoint
    var between: float = car.map.Points[NowPointId].distance_to(_loc4_)
    
    distance = car.map.Points[NowPointId].distance_to(car.global_position)

    if NowPointId == 0 and !LapsLock:
        alldistance = (Laps + 1) * 10000000 + NowPointId * 10000 + (10000 - distance)
    else:
        alldistance = Laps * 10000000 + NowPointId * 10000 + (10000 - distance)

    WinJudge() 

    # Waypoint progression logic
    if tonext + 200 < between or distance < 200:
        NowPointId += 1
        if NowPointId >= car.map.Points.size():
            NowPointId = 0

func WinJudge() -> void:
    if NowPointId == 1:
        LapsLock = false
        
    if NowPointId == 0 and !LapsLock:
        var win_pos: Vector2 = car.map.WinPosition # Assuming map has this method
        var win_to_point_0: float = win_pos.distance_to(car.map.Points[0])
        
        # distance is the car's distance to Points[0] (the next waypoint)
        if distance < win_to_point_0:
            if Laps == GameData.currentLaps:
                FinishRace()
                return
                
            Laps += 1
            # If this is the main player (ID 0)
            if hud!=null: 
                hud.updatelap()
                if Laps == GameData.currentLaps:
                    # Replace with your actual UI/Notification system call
                    hud.ShowMessage("FINAL LAP")
                else:
                    # Replace with your actual formatted string/localization system call
                    var lap_text:String = "LAP %d/%d" % [Laps, GameData.currentLaps]
                    hud.ShowMessage(lap_text)
            
            LapsLock = true


func FinishRace()->void:
    alldistance = 100000000 * (GameData.PlayersArr.size() - OrderId);
    Stoprace();

func Stoprace()->void:
      car.playering = false;
      racefinished.emit()

func RunPropBox(x:float,y:float)->void:
    if not car.playering:
        return
    car.sounds.GetProp()
    if not hud.PropItemReady():
        hud.propmove(x,y)
    if prop.NowPorpId!=0:
        return
    GetProp(GetPropPer())
    hud.StartPropBox(1.5,prop.NowPorpId)


            

func GetProp(propid:int)->void:
    prop.NowPorpId=propid

func ClearPropBox(id:int)->void:
    if hud!=null:
        hud.PropUsed(id)


func GetPropPer()->int:
    var _loc5_:int = randi_range(1,99);
    if(charid == 1 && OrderId == 0 && PlayerID == 0):
        _loc5_ = randi_range(0,89);
    if(charid == 1 && OrderId == 1 && PlayerID == 0):
        _loc5_ = randi_range(0,79);
    var _loc2_:Array[int] = [0,0,0,0,0,0,0,0,0,0,0];
    var _loc6_:Vector2;
    #TODO: is selectlevelid the difficulty?
    if(PlayerID == 0 || GameData.currentDifficulty < 2):
        if(OrderId == 0):
            _loc2_[1] = 0;
            _loc2_[2] = 0;
            _loc2_[3] = 30;
            _loc2_[4] = 30;
            _loc2_[5] = 0;
            _loc2_[6] = 0;
            _loc2_[7] = 30;
            _loc2_[8] = 0;
            _loc2_[9] = 10;
        elif(OrderId == 1):
            _loc2_[1] = 5;
            _loc2_[2] = 0;
            _loc2_[3] = 20;
            _loc2_[4] = 10;
            _loc2_[5] = 5;
            _loc2_[6] = 20;
            _loc2_[7] = 10;
            _loc2_[8] = 10;
            _loc2_[9] = 20;
        elif(OrderId == 2):
            _loc2_[1] = 10;
            _loc2_[2] = 5;
            _loc2_[3] = 0;
            _loc2_[4] = 0;
            _loc2_[5] = 10;
            _loc2_[6] = 25;
            _loc2_[7] = 0;
            _loc2_[8] = 30;
            _loc2_[9] = 20;
        else:
            _loc2_[1] = 10;
            _loc2_[2] = 5;
            _loc2_[3] = 0;
            _loc2_[4] = 0;
            _loc2_[5] = 10;
            _loc2_[6] = 25;
            _loc2_[7] = 0;
            _loc2_[8] = 30;
            _loc2_[9] = 20;
    elif(OrderId == 0):
        _loc6_=GameData.PlayersArr[0].car.global_position-car.global_position
        if(_loc6_.length() < 300):
            _loc2_[1] = 30;
            _loc2_[2] = 0;
            _loc2_[3] = 10;
            _loc2_[4] = 20;
            _loc2_[5] = 0;
            _loc2_[6] = 0;
            _loc2_[7] = 20;
            _loc2_[8] = 10;
            _loc2_[9] = 10;
        else:
            _loc2_[1] = 0;
            _loc2_[2] = 0;
            _loc2_[3] = 30;
            _loc2_[4] = 30;
            _loc2_[5] = 0;
            _loc2_[6] = 0;
            _loc2_[7] = 30;
            _loc2_[8] = 0;
            _loc2_[9] = 10;
    elif(OrderId == 1):
        _loc6_=GameData.PlayersArr[0].car.global_position-car.global_position
        if(_loc6_.length() < 300):
            if(GameData.PlayersArr[0].OrderId == 0):
                _loc2_[1] = 40;
                _loc2_[2] = 0;
                _loc2_[3] = 0;
                _loc2_[4] = 0;
                _loc2_[5] = 5;
                _loc2_[6] = 5;
                _loc2_[7] = 0;
                _loc2_[8] = 30;
                _loc2_[9] = 20;
            else:
                _loc2_[1] = 30;
                _loc2_[2] = 0;
                _loc2_[3] = 10;
                _loc2_[4] = 15;
                _loc2_[5] = 0;
                _loc2_[6] = 0;
                _loc2_[7] = 15;
                _loc2_[8] = 10;
                _loc2_[9] = 20;
        elif(GameData.PlayersArr[0].OrderId == 0):
            _loc2_[1] = 0;
            _loc2_[2] = 0;
            _loc2_[3] = 0;
            _loc2_[4] = 0;
            _loc2_[5] = 10;
            _loc2_[6] = 30;
            _loc2_[7] = 0;
            _loc2_[8] = 40;
            _loc2_[9] = 20;
        else:
            _loc2_[1] = 0;
            _loc2_[2] = 0;
            _loc2_[3] = 20;
            _loc2_[4] = 25;
            _loc2_[5] = 0;
            _loc2_[6] = 0;
            _loc2_[7] = 25;
            _loc2_[8] = 10;
            _loc2_[9] = 20;
    elif(OrderId == 2):
        _loc6_=GameData.PlayersArr[0].car.global_position-car.global_position
        if(_loc6_.length() < 300):
            if(GameData.PlayersArr[0].OrderId < 2):
                _loc2_[1] = 40;
                _loc2_[2] = 0;
                _loc2_[3] = 0;
                _loc2_[4] = 0;
                _loc2_[5] = 5;
                _loc2_[6] = 15;
                _loc2_[7] = 0;
                _loc2_[8] = 20;
                _loc2_[9] = 20;
            else:
                _loc2_[1] = 0;
                _loc2_[2] = 0;
                _loc2_[3] = 10;
                _loc2_[4] = 30;
                _loc2_[5] = 0;
                _loc2_[6] = 0;
                _loc2_[7] = 30;
                _loc2_[8] = 10;

        elif(GameData.PlayersArr[0].OrderId == 0):
            _loc2_[1] = 0;
            _loc2_[2] = 5;
            _loc2_[3] = 0;
            _loc2_[4] = 0;
            _loc2_[5] = 20;
            _loc2_[6] = 15;
            _loc2_[7] = 0;
            _loc2_[8] = 30;
            _loc2_[9] = 30;
        elif(GameData.PlayersArr[0].OrderId == 1):
            _loc2_[1] = 0;
            _loc2_[2] = 5;
            _loc2_[3] = 0;
            _loc2_[4] = 0;
            _loc2_[5] = 10;
            _loc2_[6] = 15;
            _loc2_[7] = 0;
            _loc2_[8] = 40;
            _loc2_[9] = 30;
        else:
            _loc2_[1] = 0;
            _loc2_[2] = 0;
            _loc2_[3] = 10;
            _loc2_[4] = 30;
            _loc2_[5] = 0;
            _loc2_[6] = 0;
            _loc2_[7] = 30;
            _loc2_[8] = 10;
            _loc2_[9] = 20;
    else:
        _loc6_=GameData.PlayersArr[0].car.global_position-car.global_position
        if(_loc6_.length() < 300):
            _loc2_[1] = 30;
            _loc2_[2] = 0;
            _loc2_[3] = 0;
            _loc2_[4] = 0;
            _loc2_[5] = 5;
            _loc2_[6] = 15;
            _loc2_[7] = 0;
            _loc2_[8] = 30;
            _loc2_[9] = 20;
        elif(GameData.PlayersArr[0].OrderId == 0):
            _loc2_[1] = 0;
            _loc2_[2] = 5;
            _loc2_[3] = 0;
            _loc2_[4] = 0;
            _loc2_[5] = 30;
            _loc2_[6] = 5;
            _loc2_[7] = 0;
            _loc2_[8] = 30;
            _loc2_[9] = 30;
        else:
            _loc2_[1] = 0;
            _loc2_[2] = 10;
            _loc2_[3] = 0;
            _loc2_[4] = 0;
            _loc2_[5] = 10;
            _loc2_[6] = 10;
            _loc2_[7] = 0;
            _loc2_[8] = 40;
            _loc2_[9] = 30;
    var _loc3_:int = 1;
    var _loc4_:int = 0;
    while(_loc3_ < _loc2_.size()):
        _loc4_ += _loc2_[_loc3_];
        if(_loc5_ < _loc4_):
            return _loc3_;
        _loc3_ = _loc3_ + 1;
    return 7
    #return randi_range(0,8)

func ResetUse()->void:
    CanUseProp=true

func UseProp()->void:
    if(IsPlayering() && not car.isSleep and CanUseProp and !IsUsingProp):
        prop.UseProp()
        CanUseProp=false
