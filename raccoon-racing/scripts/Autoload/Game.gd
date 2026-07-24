extends Node

var players: Array[Player]
var fcsCar:Car
##to lock props when player still cannot see them
var propLock:bool=false
var ready_players: Dictionary = {}
signal PlayersReady(tick:int)

@rpc("any_peer", "reliable")
func server_receive_ready(peer_id: int)->void:
	if GameData.IsMultiplayer and not NetworkManager.is_host: 
		print('returning :()')
		return

	ready_players[peer_id] = true

	# Check if everyone in the lobby has loaded
	if ready_players.size() == GameData.OnlinePlayersCount:
		start_race_countdown()
		ready_players={}

func start_race_countdown()->void:
	# Pick a safe tick in the future
	var target_tick:int = NetworkTime.tick 
	prints('target:',str(target_tick),'curr:',NetworkTime.tick)
	if GameData.OnlinePlayersCount>1:
		target_tick+= NetworkTime.tickrate*5
	rpc("broadcast_start_tick", target_tick)

@rpc("authority", "call_local", "reliable")
func broadcast_start_tick(target_tick: int)->void:
	PlayersReady.emit(target_tick)

func register(player:Player)->void:
	players.append(player)

func focusCar(car:Car)->void:
	fcsCar=car
