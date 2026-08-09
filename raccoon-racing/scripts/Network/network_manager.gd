extends Node

#region Signal declaration
signal signal_lobby_created(code: String)
signal signal_lobby_joined
signal signal_peer_count_changed(count: int)
signal signal_client_disconnected
signal signal_left_lobby        # we voluntarily left
signal signal_host_left         # host disconnected, lobby is dead
signal signal_peer_left(peer_id: int)  # a non-host peer left, lobby continues
#endregion

#region Variables
# ── Network Mode Tracking ─────────────────────────────────────────────────────
enum ConnectionType { NONE, WEBRTC, LAN }
var connection_type: ConnectionType = ConnectionType.NONE
const LAN_PORT: int = 8910
const DISCOVERY_PORT: int = 8911
var discovery_broadcaster: PacketPeerUDP
var discovery_listener: PacketPeerUDP
var broadcast_timer: float = 0.0

var _intentional_disconnect: bool = false
const WEB_SOCKET_SERVER_URL = "wss://raccoonracing.onrender.com"
const MAX_PLAYERS = 4

var ws_peer: WebSocketPeer
var web_rtc_peer: WebRTCMultiplayerPeer
var enet_peer: ENetMultiplayerPeer # Used for LAN

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
var PlayerID:int=0
var NetworkID:int
var IsLobbySealed:bool
#endregion

# ── Lifecycle ──────────────────────────────────────────────────────────────────
#region Lifecycle
func _ready() -> void:
	set_process(false)
	tree_exited.connect(_ws_close_connection)
	
	# Connect standard multiplayer signals (works for both WebRTC and ENet)
	# We connect these once here, instead of inside the peer creation functions
	multiplayer.peer_connected.connect(_on_multiplayer_peer_connected)
	multiplayer.peer_disconnected.connect(_on_multiplayer_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)

	
func _process(delta: float) -> void:
	# Only process WebSocket if we are in WebRTC mode
	if connection_type == ConnectionType.WEBRTC:
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
				var code:int   = ws_peer.get_close_code()
				var reason:String = ws_peer.get_close_reason()
				print("WS closed. Code: ", code, " Reason: '", reason, "'")
				if code <= 0:
					print("WARNING: Possible TLS or network failure – never reached server")
				if not _intentional_disconnect:
					signal_client_disconnected.emit()
				_intentional_disconnect = false
				set_process(false)
	if connection_type == ConnectionType.LAN and is_host and discovery_broadcaster:
		broadcast_timer += delta
		if broadcast_timer >= 1.0:
			broadcast_timer = 0.0
			discovery_broadcaster.put_packet("RACCOON_LAN_HOST".to_utf8_buffer())
	# LAN Client listens for a host
	elif connection_type == ConnectionType.LAN and not is_host and discovery_listener:
		if discovery_listener.get_available_packet_count() > 0:
			var packet:String = discovery_listener.get_packet().get_string_from_utf8()
			var server_ip:String = discovery_listener.get_packet_ip()

			if packet == "RACCOON_LAN_HOST":
				print("[LAN] Found host at: ", server_ip)
				discovery_listener.close()
				discovery_listener = null
				# Automatically join the host using the discovered IP!
				lan_join(server_ip)
#endregion

#region Public API
# ── Public API ───────────────────────────────────────────────
func lobby_host(lan:bool) -> void:
	if lan:
		lan_host()
	else:
		lobby_host_webrtc()
func lobby_join(code:String,lan:bool) -> void:
	if lan:
		lan_join(code)
	else:
		lobby_join_webrtc(code)
#endregion

#region WebRTC API
# ── Public API: WebRTC (Online) ───────────────────────────────────────────────

func lobby_host_webrtc() -> void:
	is_host = true
	connection_type = ConnectionType.WEBRTC
	_pending_join_code = ""
	_join_sent = false
	_connect_to_server()

func lobby_join_webrtc(code:String) -> void:
	is_host = false
	connection_type = ConnectionType.WEBRTC
	_pending_join_code = code.strip_edges()
	_join_sent = false
	_connect_to_server()
#endregion 

#region LAN API
# ── Public API: LAN ───────────────────────────────────────────────────────────

func lan_host() -> void:
	is_host = true
	connection_type = ConnectionType.LAN
	current_lobby = GetLocalIP()
	#start broadcasting
	enet_peer = ENetMultiplayerPeer.new()
	var err:Error = enet_peer.create_server(LAN_PORT, MAX_PLAYERS)
	if err == OK:
		multiplayer.multiplayer_peer = enet_peer
		my_id = 1 # Host is always 1 in star topology
		print("[LAN] Hosting on port ", LAN_PORT, " with ID: ", my_id)
		signal_lobby_created.emit(GetLocalIP())
		set_process(true)
	else:
		print("[LAN] Failed to create server: ", err)
		connection_type = ConnectionType.NONE

func lan_join(ip: String) -> void:
	is_host = false
	connection_type = ConnectionType.LAN
	
	enet_peer = ENetMultiplayerPeer.new()
	var err:Error = enet_peer.create_client(ip, LAN_PORT)
	if err == OK:
		multiplayer.multiplayer_peer = enet_peer
		print("[LAN] Connecting to ", ip, ":", LAN_PORT)
		current_lobby=ip
		# We wait for the "connected_to_server" signal to emit signal_lobby_joined
	else:
		print("[LAN] Failed to create client: ", err)
		connection_type = ConnectionType.NONE
		signal_client_disconnected.emit()

func discover_lan_host() -> void:
	if discovery_listener == null:
		connection_type = ConnectionType.LAN
		discovery_listener = PacketPeerUDP.new()
		var err:Error = discovery_listener.bind(DISCOVERY_PORT)
		if err == OK:
			print("[LAN] Listening for hosts...")
			set_process(true)
		else:
			print("[LAN] Failed to bind discovery port: ", err)
			discovery_listener = null

func StartLanBroadcast() -> void:
	if discovery_broadcaster or connection_type != ConnectionType.LAN:
		return
	discovery_broadcaster = PacketPeerUDP.new()
	discovery_broadcaster.set_broadcast_enabled(true)
	discovery_broadcaster.set_dest_address("255.255.255.255", DISCOVERY_PORT)
	set_process(true)

func StopLanBroadcast() -> void:
	if discovery_broadcaster:
		discovery_broadcaster.close()
		discovery_broadcaster = null
#endregion

#region Disconnection
# ── Disconnect / Leave ────────────────────────────────────────────────────────

func disconnect_from_server() -> void:
	IsLobbySealed=false
	if connection_type == ConnectionType.WEBRTC:
		_ws_close_connection()
		if web_rtc_peer:
			web_rtc_peer.close()
			web_rtc_peer = null
	elif connection_type == ConnectionType.LAN:
		CleanDiscovery()
		if enet_peer:
			enet_peer.close()
			enet_peer = null
			
	my_id = -1
	current_lobby = ""
	connection_type = ConnectionType.NONE


func leave_lobby() -> void:
	_intentional_disconnect = true
	IsLobbySealed=false
	
	if connection_type == ConnectionType.WEBRTC:
		_ws_close_connection(1000, "Left lobby")
		if web_rtc_peer:
			web_rtc_peer.close()
			web_rtc_peer = null
	elif connection_type == ConnectionType.LAN:
		CleanDiscovery()
		if enet_peer:
			enet_peer.close()
			enet_peer = null

	multiplayer.multiplayer_peer = null
	my_id = -1
	current_lobby = ""
	is_host = false
	connection_type = ConnectionType.NONE
	signal_left_lobby.emit()
#endregion

#region Game Start
# ── Game Start ────────────────────────────────────────────────────────────────

func start_match() -> void:
	if not is_host:
		return
		
	# Only signal the WebRTC server if we are in WebRTC mode
	if connection_type == ConnectionType.WEBRTC:
		_ws_send_text("S: \n")
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
#endregion

#region WebRTC parsing
# ── Packet parsing (WebRTC Only) ──────────────────────────────────────────────

func _ws_parse_packet() -> void:
	var raw:String = ws_peer.get_packet().get_string_from_utf8()
	# ... (Your existing WebRTC parsing code remains exactly the same here) ...
	# Omitted for brevity, but keep your entire match statement block here!
	var first_newline:int = raw.find("\n")
	var header: String
	var body: String

	if first_newline == -1:
		header = raw.strip_edges()
	else:
		header = raw.substr(0, first_newline).strip_edges()
		body   = raw.substr(first_newline + 1)

	if header.length() < 3:
		return

	var cmd:String     = header.substr(0, 1)
	var payload:String = header.substr(3).strip_edges()

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
			var peer_id:int = int(payload)
			print("[Net] New peer: ", peer_id)
			_network_create_new_peer_connection(peer_id)
		"D":  # Peer left
			var left_id:int = int(payload)
			print("[Net] Peer disconnected: ", left_id)
			if left_id == 1 and not is_host:
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
			_ws_close_connection(1000, "Match starting")
		"O":  # Incoming offer
			var from_id:int = int(payload)
			if web_rtc_peer and web_rtc_peer.has_peer(from_id):
				web_rtc_peer.get_peer(from_id).connection.set_remote_description("offer", body.strip_edges())
		"A":  # Incoming answer
			var from_id:int = int(payload)
			if web_rtc_peer and web_rtc_peer.has_peer(from_id):
				web_rtc_peer.get_peer(from_id).connection.set_remote_description("answer", body.strip_edges())
		"C":  # Incoming ICE candidate
			var from_id:int   = int(payload)
			var candidate:Variant = JSON.parse_string(body.strip_edges())
			if candidate == null:
				return
			if web_rtc_peer and web_rtc_peer.has_peer(from_id):
				web_rtc_peer.get_peer(from_id).connection.add_ice_candidate(
					candidate["mid"], candidate["index"], candidate["sdp"]
				)


# ── WebRTC Peer Creation ──────────────────────────────────────────────────────

func _network_create_multiplayer_peer() -> void:
	web_rtc_peer = WebRTCMultiplayerPeer.new()
	if is_host:
		web_rtc_peer.create_server()
	else:
		web_rtc_peer.create_client(my_id)
	multiplayer.multiplayer_peer = web_rtc_peer

func _network_create_new_peer_connection(peer_id: int) -> void:
	if peer_id == my_id:
		return
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
	var cmd:String = "O" if type == "offer" else "A"
	_ws_send_text("%s: %d\n%s" % [cmd, peer_id, sdp])

func _on_ice_candidate_created(mid: String, index: int, sdp: String, peer_id: int) -> void:
	_ws_send_text("C: %d\n%s" % [peer_id, JSON.stringify({"mid": mid, "index": index, "sdp": sdp})])
#endregion

#region Signal Handling
# ── Multiplayer Signal Handlers (Shared by WebRTC and LAN) ────────────────────

func _on_multiplayer_peer_connected(id: int) -> void:
	print("[Net] Peer connected: ", id)
	signal_peer_count_changed.emit(multiplayer.get_peers().size() + 1)

func _on_multiplayer_peer_disconnected(id: int) -> void:
	print("[Net] Peer disconnected: ", id)
	signal_peer_count_changed.emit(multiplayer.get_peers().size() + 1)
	if id == 1 and not is_host:
		# Host left in LAN
		signal_host_left.emit()
	else:
		signal_peer_left.emit(id)

func _on_connected_to_server() -> void:
	# Called on LAN Clients when successfully connected to the host
	if connection_type == ConnectionType.LAN:
		my_id = multiplayer.get_unique_id()
		print("[LAN] Successfully connected to host with ID: ", my_id)
		signal_lobby_joined.emit()

func _on_connection_failed() -> void:
	# Called on LAN Clients if connection to host fails
	if connection_type == ConnectionType.LAN:
		print("[LAN] Connection failed")
		signal_client_disconnected.emit()

func CleanDiscovery()->void:
	set_process(false)
	print('[LAN] Quit listening')
	if discovery_broadcaster:
		discovery_broadcaster.close()
		discovery_broadcaster = null
	if discovery_listener:
		discovery_listener.close()
		discovery_listener = null
#endregion

#region Game Start
# ── Game start RPC ───────────────────────────────────────────────────────────

@rpc("any_peer", "call_local", "reliable")
func start_game() -> void:
	CleanDiscovery()
	IsLobbySealed=true
	print("Start Game RPC received")
	# GameState.isMultiplayer = true
	# get_tree().change_scene_to_file("res://Assets/Scene/Level/mainGame.tscn")
	pass
#endregion

#region Utils
# ── Utils ───────────────────────────────────────────────────────────
func GetLocalIP() -> String:
	var addresses:PackedStringArray = IP.get_local_addresses()
	var best_candidate:String = ""
	
	for ip in addresses:
		# Exclude IPv6 and loopback
		if ":" in ip or ip.begins_with("127."):
			continue
			
		# Check for common private LAN IP ranges
		if ip.begins_with("192.168.") or ip.begins_with("10."):
			return ip # Highest priority LAN address
		
		# Check for 172.16.x.x - 172.31.x.x private range
		if ip.begins_with("172."):
			var parts:PackedStringArray = ip.split(".")
			if parts.size() > 1:
				var second_octet:int = parts[1].to_int()
				if second_octet >= 16 and second_octet <= 31:
					return ip
		
		# Keep any non-loopback IPv4 address as a fallback candidate
		if best_candidate == "":
			best_candidate = ip
			
	return best_candidate

func IsDiscovering()->bool:
	return discovery_listener!=null

func IsLan()->bool:
	return connection_type==ConnectionType.LAN

func SetLanType()->void:
	connection_type = ConnectionType.LAN

func ResetType()->void:
	connection_type = ConnectionType.LAN

func IsConnected() -> bool:
	return connection_type != ConnectionType.NONE
#endregion
