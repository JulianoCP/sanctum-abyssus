extends Node

func _ready():
	SgGlobalReferences.set_reference("ServerEntities", self)

func request_character() -> void:
	SgGlobalReferences.get_reference("ServerConnection").send_package_to_server(
		{
			"destined_node" : "ServerEntities",
			"method" : "rpc_sync_spawn_characters",
			"data" : {
				"is_death" : false,
				"start_location" : Vector2.ZERO,
				"steam_id" : SgGlobalReferences.get_reference("SteamManager").get_my_steam_id(),
				"steam_name" : SgGlobalReferences.get_reference("SteamManager").get_my_steam_name()
			}
		}
	)

func spawn_character_to_player(data : Dictionary) -> void:
	if SgGlobalReferences.get_reference("CharactersControl") != null:
		SgGlobalReferences.get_reference("CharactersControl").remote_create_character(data)

func rpc_sync_spawn_characters(data : Dictionary) -> void:
	if !SgGlobalReferences.get_reference("ServerConnection").get_connected_peers().has(data["steam_id"]):
		SgGlobalReferences.get_reference("ServerConnection").add_new_connected_peer(data["steam_id"], data)
		self.spawn_character_to_player({"peers" : SgGlobalReferences.get_reference("ServerConnection").get_connected_peers()})

func receive_sync_character_movement(data) -> void:
	if SgGlobalReferences.get_reference("CharactersControl") != null:
		SgGlobalReferences.get_reference("CharactersControl").remote_sync_character_movement(data)

func receive_shot_from_server(data) -> void:
	if SgGlobalReferences.get_reference("CharactersControl") != null:
		SgGlobalReferences.get_reference("CharactersControl").remote_shot(data)

func receive_spawn_enemy_on_multicast(data) -> void:
	if SgGlobalReferences.get_reference("WavesControl") != null:
		SgGlobalReferences.get_reference("WavesControl").remote_spawn_enemy(data)

func receive_sync_enemy_movement(data) -> void:
	if SgGlobalReferences.get_reference("WavesControl") != null:
		SgGlobalReferences.get_reference("WavesControl").remote_sync_enemy_movement(data)

func _notify_spawn_character(steam_id, location) -> void:
	SgGlobalReferences.get_reference("ServerConnection").set_value_on_connected_peer(steam_id, "start_location", location)
	
	SgGlobalReferences.get_reference("ServerConnection").send_package_to_multicast(
		{
			"destined_node" : "ServerEntities",
			"method" : "spawn_character_to_player",
			"data" : {
				"peers" : SgGlobalReferences.get_reference("ServerConnection").get_connected_peers()
			}
		}
	)

func _notify_player_death(data) -> void:
	if SgGlobalReferences.get_reference("CharactersControl") != null:
		SgGlobalReferences.get_reference("CharactersControl").remote_notify_player_death(data)

func _notify_spawn_enemy(data) -> void:
	if SgGlobalReferences.get_reference("WavesControl") != null:
		SgGlobalReferences.get_reference("WavesControl").remote_spawn_enemy(data)

func _notify_player_status(data) -> void:
	if SgGlobalReferences.get_reference("CharactersControl") != null:
		SgGlobalReferences.get_reference("CharactersControl").remote_notify_player_status(data)

func remote_sync_characters_position(data) -> void:
	if SgGlobalReferences.get_reference("CharactersControl") != null:
		SgGlobalReferences.get_reference("CharactersControl").remote_sync_character_position(data)
