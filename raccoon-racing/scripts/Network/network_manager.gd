extends Node

signal signal_lobby_created(code: String)
signal signal_lobby_joined
signal signal_peer_count_changed(count: int)
signal signal_client_disconnected
signal signal_left_lobby        # we voluntarily left
signal signal_host_left         # host disconnected, lobby is dead
signal signal_peer_left(peer_id: int)  # a non-host peer left, lobby continues

var _intentional_disconnect: bool = false
const WEB_SOCKET_SERVER_URL = "wss://raccoonracing.onrender.com"
const MAX_PLAYERS = 4

var ws_peer: WebSocketPeer
var web_rtc_peer: WebRTCMultiplayerPeer

var my_id:         int    = -1
var is_host:       bool   = false
var current_lobby: String = ""

var _pending_join_code: String = ""
var _join_sent:         bool   = false

var ICE_SERVERS:Dictionary = {
	"iceServers": [
		{"urls": ["stun:stun.l.google.com:19302"]}
	]
}

#id assigned
var PlayerID:int
var NetworkID:int

# ── Lifecycle ──────────────────────────────────────────────────────────────────

func _ready() -> void:
	set_process(false)
	tree_exited.connect(_ws_close_connection)


func _process(_delta: float) -> void:
	ws_peer.poll()

	match ws_peer.get_ready_state():
		WebSocketPeer.STATE_CONNECTING:
			return

		WebSocketPeer.STATE_OPEN:
			if not _join_sent:
				_join_sent = true
				_ws_send_text("J: %s\n" % _pending_join_code)
			while ws_peer.get_available_packet_count():
				_ws_parse_packet()

		WebSocketPeer.STATE_CLOSING:
			pass

		WebSocketPeer.STATE_CLOSED:
			var code   = ws_peer.get_close_code()
			var reason = ws_peer.get_close_reason()
			print("WS closed. Code: ", code, " Reason: '", reason, "'")
			if code <= 0:
				print("WARNING: Possible TLS or network failure – never reached server")
			if not _intentional_disconnect:
				signal_client_disconnected.emit()
			_intentional_disconnect = false
			set_process(false)


# ── Public API ─────────────────────────────────────────────────────────────────

func lobby_host() -> void:
	is_host            = true
	_pending_join_code = ""
	_join_sent         = false
	_connect_to_server()

func lobby_join(code:String) -> void:
	is_host            = false
	_pending_join_code = code.strip_edges()
	_join_sent         = false
	_connect_to_server()

func disconnect_from_server() -> void:
	_ws_close_connection()
	if web_rtc_peer:
		web_rtc_peer.close()
		web_rtc_peer = null
	my_id         = -1
	current_lobby = ""


func leave_lobby() -> void:
	# Works for both host and client. If we're the host, the server will
	# broadcast "D: 1" to everyone else, who'll interpret that as the
	# lobby closing (see the "D:" handler below). If we're a regular
	# client, the server broadcasts "D: <my_id>" and the lobby carries on.
	_intentional_disconnect = true
	_ws_close_connection(1000, "Left lobby")
	if web_rtc_peer:
		if multiplayer.peer_connected.is_connected(_on_rtc_peer_connected):
			multiplayer.peer_connected.disconnect(_on_rtc_peer_connected)
		if multiplayer.peer_disconnected.is_connected(_on_rtc_peer_disconnected):
			multiplayer.peer_disconnected.disconnect(_on_rtc_peer_disconnected)
		web_rtc_peer.close()
		web_rtc_peer = null
	multiplayer.multiplayer_peer = null
	my_id         = -1
	current_lobby = ""
	is_host       = false
	signal_left_lobby.emit()

# Called by the host whenever they want to begin, even alone (NPCs fill the rest)
func start_match() -> void:
	if not is_host:
		return
	# FIX: previously nothing told the signaling server the lobby was done,
	# so the server's 10s auto-close timer (which only starts once "S:" is
	# received) never fired and the socket stayed open indefinitely.
	_ws_send_text("S: \n")
	# TODO: this is the function to call to actually start the game
	start_game.rpc()


# ── WebSocket helpers ────────────────────────────────────────────────────────

func _connect_to_server() -> void:
	ws_peer = WebSocketPeer.new()
	if OS.has_feature("web"):
		ws_peer.connect_to_url(WEB_SOCKET_SERVER_URL)
	else:
		ws_peer.connect_to_url(WEB_SOCKET_SERVER_URL, TLSOptions.client())
	set_process(true)

func _ws_send_text(text: String) -> void:
	if ws_peer and ws_peer.get_ready_state() == WebSocketPeer.STATE_OPEN:
		ws_peer.send_text(text)

func _ws_close_connection(code: int = 1000, reason: String = "Disconnecting") -> void:
	if ws_peer and ws_peer.get_ready_state() == WebSocketPeer.STATE_OPEN:
		ws_peer.close(code, reason)


# ── Packet parsing ───────────────────────────────────────────────────────────

func _ws_parse_packet() -> void:
	var raw = ws_peer.get_packet().get_string_from_utf8()
	print("Received from signaling: ", raw)

	if raw.is_empty():
		return

	var first_newline = raw.find("\n")
	var header: String
	var body: String

	if first_newline == -1:
		header = raw.strip_edges()
	else:
		header = raw.substr(0, first_newline).strip_edges()
		body   = raw.substr(first_newline + 1)

	if header.length() < 3:
		return

	var cmd     = header.substr(0, 1)
	var payload = header.substr(3).strip_edges()

	match cmd:
		"I":  # Server assigned us an ID
			my_id = int(payload)
			print("[Net] Assigned ID: %d (host=%s)" % [my_id, str(my_id == 1)])
			_network_create_multiplayer_peer()

		"J":  # Lobby created / joined confirmed
			current_lobby = payload
			print("[Net] Lobby: ", current_lobby)
			if is_host:
				signal_lobby_created.emit(current_lobby)
			else:
				signal_lobby_joined.emit()

		"N":  # New peer arrived
			var peer_id = int(payload)
			print("[Net] New peer: ", peer_id)
			_network_create_new_peer_connection(peer_id)

		"D":  # Peer left
			var left_id = int(payload)
			print("[Net] Peer disconnected: ", left_id)
			if left_id == 1 and not is_host:
				# The host left — the whole lobby is no longer viable.
				print("[Net] Host left, tearing down lobby")
				_ws_close_connection(1000, "Host left")
				if web_rtc_peer:
					web_rtc_peer.close()
					web_rtc_peer = null
				multiplayer.multiplayer_peer = null
				signal_host_left.emit()
				return
			if web_rtc_peer and web_rtc_peer.has_peer(left_id):
				web_rtc_peer.remove_peer(left_id)
			signal_peer_left.emit(left_id)
			
		"S":  # Lobby sealed
			print("[Net] Lobby sealed")
			# FIX: proactively close our own signaling connection as soon as
			# the lobby is sealed, instead of waiting on the server's 10s
			# forced-close timer. The WebRTC connections are independent of
			# this socket, so closing it here does not affect gameplay.
			_ws_close_connection(1000, "Match starting")

		"O":  # Incoming offer
			var from_id = int(payload)
			if web_rtc_peer and web_rtc_peer.has_peer(from_id):
				web_rtc_peer.get_peer(from_id).connection.set_remote_description("offer", body.strip_edges())

		"A":  # Incoming answer
			var from_id = int(payload)
			if web_rtc_peer and web_rtc_peer.has_peer(from_id):
				web_rtc_peer.get_peer(from_id).connection.set_remote_description("answer", body.strip_edges())

		"C":  # Incoming ICE candidate – body is JSON
			var from_id   = int(payload)
			var candidate = JSON.parse_string(body.strip_edges())
			if candidate == null:
				print("[Net] Error parsing ICE candidate JSON!")
				return
			if web_rtc_peer and web_rtc_peer.has_peer(from_id):
				web_rtc_peer.get_peer(from_id).connection.add_ice_candidate(
					candidate["mid"], candidate["index"], candidate["sdp"]
				)


# ── WebRTC ───────────────────────────────────────────────────────────────────

func _network_create_multiplayer_peer() -> void:
	web_rtc_peer = WebRTCMultiplayerPeer.new()
	# STAR TOPOLOGY: host is the server (always id 1, matching the id the
	# signaling server assigns it), clients only ever dial the host.
	if is_host:
		web_rtc_peer.create_server()
	else:
		web_rtc_peer.create_client(my_id)
	multiplayer.multiplayer_peer = web_rtc_peer
	multiplayer.peer_connected.connect(_on_rtc_peer_connected)
	multiplayer.peer_disconnected.connect(_on_rtc_peer_disconnected)

func _network_create_new_peer_connection(peer_id: int) -> void:
	if peer_id == my_id:
		return
	# STAR TOPOLOGY: only allow a connection if one end is the host (id 1).
	# Two non-host clients both receive "N:" about each other from the
	# signaling server (it's topology-agnostic), but they must ignore it
	# here so they never try to connect directly to each other.
	if not (is_host or peer_id == 1):
		return
	var conn := WebRTCPeerConnection.new()
	conn.initialize(ICE_SERVERS)
	conn.session_description_created.connect(_on_offer_created.bind(peer_id))
	conn.ice_candidate_created.connect(_on_ice_candidate_created.bind(peer_id))
	web_rtc_peer.add_peer(conn, peer_id)
	if my_id < peer_id:
		await get_tree().process_frame
		conn.create_offer()

func _on_offer_created(type: String, sdp: String, peer_id: int) -> void:
	if not web_rtc_peer.has_peer(peer_id):
		return
	web_rtc_peer.get_peer(peer_id).connection.set_local_description(type, sdp)
	var cmd = "O" if type == "offer" else "A"
	_ws_send_text("%s: %d\n%s" % [cmd, peer_id, sdp])

func _on_ice_candidate_created(mid: String, index: int, sdp: String, peer_id: int) -> void:
	print("[Net] ICE candidate created for peer %d: %s" % [peer_id, mid])
	_ws_send_text("C: %d\n%s" % [peer_id, JSON.stringify({"mid": mid, "index": index, "sdp": sdp})])

func _on_rtc_peer_connected(id: int) -> void:
	print("[Net] WebRTC connected to peer %d" % id)
	signal_peer_count_changed.emit(multiplayer.get_peers().size() + 1)

func _on_rtc_peer_disconnected(id: int) -> void:
	print("[Net] WebRTC peer %d disconnected" % id)
	signal_peer_count_changed.emit(multiplayer.get_peers().size() + 1)


# ── Game start ───────────────────────────────────────────────────────────────

@rpc("any_peer", "call_local", "reliable")
func start_game() -> void:
	print("start_game RPC received")
	# TODO: this is where your actual game-start logic goes
	# GameState.isMultiplayer = true
	# get_tree().change_scene_to_file("res://Assets/Scene/Level/mainGame.tscn")
	pass
