extends Player
class_name AIPlayer

var AiPlayering:bool=false
var AiUsePropReflect:int=150
var AiUsePropTime:int=0
var ResetTimer:Timer
var AiResetTime:int=10
var AiLastCheckPoint:int
var AiNowPushButtonTimeNow:int
var AiNowPushButtonTime:int
var AiNowPushButton:int
var HasProp:bool=false
var IsOnlyAttPlayer:bool=false

func RunPropBox(_x:float,_y:float)->void:
    if not HasProp:
        HasProp=true
        CanUseProp=true
        var id:int=GetPropPer()
        await car.get_tree().create_timer(1.5).timeout
        GetProp(id)



func Update()->void:
    if(AiPlayering && car.playering):
        AutoUseProp();
        AutoReSetCar();
    UpdatePoint()
    car.Update()
    prop.run()
    
##return forward,brake,left,right
func AutoInput()->Array[bool]:
    var inputArr:Array[bool]=[0,0,0,0]
    inputArr[0]=true
    if(AiNowPushButtonTimeNow < AiNowPushButtonTime):
        if AiNowPushButton!=4:
            inputArr[AiNowPushButton]=true
        AiNowPushButtonTimeNow = AiNowPushButtonTimeNow + 1;
    else:
        AiNowPushButtonTimeNow = 0;
        var angle_rad: float = atan2(
            car.map.Points[NowPointId].y - car.global_position.y,
            car.map.Points[NowPointId].x - car.global_position.x
        )
        var angle_diff: float = rad_to_deg(angle_rad-car.rotation+PI/2)
        angle_diff=wrapf(angle_diff, -180.0, 180.0)
        if angle_diff > 5 and angle_diff < 180:
            AiNowPushButton = 3
            AiNowPushButtonTime = angle_diff / AiReflect
        elif angle_diff < -5 and angle_diff > -180:
            AiNowPushButton = 2
            AiNowPushButtonTime = abs(angle_diff) / 45 + AiReflect
        else:
            AiNowPushButtonTime = AiReflect
            AiNowPushButton = 4
    return inputArr

func AutoPlay()->void:
    ActionCar(0);
    if(AiNowPushButtonTimeNow < AiNowPushButtonTime):
        ActionCar(AiNowPushButton);
        AiNowPushButtonTimeNow = AiNowPushButtonTimeNow + 1;
    else:
        AiNowPushButtonTimeNow = 0;
        var angle_rad: float = atan2(
            car.map.Points[NowPointId].y - car.global_position.y,
            car.map.Points[NowPointId].x - car.global_position.x
        )
        var angle_diff: float = rad_to_deg(angle_rad-car.rotation+PI/2)
        angle_diff=wrapf(angle_diff, -180.0, 180.0)
        if angle_diff > 5 and angle_diff < 180:
            AiNowPushButton = 3
            AiNowPushButtonTime = angle_diff / AiReflect
        elif angle_diff < -5 and angle_diff > -180:
            AiNowPushButton = 2
            AiNowPushButtonTime = abs(angle_diff) / 45 + AiReflect
        else:
            AiNowPushButtonTime = AiReflect
            AiNowPushButton = 4


func ResetPlayer(order:int)->void:
    AiPlayering=false
    HasProp=false
    AiUsePropTime=0
    super(order)
  
func AutoUseProp()->bool:
    AiUsePropTime += 1
    if AiUsePropTime <= AiUsePropReflect:
        return false
        
    AiUsePropTime = 0
    HasProp=false
    
    if car.map.IsPropPoint(NowPointId) and prop.NowPorpId != 5:
        if IsOnlyAttPlayer:
            return false
        return true

    match prop.NowPorpId:
        0:
            return false
        1: # Proximity Bomb/Obstacle items
            for other:Player in GameData.PlayersArr:
                if other.PlayerID != self.PlayerID:
                    if other.prop.IsHavePropType(5) or other.prop.IsHavePropType(6) or (other.prop.IsHavePropType(9) and other.charid == 2):
                        return true
                    var dist_to_player: float = car.global_position.distance_to(other.car.global_position)
                    if dist_to_player < 300:
                        if not (IsOnlyAttPlayer and other.PlayerID != 0):
                           return true
            # Check map hazards
            for event_item:EventInMap in car.map.Events:
                if event_item.is_class("BombInMap") or event_item.is_class("BsInMap") or event_item.is_class('HoneyBombInMap'):
                    if car.global_position.distance_to(event_item.global_position) < 300:
                        return true
        2:
            return true
        3: # Global team item / shield check
            for other:Player in GameData.PlayersArr:
                if other.PlayerID != self.PlayerID:
                    if other.prop.IsHavePropType(5) or other.prop.IsHavePropType(6) or (other.prop.IsHavePropType(9) and other.charid == 2):
                        return true
        4, 7: # Offensive targeting missiles/items
            for other:Player in GameData.PlayersArr:
                if other.PlayerID != self.PlayerID and not (IsOnlyAttPlayer and other.PlayerID != 0):
                    if not other.car.isInvincible:
                        if car.global_position.distance_to(other.car.global_position) < 300:
                            var point_delta = NowPointId - other.NowPointId
                            if point_delta > 0 or point_delta < -10 or (point_delta == 0 and distance < other.distance):
                                return true
            if car.map.IsWanPoint(NowPointId):
                if IsOnlyAttPlayer:
                    if OrderId >= GameData.PlayersArr.size() - 1:
                        if GameData.OrderInfo[0]!= 0: return false
                    elif GameData.OrderInfo[OrderId + 1] != 0: 
                        return false
                return true
        5: # Shield / Boost
            if OrderId != 0:
                if IsOnlyAttPlayer and GameData.OrderInfo[0] != 0:
                    return false
                return true
        6: # Homing Missile
            if IsOnlyAttPlayer and GameData.OrderInfo[OrderId-1] != 0:
                return false
            return true
        8: # Speed Pad / Nitro Line
            if car.map.IsLinePoint(NowPointId):
                return true
        9: # Complex behavior depending on AI profile Type
            return _handle_prop_type_nine()
        _:
            push_error("Error UseProp Id")
    HasProp=false
    return false

func _handle_prop_type_nine() -> bool:
    match charid:
        3,4:
            for other in GameData.PlayersArr:
                if not (IsOnlyAttPlayer and other.PlayerID != 0) and not other.car.isInvincible and other.PlayerID != self.PlayerID:
                    if car.global_position.distance_to(other.car.global_position) < 300:
                        var point_delta:int = NowPointId - other.NowPointId
                        if point_delta > 0 or point_delta < -10 or (point_delta == 0 and distance < other.distance):
                            return true
            if car.map.IsWanPoint(NowPointId):
                if IsOnlyAttPlayer:
                    if OrderId >= GameData.PlayersArr.size() - 1:
                        if GameData.OrderInfo[0] != 0: 
                            return false
                    elif GameData.OrderInfo[OrderId + 1] != 0: 
                        return false
                return true
        1:
            if car.map.IsLinePoint(NowPointId):
                return true
        2:
            for other in GameData.PlayersArr:
                if other.PlayerID != self.PlayerID and not (IsOnlyAttPlayer and other.PlayerID != 0):
                    if not other.car.isInvincible and not other.prop.IsUseShield:
                        if car.global_position.distance_to(other.car.global_position) < 300:
                            return true
        5:
            for other in GameData.PlayersArr:
                if other.PlayerID != self.PlayerID and not (IsOnlyAttPlayer and other.PlayerID != 0):
                    if not other.car.isInvincible and car.global_position.distance_to(other.car.global_position) < 300:
                        return true
        6:
            for other in GameData.PlayersArr:
                if not (IsOnlyAttPlayer and other.PlayerID != 0) and other.PlayerID != self.PlayerID:
                    if not other.car.isInvincible and not other.car.isResetting:
                        if other.alldistance >= self.alldistance:
                            # Original Flash calculation checked squared distance (< 100000)
                            # 100000 squared distance equals ~316.2 pixels distance vector length.
                            if car.global_position.distance_squared_to(other.car.global_position) < 100000:
                                return true
    return false


func AutoReSetCar()->void:
    if(AiLastCheckPoint != NowPointId):
         ResetTimer.start()
         AiLastCheckPoint = NowPointId;

func ActionCar(action:int)->void:
    if(car.playering && not car.isSleep):
         DoAction(action);

func DoAction(action:int)->void:
    if car.jumpCurrheight<1:
        match(action):
            -1:
                car.Clearward()
            0:
                car.Forward()
            1:
                car.Backward()
            2:
                car.TurnLeft();
            3:
                car.TurnLRight();
            4:
                car.CancelTurn()
            _:
                car.CancelTurn()
            
func Stoprace()->void:
    AiPlayering = false;
    car.playering = false;
    ResetTimer.stop()
    for propinst:Prop in prop.propArr:
        prop.Delprop(propinst)
    prop.propArr=[]
    NowPointId=0

func Reset()->void:
    car.playering = false;
    car.isResetting = true;
    var newpos:Vector2 = car.map.Points[NowPointId - 1];
    var anglediff:float=(car.map.Points[NowPointId]-newpos).angle()
    car.Reset(newpos,anglediff)
    car.speed=Vector2(0,0)
    await car.get_tree().create_timer(1).timeout
    if is_instance_valid(car):
        RestartRace()

func RestartRace()->void:
    car.isResetting = false;
    car.playering = true;
    ResetTimer.start()
    
func StartRace()->void:
    AiPlayering=true
    car.playering = true;
    car.isLock = false;
    ResetTimer=Timer.new()
    car.add_child(ResetTimer)
    ResetTimer.one_shot=true
    ResetTimer.wait_time=AiResetTime
    ResetTimer.start()
    ResetTimer.timeout.connect(Reset)
    if randi() % 5 == 0:
        CanUseProp=true
        prop.NowPorpId = 8
        UseProp()
