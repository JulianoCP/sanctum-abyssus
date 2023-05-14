extends Node

var connected_peers := {}

func _ready() -> void:
	SgGlobalReferences.set_reference("ServerConnection", self)

func restore_to_defaul() -> void:
	connected_peers.clear()

func add_new_connected_peer(key, data) -> void:
	connected_peers[key] = data
	
func get_connected_peers() -> Dictionary:
	return connected_peers

func get_connected_peer(key) -> Dictionary:
	if connected_peers.has(key):
		return connected_peers[key]
	return {}

func set_value_on_connected_peer(key, sub_key, data) -> void:
	connected_peers[key][sub_key] = data

func send_package_to_server(package : Dictionary, channel : int = SgGlobalEnums.CHANNELS.CHANNEL_0, network_type : int = Steam.P2P_SEND_RELIABLE) -> void:
	SgGlobalReferences.get_reference("SteamConnection").rpc_on_server("receive_package", SgGlobalSerializeManagement.serialize(package), channel, network_type)

func send_package_to_multicast(package : Dictionary, channel : int = SgGlobalEnums.CHANNELS.CHANNEL_0, network_type : int = Steam.P2P_SEND_RELIABLE) -> void:
	SgGlobalReferences.get_reference("SteamConnection").rpc_all_clients("receive_package", SgGlobalSerializeManagement.serialize(package), channel, network_type)

func send_package_to_client(peer_id : int, package : Dictionary, channel : int = SgGlobalEnums.CHANNELS.CHANNEL_0, network_type : int = Steam.P2P_SEND_RELIABLE) -> void:
	SgGlobalReferences.get_reference("SteamConnection").rpc_on_client(peer_id,"receive_package", SgGlobalSerializeManagement.serialize(package), channel, network_type)

func receive_package(data : Array) -> void:
	var _player_id : int = data.pop_front()
	var extracted_data = SgGlobalSerializeManagement.deserialize(data[0], data[1])
	
	if extracted_data != null and typeof(extracted_data) == TYPE_DICTIONARY and extracted_data.has("method") and extracted_data.has("data") and extracted_data.has("destined_node"):
		SgGlobalReferences.get_reference("Server").get_internal_node(extracted_data["destined_node"]).call(extracted_data["method"], extracted_data["data"])
	else:
		SgGlobalReferences.get_reference("DebugLogger").debug_logger("Fails on 'receive_package'")

###########################################################
################ | FAST PACKAGES--CONTEXT | ###############
###########################################################

func udp_method_on_server(method : String, package : Array, channel : int = SgGlobalEnums.CHANNELS.CHANNEL_1, network_type : int = Steam.P2P_SEND_UNRELIABLE_NO_DELAY) -> void:
	SgGlobalReferences.get_reference("SteamConnection").rpc_on_server(method, package, channel, network_type)

func udp_method_on_multicast(method : String, package : Array, channel : int = SgGlobalEnums.CHANNELS.CHANNEL_1, network_type : int = Steam.P2P_SEND_UNRELIABLE_NO_DELAY) -> void:
	SgGlobalReferences.get_reference("SteamConnection").rpc_all_clients(method, package, channel, network_type)

func tcp_method_on_server(method : String, package : Array, channel : int = SgGlobalEnums.CHANNELS.CHANNEL_1, network_type : int = Steam.P2P_SEND_RELIABLE_WITH_BUFFERING) -> void:
	SgGlobalReferences.get_reference("SteamConnection").rpc_on_server(method, package, channel, network_type)

func tcp_method_on_multicast(method : String, package : Array, channel : int = SgGlobalEnums.CHANNELS.CHANNEL_1, network_type : int = Steam.P2P_SEND_RELIABLE_WITH_BUFFERING) -> void:
	SgGlobalReferences.get_reference("SteamConnection").rpc_all_clients(method, package, channel, network_type)

func receive_movement_on_server(data : Array) -> void:
	if SgGlobalReferences.get_reference("CharactersControl") != null:
		var result : Vector2 = SgGlobalReferences.get_reference("CharactersControl")._get_character_position(data[0])
		
		# Add character position.
		data.append(result.x)
		data.append(result.y)
		
		self.udp_method_on_multicast("receive_movement_on_multicast", data)

func receive_movement_on_multicast(data : Array) -> void:
	SgGlobalReferences.get_reference("ServerEntities").receive_sync_character_movement(data)

func receive_shot_from_server(data : Array) -> void:
	SgGlobalReferences.get_reference("ServerEntities").receive_shot_from_server(data)

func receive_spawn_enemy_on_multicast(data : Array) -> void:
	SgGlobalReferences.get_reference("ServerEntities").receive_spawn_enemy_on_multicast(data)

func receive_enemy_movement_on_multicast(data : Array) -> void:
	SgGlobalReferences.get_reference("ServerEntities").receive_sync_enemy_movement(data)
