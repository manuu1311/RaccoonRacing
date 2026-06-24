extends Player
class_name AIPlayer

var AiPlayering:bool=false
var AiUsePropReflect:int=150
var ResetTimer:Timer
var AiResetTime:int=10
var AiLastCheckPoint:int
var AiNowPushButtonTimeNow:int
var AiNowPushButtonTime:int
var AiNowPushButton:int

func RunPropBox(x:float,y:float)->void:
    pass

func Update()->void:
    if(AiPlayering && car.playering):
        AutoPlay();
        AutoUseProp();
        AutoReSetCar();
    UpdatePoint()
    car.Update()
    prop.run()
    

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

    
func AutoUseProp()->void:
    pass
    '''
    AiUsePropTime += 1
    if AiUsePropTime <= AiUsePropReflect:
        return
        
    AiUsePropTime = 0
    
    # If passing over a property point and don't have shield (assuming 5 is shield)
    if car.map.IsPropPoint(NowPointId) and prop.NowPorpId != 5:
        if IsOnlyAttPlayer:
            return
        UseProp()
        return

    match prop.NowPorpId:
        0:
            return
        1: # Proximity Bomb/Obstacle items
            for other in game.Players:
                if other.Id != self.Id:
                    if other.prop.IsHavePropType(5) or other.prop.IsHavePropType(6) or (other.prop.IsHavePropType(9) and other.PlayerType == 2):
                        UseProp()
                        return
                    var dist_to_player: float = car.global_position.distance_to(other.car.global_position)
                    if dist_to_player < 300:
                        if not (IsOnlyAttPlayer and other.Id != 0):
                           UseProp()
                           return
            # Check map hazards
            for event_item in game.map.Events:
                # Replace with your actual class names or group checks
                if event_item.is_in_group("Bombs"): 
                    if car.global_position.distance_to(event_item.global_position) < 300:
                        UseProp()
                        return
        2:
            UseProp()
        3: # Global team item / shield check
            for other in game.Players:
                if other.Id != self.Id:
                    if other.prop.IsHavePropType(5) or other.prop.IsHavePropType(6) or (other.prop.IsHavePropType(9) and other.PlayerType == 2):
                        UseProp()
                        return
        4, 7: # Offensive targeting missiles/items
            for other in game.Players:
                if other.Id != self.Id and not (IsOnlyAttPlayer and other.Id != 0):
                    if not other.IsInvincible:
                        if car.global_position.distance_to(other.car.global_position) < 300:
                            var point_delta = NowPointId - other.NowPointId
                            if point_delta > 0 or point_delta < -10 or (point_delta == 0 and distance < other.distance):
                                UseProp()
                                return
            if car.map.IsWanPoint(NowPointId):
                if IsOnlyAttPlayer:
                    if Order >= game.Players.size() - 1:
                        if game.OrderInfo[0][1] != 0: return
                    elif game.OrderInfo[Order + 1][1] != 0: 
                        return
                UseProp()
        5: # Shield / Boost
            if Order != 0:
                if IsOnlyAttPlayer and game.OrderInfo[0][1] != 0:
                    return
                UseProp()
        6: # Homing Missile
            # Replace placeholder logic with your homing selection system
            if IsOnlyAttPlayer and prop.SetAimPlayer(game, self).Id != 0:
                return
            UseProp()
        8: # Speed Pad / Nitro Line
            if car.map.IsLinePoint(NowPointId):
                UseProp()
        9: # Complex behavior depending on AI profile Type
            _handle_prop_type_nine()
        _:
            push_error("Error UseProp Id")

func _handle_prop_type_nine() -> void:
    match PlayerType:
        0, 3:
            for other in game.Players:
                if not (IsOnlyAttPlayer and other.Id != 0) and not other.IsInvincible and other.Id != self.Id:
                    if car.global_position.distance_to(other.car.global_position) < 300:
                        var point_delta = NowPointId - other.NowPointId
                        if point_delta > 0 or point_delta < -10 or (point_delta == 0 and distance < other.distance):
                            UseProp()
                            return
            if car.map.IsWanPoint(NowPointId):
                if IsOnlyAttPlayer:
                    if Order >= game.Players.size() - 1:
                        if game.OrderInfo[0][1] != 0: return
                    elif game.OrderInfo[Order + 1][1] != 0: 
                        return
                UseProp()
        1:
            if car.map.IsLinePoint(NowPointId):
                UseProp()
        2:
            for other in game.Players:
                if other.Id != self.Id and not (IsOnlyAttPlayer and other.Id != 0):
                    if not other.IsInvincible and not other.prop.IsUseShield:
                        if car.global_position.distance_to(other.car.global_position) < 300:
                            UseProp()
                            return
        4:
            for other in game.Players:
                if other.Id != self.Id and not (IsOnlyAttPlayer and other.Id != 0):
                    if not other.IsInvincible and car.global_position.distance_to(other.car.global_position) < 300:
                        UseProp()
                        return
        5:
            for other in game.Players:
                if not (IsOnlyAttPlayer and other.Id != 0) and other.Id != self.Id:
                    if not other.IsInvincible and not other.car.isResetting:
                        if other.Alldistance >= self.Alldistance:
                            # Original Flash calculation checked squared distance (< 100000)
                            # 100000 squared distance equals ~316.2 pixels distance vector length.
                            if car.global_position.distance_squared_to(other.car.global_position) < 100000:
                                UseProp()
                                return
    '''

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

func Reset()->void:
    car.playering = false;
    car.isResetting = true;
    var newpos:Vector2 = car.map.Points[NowPointId - 1];
    var anglediff:float=(car.map.Points[NowPointId]-newpos).angle()
    car.Reset(newpos,anglediff)
    car.speed=Vector2(0,0)
    await car.get_tree().create_timer(1).timeout
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
