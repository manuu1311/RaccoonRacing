extends Node
class_name PropManager

var player:Player;
var propArr:Array[Prop]

func _init(playerinst:Player)->void:
	player = playerinst;
	propArr = []

func run()->void:
	for propinst:Prop in propArr:
		propinst.run_tick()

'''
1:become invincible
2:sleep other players
3:shield
4:deploy mine
5:missile to first player
6:missile to next player
7:banana
8:turbo
9:character signature:
	1:double turbo
	2:bombs
	3:double mine
	4:ice trail
	5:rotating bones
	6:laser shrink ray
'''
func UseProp()->void:
	var _loc2_:int;
	match(player.car.NowPorpId):
		0:
			return;
		#invincible
		1:
			propArr.append(InvincibleProp.new(player))
			ClearPropBox();
			return;
		2:
			_loc2_ = 0;
			while(_loc2_ < GameData.PlayersArr.size()):
				var newplayer:Player=GameData.PlayersArr[_loc2_]
				if(newplayer.PlayerID != player.PlayerID):
					if(not newplayer.car.isResetting and not newplayer.car.isInvincible):
						newplayer.prop.propArr.append(SleepProp.new(newplayer))
						#apply animation
						for playerinst:Player in GameData.PlayersArr:
							playerinst.car.prop_effector.PlaySleepHudAnimation(newplayer.PlayerID)
				else:
					player.car.prop_effector.SleepShotArt(player.PlayerID)
				_loc2_ = _loc2_ + 1;
			ClearPropBox();
			return
		3:
			propArr.append(ShieldProp.new(player))
			ClearPropBox();
			return;
		4:
			propArr.append(MineProp.new(player))
			ClearPropBox();
			return;
		5:
			propArr.append(Propkn1Prop.new(player))
			ClearPropBox();
			return;
		6:
			propArr.append(HomingMissileProp.new(player))
			ClearPropBox();
			return;
		7:
			propArr.append(OilProp.new(player))
			ClearPropBox();
			return;
		8:
			propArr.append(PetroProp.new(player))
			ClearPropBox();
			return;
		9:
			match(player.car.CharID):
				1:
					propArr.append(PetroProp.new(player))
					player.car.NowPorpId = 8;
					player.ClearPropBox(8);
				2:
					propArr.append(FurballsProp.new(player))
					ClearPropBox();
				3:
					propArr.append(HoneyProp.new(player))
					ClearPropBox();
				4:
					propArr.append(IceTrailProp.new(player))
					ClearPropBox();
				5:
					propArr.append(BoneProp.new(player))
					ClearPropBox();
				6:
					var j:int = 0;
					while(j < GameData.PlayersArr.size()):
						var newplayer:Player=GameData.PlayersArr[j]
						if(newplayer.PlayerID!=player.PlayerID): 
							if(not newplayer.car.isResetting and not newplayer.car.isInvincible):
								if(newplayer.alldistance <= player.alldistance):
									var dist:Vector2=newplayer.car.global_position-player.car.global_position
									var distsq:float=dist.length_squared()
									if(distsq < 100000):
										newplayer.prop.propArr.append(ShrinkProp.new(newplayer,player.car))
										ClearPropBox();
										break
						j+=1;
					if(j >= GameData.PlayersArr.size()):
						player.prop.propArr.append(ShrinkProp.new(player,null))
						ClearPropBox();
				#default
				_:
					pass
					#as.MessageBox.ShowMessage("Error  UseProp Playertype");
			return;
		#default
		_:
			pass
			#as.MessageBox.ShowMessage("Error UseProp Id");
	return;

func ClearPropBox()->void:
	player.car.NowPorpId = 0;
	player.ClearPropBox(player.car.NowPorpId);


func Delprop(prop:Prop)->void:
	var _loc2_:int = 0;
	while(_loc2_ < propArr.size()):
		if(propArr[_loc2_] == prop):
			propArr[_loc2_].del()
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
