extends Node

@export var path_from_character_spawns : NodePath = ""
@export var path_player_spawn_location : NodePath = ""
@export var pref_player_character := "res://prefabs/game/entities/player/pref_player_character.tscn"

var game_already_finished := false
var controllers_connected := {}
var have_alive_players := true
var spawns_nodes := []

func _ready() -> void:
	SgGlobalReferences.set_reference("CharactersControl", self)
	
	if SgGlobalReferences.get_reference("SteamLobby").is_owner():
		for spawn in self.get_node(path_from_character_spawns).get_children():
			spawns_nodes.append(spawn)

func _get_character_position(peer_id) -> Vector2i:
	if controllers_connected.has(peer_id) and controllers_connected[peer_id].has("character_reference"):
		return controllers_connected[peer_id]["character_reference"].get_position().round()
	else:
		return Vector2i.ZERO

func _get_character_reference(peer_id) -> Object:
	if controllers_connected.has(peer_id) and controllers_connected[peer_id].has("character_reference"):
			return controllers_connected[peer_id]["character_reference"]
	return null

func get_have_alive_players() -> bool:
	return have_alive_players

func _get_random_character_target() -> int:
	var players := controllers_connected.keys()
	players.shuffle()
	
	if players.size() > 0:
		for player in players:
			if !controllers_connected[player]["is_death"]:
				return player
		
		have_alive_players = false
		
		if !game_already_finished:
			game_already_finished = true
			SgGlobalReferences.get_reference("SceneController").end_game()
	return -1

func remote_create_character(data : Dictionary) -> void:
	for peer in data["peers"]:
		if !controllers_connected.has(peer):
			controllers_connected[peer] = data["peers"][peer]
			
			var start_location : Vector2 = Vector2.ZERO
			var instance_player_character = load(pref_player_character).instantiate()
			
			if Vector2(data["peers"][peer]["start_location"]) == Vector2.ZERO:
				start_location = spawns_nodes[randi() % spawns_nodes.size()].get_possible_position_to_spawn()
			else:
				start_location = Vector2(data["peers"][peer]["start_location"])
			
			instance_player_character.set_player_character_info("steam_id", peer)
			instance_player_character.set_player_character_info("steam_name", data["peers"][peer]["steam_name"])
			
			instance_player_character.set_position(start_location)
			instance_player_character.notify_player_was_created()
			
			self.add_child(instance_player_character);
			controllers_connected[peer]["character_reference"] = instance_player_character

func set_player_death(peer_id) -> void:
	controllers_connected[peer_id]["is_death"] = true
	SgGlobalReferences.get_reference("WavesControl").notify_player_death(peer_id)

func remote_notify_player_death(data) -> void:
	if controllers_connected.has(data["steam_id"]):
		controllers_connected[data["steam_id"]]["character_reference"].remote_on_death()

func remote_notify_player_status(data) -> void:
	SgGlobalReferences.get_reference("Healths").update_status(data)

func try_spectate() -> bool:
	var have_a_player_alive := false
	var players := controllers_connected.keys()
	
	players.shuffle()
	
	for player in players:
		if !controllers_connected[player]["is_death"]:
			have_a_player_alive = true
			controllers_connected[player]["character_reference"].enable_player_camera()
	
	if !have_a_player_alive:
		SgGlobalReferences.get_reference("DebugLogger").debug_logger("Dont have more players alive!")
	
	return have_a_player_alive

func remote_sync_character_movement(data) -> void:
	if controllers_connected.has(data[1]):
		controllers_connected[data[1]]["character_reference"].remote_sync_character_movement(data)

func remote_shot(data) -> void:
	if controllers_connected.has(data[1]):
		controllers_connected[data[1]]["character_reference"].remote_shot_from_server(data)
