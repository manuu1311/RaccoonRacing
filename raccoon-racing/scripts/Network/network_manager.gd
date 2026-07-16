extends CanvasLayer

const NORAY_HOST = "tomfol.io"
const NORAY_PORT = 8890
@onready var line_edit: LineEdit = $JoinButton/LineEdit

var host_id: String = ""

func _ready() -> void:
	# 1. Listen for Noray's handshake connections
	Noray.on_connect_nat.connect(_on_noray_connected)
	Noray.on_connect_relay.connect(_on_noray_connected)
	
	# 2. Print out what's happening under the hood
	multiplayer.peer_connected.connect(func(id): print("Player connected to Godot session: ", id))
	multiplayer.connection_failed.connect(func(): print("Godot Multiplayer Connection Failed!"))

# --- HOST LOGIC ---
func start_host() -> void:
	await Noray.connect_to_host(NORAY_HOST, NORAY_PORT)
	Noray.register_host()
	print('waiting for ids')
	await Noray.on_pid
	print('last one now')
	await Noray.register_remote()
	host_id = Noray.oid  # share THIS, not the pid
	print("!!! HOST READY !!! Share this ID with the client: ", host_id)
	
# --- CLIENT LOGIC ---
func start_client() -> void:
	var target_oid: String = line_edit.text  # keep as string
	await Noray.connect_to_host(NORAY_HOST, NORAY_PORT)
	Noray.register_host()
	await Noray.on_pid
	await Noray.register_remote()
	Noray.connect_nat(target_oid)  # or connect_relay(target_oid)
	
# --- HANDSHAKE & MULTIPLAYER PEER BINDING ---
func _on_noray_connected(address: String, port: int) -> void:
	print("Noray introduced us to a peer at: ", address, ":", port)
	
	# Create the UDP socket for the low-level handshake
	var udp := PacketPeerUDP.new()
	udp.bind(Noray.local_port)
	udp.set_dest_address(address, port)
	
	print("Performing packet handshake...")
	var err = await PacketHandshake.over_packet_peer(udp)
	udp.close()
	
	if err != OK:
		print("Handshake failed: ", err)
		return
		
	print("Handshake successful! Setting up ENet peer...")
	var peer := ENetMultiplayerPeer.new()
	
	# If we have a host_id, we are the host. Otherwise, we are the client.
	if host_id != "":
		err = peer.create_server(Noray.local_port)
	else:
		err = peer.create_client(address, port, 0, 0, 0, Noray.local_port)
		
	if err != OK:
		print("Failed to bind ENet peer: ", err)
		return
		
	multiplayer.multiplayer_peer = peer
	print("Multiplayer peer successfully assigned to tree!")
