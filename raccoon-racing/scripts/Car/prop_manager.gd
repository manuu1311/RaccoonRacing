extends Node
class_name PropManager

var IsUseShield:bool;
var player:Player;
var propArr:Array[Prop];
var NowPorpId:int = 0;

func _init(playerinst:Player)->void:
    player = playerinst;
    propArr = []
    IsUseShield = false;

func run()->void:
    for propinst:Prop in propArr:
        propinst.run()


func UseProp()->void:
    print('gotit',NowPorpId)
    var _loc2_:int;
    match(NowPorpId):
        0:
            return;
        #invincible
        1:
            #this.propArr.push(new as.Prop.PropInvincible(this.game,this.player));
            ClearPropBox();
            return;
        2:
            _loc2_ = 0;
            while(_loc2_ < GameData.PlayersArr.size()):
                var newplayer:Player=GameData.PlayersArr[_loc2_]
                if(newplayer.PlayerID != player.PlayerID):
                    if(not newplayer.car.isResetting and not newplayer.car.isInvincible):
                        pass
                        #TODO:sleep
                        #this.game.Players[_loc2_].prop.propArr.push(new as.Prop.PropSleep(this.game,this.game.Players[_loc2_]));

                else:
                    #TODO:sleep animation
                    pass
                    #as.Prop.PropSleep.SleepShotArt(this.player);
                _loc2_ = _loc2_ + 1;
            ClearPropBox();
            return
        3:
            #TODO:shield
            #this.propArr.push(new as.Prop.PropShield(this.game,this.player));
            ClearPropBox();
            return;
        4:
            #TODO:mine
            #this.propArr.push(new as.Prop.PropMine(this.game,this.player));
            ClearPropBox();
            return;
        5:
            #TODO:propkn1
            #this.propArr.push(new as.Prop.Propkn1(this.game,this.player));
            ClearPropBox();
            return;
        6:
            #TODO: missile
            #this.propArr.push(new as.Prop.PropHomingMissile(this.game,this.player));
            ClearPropBox();
            return;
        7:
            #TODO:boost
            #propArr.push(new as.Prop.PropOil(this.game,this.player));
            ClearPropBox();
            return;
        8:
            propArr.append(PetroProp.new(player))
            ClearPropBox();
            return;
        9:
            match(player.charid):
                1:
                    print('yaa')
                    propArr.append(PetroProp.new(player))
                    NowPorpId = 8;
                    player.ClearPropBox(8);
                2:
                    #this.propArr.push(new as.Prop.PropFurballs(this.game,this.player));
                    ClearPropBox();
                3:
                    #this.propArr.push(new as.Prop.PropHoneyBomb(this.game,this.player));
                    ClearPropBox();
                4:
                    #this.propArr.push(new as.Prop.PropIceTrail(this.game,this.player));
                    ClearPropBox();
                5:
                    #this.propArr.push(new as.Prop.PropBone(this.game,this.player));
                    ClearPropBox();
                5:
                    var j:int = 0;
                    while(j < GameData.PlayersArr.size()):
                        var newplayer:Player=GameData.PlayersArr[j]
                        if(newplayer.PlayerID!=player.PlayerID): 
                            if(not newplayer.car.isResetting and not newplayer.car.isInvincible):
                                if(newplayer.alldistance >= player.alldistance):
                                    var dist:Vector2=newplayer.car.global_position-player.car.global_position
                                    var distsq:float=dist.length_squared()
                                    if(distsq < 100000):
                                        #this.game.Players[j].prop.propArr.push(new as.Prop.PropShrinkRay(this.game,this.game.Players[j],this.player));
                                        ClearPropBox();

                        j+=1;
                    if(j >= GameData.PlayersArr.size()):
                        #this.propArr.push(new as.Prop.PropShrinkRay(this.game,this.player,null));
                        ClearPropBox();
                #default
                _:
                    pass
                    #TODO:message..
                    #as.MessageBox.ShowMessage("Error  UseProp Playertype");
            return;
        #default
        _:
            pass
            #TODO:message=
            #as.MessageBox.ShowMessage("Error UseProp Id");
    return;

func ClearPropBox()->void:
    NowPorpId = 0;
    player.ClearPropBox(NowPorpId);


func Delprop(prop:Prop)->void:
    var _loc2_:int = 0;
    while(_loc2_ < propArr.size()):
        if(propArr[_loc2_] == prop):
            propArr.remove_at(_loc2_)
            return 
        _loc2_ = _loc2_ + 1;

func IsHavePropType(typeid:int)->bool:
    for prop in propArr:
        if prop.proptype == typeid:
            return true
    return false


func del_prop_by_type(type_id: int) -> void:
    for i in range(propArr.size() - 1, -1, -1):
        if propArr[i].proptype == type_id:
            propArr[i].del()
            propArr.remove_at(i)
