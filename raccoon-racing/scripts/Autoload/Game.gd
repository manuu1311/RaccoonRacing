extends Node

var players: Array[Player]
var ready_players: Dictionary = {}
signal PlayersReady(tick:int)
##split screen mode
var IsSplitScreen:bool=true
var LocalPlayers:int=3


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
	if GameData.OnlinePlayersCount>1:
		target_tick+= NetworkTime.tickrate*5
	prints('Current tick:',NetworkTime.tick,'Target start tick:',str(target_tick))
	rpc("broadcast_start_tick", target_tick)

@rpc("authority", "call_local", "reliable")
func broadcast_start_tick(target_tick: int)->void:
	PlayersReady.emit(target_tick)

func register(player:Player)->void:
	players.append(player)
