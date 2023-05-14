extends Node

enum PACKET_TYPE {HANDSHAKE = 1, HANDSHAKE_REPLY = 2, PEER_STATE = 3, RPC = 6}

signal peer_session_failure(steam_id, reason)
signal confirm_peer_on_lobby(steam_id)
signal peer_status_updated(steam_id)
signal all_peers_connected
signal peer_updated

var _peers_confirmed_node_path = {}
var _server_steam_id := 0
var _peers = {}

var _server_packets := {
	"packet_size_channel_0" : 0,
	"packet_size_channel_1" : 0,
	"packet_size_channel_2" : 0,
	"packet_size_channel_3" : 0,
	"packet_size_channel_4" : 0
}

func _ready() -> void:
	SgGlobalReferences.set_reference("SteamConnection", self)
	
	if SgGlobalReferences.get_reference("SteamLobby").connect("player_joined_lobby", Callable(self, "_init_p2p_session")) != OK: pass
	if SgGlobalReferences.get_reference("SteamLobby").connect("player_left_lobby", Callable(self, "_close_p2p_session")) != OK: pass
	if SgGlobalReferences.get_reference("SteamLobby").connect("lobby_owner_changed", Callable(self, "_migrate_host")) != OK: pass
	if SgGlobalReferences.get_reference("SteamLobby").connect("lobby_created", Callable(self, "_init_p2p_host")) != OK: pass
	
	if Steam.connect("p2p_session_connect_fail", Callable(self, "_on_p2p_session_connect_fail")) != OK: pass
	if Steam.connect("p2p_session_request", Callable(self, "_on_p2p_session_request")) != OK: pass

func _process(_delta) -> void:
	_server_packets["packet_size_channel_0"] = Steam.getAvailableP2PPacketSize(0)
	_server_packets["packet_size_channel_1"] = Steam.getAvailableP2PPacketSize(1)
	_server_packets["packet_size_channel_2"] = Steam.getAvailableP2PPacketSize(2)
	_server_packets["packet_size_channel_3"] = Steam.getAvailableP2PPacketSize(3)
	_server_packets["packet_size_channel_4"] = Steam.getAvailableP2PPacketSize(4)
	
	#Read channels
	while _server_packets["packet_size_channel_0"] > 0 || _server_packets["packet_size_channel_1"] > 0 || _server_packets["packet_size_channel_2"] > 0 || _server_packets["packet_size_channel_3"] > 0 || _server_packets["packet_size_channel_4"] > 0:
		if _server_packets["packet_size_channel_0"] > 0:
			_read_p2p_packet(_server_packets["packet_size_channel_0"], 0)
		_server_packets["packet_size_channel_0"] = Steam.getAvailableP2PPacketSize(0)
	
		if _server_packets["packet_size_channel_1"] > 0:
			_read_p2p_packet(_server_packets["packet_size_channel_1"], 1)
		_server_packets["packet_size_channel_1"] = Steam.getAvailableP2PPacketSize(1)
		
		if _server_packets["packet_size_channel_2"] > 0:
			_read_p2p_packet(_server_packets["packet_size_channel_2"], 2)
		_server_packets["packet_size_channel_2"] = Steam.getAvailableP2PPacketSize(2)
		
		if _server_packets["packet_size_channel_3"] > 0:
			_read_p2p_packet(_server_packets["packet_size_channel_3"], 3)
		_server_packets["packet_size_channel_3"] = Steam.getAvailableP2PPacketSize(3)
		
		if _server_packets["packet_size_channel_4"] > 0:
			_read_p2p_packet(_server_packets["packet_size_channel_4"], 4)
		_server_packets["packet_size_channel_4"] = Steam.getAvailableP2PPacketSize(4)

# CLIENTS AND SERVER
# Calls this method on the server
func rpc_on_server(method: String, args: Array = [], channel : int = 0, network_type : int = Steam.P2P_SEND_RELIABLE) -> void:
	_rpc(get_server_steam_id(), method, args, channel, network_type)

# SERVER ONLY
# Calls this method on the client specified
func rpc_on_client(to_peer_id: int, method: String, args: Array = [], channel : int = 0, network_type : int = Steam.P2P_SEND_RELIABLE) -> void:
	if not is_server():
		SgGlobalReferences.get_reference("DebugLogger").debug_logger("Tried to call RPC on client method: %s " % [method])
		return
	_rpc(to_peer_id, method, args, channel, network_type)

# SERVER ONLY
# Calls this method on ALL clients connected
func rpc_all_clients(method: String, args: Array = [], channel : int = 0, network_type : int = Steam.P2P_SEND_RELIABLE) -> void:
	for peer_id in _peers:
		rpc_on_client(peer_id, method, args, channel, network_type)

# Returns whether a peer is connected or not.
func is_peer_connected(steam_id) -> bool:
	if _peers.has(steam_id):
		return _peers[steam_id].connected
	else:
		SgGlobalReferences.get_reference("DebugLogger").debug_logger("Tried to get status of non-existent peer: %s" % steam_id)
		return false

# Returns a peer object for a given users steam_id
func get_peer(steam_id) -> Object:
	if _peers.has(steam_id):
		return _peers[steam_id]
	else:
		SgGlobalReferences.get_reference("DebugLogger").debug_logger("Tried to get non-existent peer: %s" % steam_id)
		return null

# Returns the dictionary of all peers
func get_peers() -> Dictionary:
	return _peers

# Returns whether this peer is the server or not
func is_server() -> bool:
	if not _peers.has(SgGlobalReferences.get_reference("SteamManager").get_my_steam_id()):
		return false
	return _peers[SgGlobalReferences.get_reference("SteamManager").get_my_steam_id()].host

# Gets the peer object of the server connection
func get_server_peer() -> Object:
	return get_peer(get_server_steam_id())

# Gets the server users steam id
func get_server_steam_id() -> int:
	if _server_steam_id > 0:
		return _server_steam_id
	
	for peer in _peers.values():
		if peer.host:
			_server_steam_id = peer.steam_id
			return _server_steam_id
	
	return -1

# Returns whether all peers are connected or not.
func peers_connected() -> bool:
	for peer_id in _peers:
		if _peers[peer_id].connected == false:
			return false
	return true

# RPC method
func _rpc(to_peer_id: int, method: String, args: Array, channel : int, network_type : int = Steam.P2P_SEND_RELIABLE) -> void:
	var to_peer = get_peer(to_peer_id)
	
	if to_peer == null:
		SgGlobalReferences.get_reference("DebugLogger").debug_logger("Cannot send an RPC to a null peer. Check youre completed connected to the network first")
		return
		
	# Check we are connected first
	if not is_peer_connected(SgGlobalReferences.get_reference("SteamManager").get_my_steam_id()):
		SgGlobalReferences.get_reference("DebugLogger").debug_logger("Cannot send an RPC when not connected to the network")
		return
		
	if not is_peer_connected(to_peer.steam_id):
		SgGlobalReferences.get_reference("DebugLogger").debug_logger("Cannot send an RPC to someone who is not connected to the network!")
		return
	
	# Skip sending to network and run locally
	if to_peer.steam_id == SgGlobalReferences.get_reference("SteamManager").get_my_steam_id() and is_server():
		_execute_rpc(to_peer, method, args.duplicate())
		return
	
	if to_peer.steam_id == SgGlobalReferences.get_reference("SteamManager").get_my_steam_id():
		SgGlobalReferences.get_reference("DebugLogger").debug_logger("Client tried to send self an RPC request!")
	
	var packet = PackedByteArray()
	var payload = [method, args]
	
	var serialized_payload = var_to_bytes(payload)
	
	packet.append(PACKET_TYPE.RPC)
	packet.append_array(serialized_payload)
	
	if _send_p2p_packet(to_peer.steam_id, packet, network_type, channel) != true : SgGlobalReferences.get_reference("DebugLogger").debug_logger("Fails '_send_p2p_packet'")

func _create_peer(steam_id) -> Peer:
	var peer = Peer.new()
	peer.steam_id = steam_id
	_peers_confirmed_node_path[steam_id] = []
	
	return peer

func _init_p2p_host(_lobby_id) -> void:
	SgGlobalReferences.get_reference("DebugLogger").debug_logger("Initializing P2P Host as %s" % SgGlobalReferences.get_reference("SteamManager").get_my_steam_id())
	
	var host_peer = _create_peer(SgGlobalReferences.get_reference("SteamManager").get_my_steam_id())
	host_peer.host = true
	host_peer.connected = true
	_peers[SgGlobalReferences.get_reference("SteamManager").get_my_steam_id()] = host_peer
	
	emit_signal("all_peers_connected")
	
func _init_p2p_session(steam_id) -> void:
	if not is_server(): # only server should be initializing p2p requests.
		return
		
	SgGlobalReferences.get_reference("DebugLogger").debug_logger("Initializing P2P Session with %s" % steam_id)
	_peers[steam_id] = _create_peer(steam_id)
	
	emit_signal("peer_status_updated", steam_id)
	_send_p2p_command_packet(steam_id, PACKET_TYPE.HANDSHAKE)

func _close_p2p_session(steam_id) -> void:
	if steam_id == SgGlobalReferences.get_reference("SteamManager").get_my_steam_id():
		if Steam.closeP2PSessionWithUser(steam_id) != false : SgGlobalReferences.get_reference("DebugLogger").debug_logger("Fails 'closeP2PSessionWithUser' [ 1 ]")
		_server_steam_id = 0
		_peers.clear()
		return
	
	SgGlobalReferences.get_reference("DebugLogger").debug_logger("Closing P2P Session with %s" % steam_id)
	
	var session_state = Steam.getP2PSessionState(steam_id)
	if session_state.has("connection_active") and session_state["connection_active"]:
		if Steam.closeP2PSessionWithUser(steam_id) != false : SgGlobalReferences.get_reference("DebugLogger").debug_logger("Fails 'closeP2PSessionWithUser' [ 2 ]")
		
	if _peers.has(steam_id):
		_peers.erase(steam_id)
		
	_server_send_peer_state()

func _send_p2p_command_packet(steam_id, packet_type: int, arg = null, channel : int = 0, network_type : int = Steam.P2P_SEND_RELIABLE) -> void:
	var payload = PackedByteArray()
	payload.append(packet_type)
	
	if arg != null:
		payload.append_array(var_to_bytes(arg))
		
	if not _send_p2p_packet(steam_id, payload, network_type, channel):
		SgGlobalReferences.get_reference("DebugLogger").debug_logger("Failed to send command packet %s" % packet_type)

func _send_p2p_packet(steam_id, data: PackedByteArray, send_type: int = Steam.P2P_SEND_RELIABLE, channel: int = 0) -> bool:
	return Steam.sendP2PPacket(steam_id, data, send_type, channel)

func _broadcast_p2p_packet(data: PackedByteArray, send_type: int = Steam.P2P_SEND_RELIABLE, channel: int = 0) -> void:
	for peer_id in _peers:
		if peer_id != SgGlobalReferences.get_reference("SteamManager").get_my_steam_id():
			if _send_p2p_packet(peer_id, data, send_type, channel) != true : SgGlobalReferences.get_reference("DebugLogger").debug_logger("Fails '_send_p2p_packet'")

func _read_p2p_packet(packet_size : int, channel : int):
	var packet = Steam.readP2PPacket(packet_size, channel) # Packet is a Dict which contains {"data": PoolByteArray, "steamIDRemote": CSteamID}
	
	if packet.is_empty():
		SgGlobalReferences.get_reference("DebugLogger").debug_logger("Steam Networking: read an empty packet with non-zero size!")
		return
	
	# Get the remote user's ID
	var sender_id: int = packet["steam_id_remote"]
	var packet_data: PackedByteArray = packet["data"]

	_handle_packet(sender_id, packet_data, channel)

func _confirm_peer(steam_id):
	if not _peers.has(steam_id):
		SgGlobalReferences.get_reference("DebugLogger").debug_logger("Peer Not Confirmed %s" % steam_id)
		return
	
	_peers[steam_id].connected = true
	emit_signal("peer_status_updated", steam_id)
	_server_send_peer_state()
	
	if peers_connected():
		emit_signal("all_peers_connected")
	
	emit_signal("confirm_peer_on_lobby", steam_id)

func _server_send_peer_state() -> void:
	SgGlobalReferences.get_reference("DebugLogger").debug_logger("Sending Peer State")
	
	var peers = []
	
	for peer in _peers.values():
		peers.append(peer.serialize())
		
	var payload = PackedByteArray()
	
	payload.append(PACKET_TYPE.PEER_STATE)
	payload.append_array(var_to_bytes(peers))
	
	_broadcast_p2p_packet(payload)

func _update_peer_state(payload: PackedByteArray) -> void:
	if is_server():
		return
		
	SgGlobalReferences.get_reference("DebugLogger").debug_logger("Updating Peer State")
	
	var serialized_peers = bytes_to_var(payload)
	var new_peers = []
	
	for serialized_peer in serialized_peers:
		var peer = Peer.new()
		peer.deserialize(serialized_peer)
		
		if not _peers.has(peer.steam_id) or not peer.equal(_peers[peer.steam_id]):
			_peers[peer.steam_id] = peer
			emit_signal("peer_status_updated", peer.steam_id)
		new_peers.append(peer.steam_id)
	
	for peer_id in _peers.keys():
		if not peer_id in new_peers:
			_peers.erase(peer_id)
			emit_signal("peer_status_updated", peer_id)

	emit_signal("peer_updated")

func _handle_packet(sender_id, payload : PackedByteArray, channel : int, network_type : int = Steam.P2P_SEND_RELIABLE) -> void:
	if payload.size() == 0:
		SgGlobalReferences.get_reference("DebugLogger").debug_logger("Cannot handle an empty packet payload!")
		return
	
	var packet_type = payload[0]
	var packet_data : PackedByteArray = []
	
	if payload.size() > 1:
		packet_data = payload.slice(1, payload.size())
		
	match packet_type:
		PACKET_TYPE.HANDSHAKE:
			_send_p2p_command_packet(sender_id, PACKET_TYPE.HANDSHAKE_REPLY, null, channel, network_type)
		PACKET_TYPE.HANDSHAKE_REPLY:
			_confirm_peer(sender_id)
		PACKET_TYPE.PEER_STATE:
			_update_peer_state(packet_data)
		PACKET_TYPE.RPC:
			_handle_rpc_packet(sender_id, packet_data)

func _handle_rpc_packet(sender_id: int, payload: PackedByteArray) -> void:
	var data = bytes_to_var(payload)
	
	#Label sender_id, method, args
	_execute_rpc(get_peer(sender_id), data[0], data[1])

func _execute_rpc(sender, method: String, args: Array) -> void:
	if SgGlobalReferences.get_reference("ServerConnection") == null:
		SgGlobalReferences.get_reference("DebugLogger").debug_logger("Node 'ServerConnection' does not exist on this client! Cannot call RPC")
		return
	
	if not SgGlobalReferences.get_reference("ServerConnection").has_method(method):
		SgGlobalReferences.get_reference("DebugLogger").debug_logger("Node 'ServerConnection' does not have a method %s" % method)
		return
	
	args.push_front(sender.steam_id)
	SgGlobalReferences.get_reference("ServerConnection").call(method, args)

func _on_p2p_session_connect_fail(steam_id: int, session_error) -> void:
	match session_error:
		Steam.P2P_SESSION_ERROR_NONE:
			SgGlobalReferences.get_reference("DebugLogger").debug_logger("Session failure with " + str(steam_id) + " [no error given].")
		Steam.P2P_SESSION_ERROR_NOT_RUNNING_APP:
			SgGlobalReferences.get_reference("DebugLogger").debug_logger("Session failure with " + str(steam_id) + " [target user not running the same game].")
		Steam.P2P_SESSION_ERROR_NO_RIGHTS_TO_APP:
			SgGlobalReferences.get_reference("DebugLogger").debug_logger("Session failure with " + str(steam_id) + " [local user doesn't own app / game].")
		Steam.P2P_SESSION_ERROR_DESTINATION_NOT_LOGGED_ON:
			SgGlobalReferences.get_reference("DebugLogger").debug_logger("Session failure with " + str(steam_id) + " [target user isn't connected to Steam].")
		Steam.P2P_SESSION_ERROR_TIMEOUT:
			SgGlobalReferences.get_reference("DebugLogger").debug_logger("Session failure with " + str(steam_id) + " [connection timed out].")
		Steam.P2P_SESSION_ERROR_MAX:
			SgGlobalReferences.get_reference("DebugLogger").debug_logger("Session failure with " + str(steam_id) + " [unused].")
		_:
			SgGlobalReferences.get_reference("DebugLogger").debug_logger("Session failure with " + str(steam_id) + " [unknown error " + str(session_error) + "].")
	
	emit_signal("peer_session_failure", steam_id, session_error)
	
	if steam_id in _peers:
		_peers[steam_id].connected = false
		emit_signal("peer_status_updated", steam_id)
		_server_send_peer_state()

func _on_p2p_session_request(remote_steam_id):
	SgGlobalReferences.get_reference("DebugLogger").debug_logger("Received p2p session request from %s" % remote_steam_id)
	
	# Only accept this p2p request if its from the host of the lobby.
	if SgGlobalReferences.get_reference("SteamLobby").get_lobby_owner() == remote_steam_id:
		if Steam.acceptP2PSessionWithUser(remote_steam_id) != true : SgGlobalReferences.get_reference("DebugLogger").debug_logger("Fails 'acceptP2PSessionWithUser'")
	else:
		SgGlobalReferences.get_reference("DebugLogger").debug_logger("Got a rogue p2p session request from %s. Not accepting." % remote_steam_id)

class Peer:
	var connected := false
	var steam_id : int
	var host := false
	
	func serialize() -> PackedByteArray:
		var data = [steam_id, connected, host]
		return var_to_bytes(data)

	func deserialize(data: PackedByteArray):
		var unpacked = bytes_to_var(data)
		steam_id = unpacked[0]
		connected = unpacked[1]
		host = unpacked[2]
		
	func equal(peer):
		return peer.steam_id == steam_id and peer.host == host and peer.connected == connected
