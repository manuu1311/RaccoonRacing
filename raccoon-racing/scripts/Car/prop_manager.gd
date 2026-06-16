extends Node
class_name PropManager

var IsUseShield:bool;
var player:Player;
var propArr:Array[int];
var NowPorpId:int = 0;

func PropManage(playerinst:Player)->void:
    player = playerinst;
    propArr = []
    IsUseShield = false;

func run()->void:
    var _loc2_:id = 0;
    while(_loc2_ < propArr.length):
        propArr[_loc2_].run();
        _loc2_ = _loc2_ + 1;


func UseProp()->void:
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
                    if(not newplayer.isResetting and not newplayer.isInvincible):
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
            #TODO:boost
            #this.propArr.push(new as.Prop.PropPetro(this.game,this.player));
            ClearPropBox();
            return;
        9:
        match(this.player.PlayerType):
            case 0:
                this.propArr.push(new as.Prop.PropHoneyBomb(this.game,this.player));
                this.ClearPropBox();
                break;
            case 1:
                this.propArr.push(new as.Prop.PropPetro(this.game,this.player));
                this.NowPorpId = 8;
                this.player.ClearPropBox(8);
                break;
            case 2:
                this.propArr.push(new as.Prop.PropFurballs(this.game,this.player));
                this.ClearPropBox();
                break;
            case 3:
                this.propArr.push(new as.Prop.PropIceTrail(this.game,this.player));
                this.ClearPropBox();
                break;
            case 4:
                this.propArr.push(new as.Prop.PropBone(this.game,this.player));
                this.ClearPropBox();
                break;
            case 5:
                var j = 0;
                while(j < this.game.Players.length)
                {
                    if(this.game.Players[j].Id != this.player.Id)
                    {
                    if(!this.game.Players[j].IsInvincible)
                    {
                        if(!this.game.Players[j].IsReSeting)
                        {
                            if(this.game.Players[j].Alldistance >= this.player.Alldistance)
                            {
                                _loc4_ = this.game.Players[j].myCar.Dmc._x - this.player.myCar.Dmc._x;
                                _loc3_ = this.game.Players[j].myCar.Dmc._y - this.player.myCar.Dmc._y;
                                _loc5_ = _loc4_ * _loc4_ + _loc3_ * _loc3_;
                                if(_loc5_ < 100000)
                                {
                                this.game.Players[j].prop.propArr.push(new as.Prop.PropShrinkRay(this.game,this.game.Players[j],this.player));
                                this.ClearPropBox();
                                break;
                                }
                            }
                        }
                    }
                    }
                    j++;
                }
                if(j >= this.game.Players.length)
                {
                    this.propArr.push(new as.Prop.PropShrinkRay(this.game,this.player,null));
                    this.ClearPropBox();
                }
                break;
            default:
                as.MessageBox.ShowMessage("Error  UseProp Playertype");
        }
        return;
        default:
        as.MessageBox.ShowMessage("Error UseProp Id");
        return;
    }
}
function ClearPropBox()
{
    this.NowPorpId = 0;
    this.player.ClearPropBox();
}
function Delprop(prop)
{
    var _loc2_ = 0;
    while(_loc2_ < this.propArr.length)
    {
        if(this.propArr[_loc2_] == prop)
        {
        this.propArr[_loc2_].del();
        this.propArr.splice(_loc2_,1);
        false;
        return undefined;
        }
        _loc2_ = _loc2_ + 1;
    }
}
function IsHavePropType(typeid)
{
    var _loc2_ = 0;
    while(_loc2_ < this.propArr.length)
    {
        if(this.propArr[_loc2_].proptype == typeid)
        {
        return true;
        }
        _loc2_ = _loc2_ + 1;
    }
    return false;
}
function Delpropbytype(typeid)
{
    var _loc2_ = 0;
    while(_loc2_ < this.propArr.length)
    {
        if(this.propArr[_loc2_].proptype == typeid)
        {
        this.propArr[_loc2_].del();
        delete this.propArr[_loc2_];
        this.propArr.splice(_loc2_,1);
        _loc2_ = _loc2_ - 1;
        }
        _loc2_ = _loc2_ + 1;
    }
}
}
