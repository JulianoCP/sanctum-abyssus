extends Control

@export var chat_nodepath : NodePath = ""
@export var input_nodepath : NodePath = ""
@export var players_contianer_nodepath : NodePath = ""
@export var start_game_button_nodepath : NodePath = ""
@export var leave_game_button_nodepath : NodePath = ""

var _members_on_lobby : Dictionary = {}
var _lobby_owner : int = 0

func _ready() -> void:
	SgGlobalReferences.set_reference("PreparationLobby", self)
	
	if SgGlobalReferences.get_reference("SteamLobby").connect("lobby_created", Callable(self, "_on_create_game")) != OK: pass
	if SgGlobalReferences.get_reference("SteamLobby").connect("lobby_joined", Callable(self, "_on_lobby_joined")) != OK: pass
	if SgGlobalReferences.get_reference("SteamLobby").connect("chat_message_received", Callable(self, "_on_lobby_message")) != OK: pass
	if SgGlobalReferences.get_reference("SteamLobby").connect("player_left_lobby", Callable(self, "_on_player_left_lobby")) != OK: pass
	if SgGlobalReferences.get_reference("SteamLobby").connect("player_joined_lobby", Callable(self, "_on_player_join_lobby")) != OK: pass
	if SgGlobalReferences.get_reference("SteamLobby").connect("lobby_join_requested", Callable(self, "_on_lobby_join_requested")) != OK: pass
	if SgGlobalReferences.get_reference("SteamLobby").connect("failed_to_create_lobby", Callable(self, "_on_failed_to_create_lobby")) != OK: pass
	if SgGlobalReferences.get_reference("SteamConnection").connect("confirm_peer_on_lobby", Callable(self, "_on_confirm_peer_on_lobby")) != OK: pass

func _exit_tree():
	SgGlobalReferences.set_reference("PreparationLobby", null)

func _on_create_game(data) -> void:
	self.add_message_to_chat("[color=aqua][SERVER-INFO][/color] - [color=lime]LOBBY CREATED!\n[/color]")
	self.add_message_to_chat("[color=aqua][SERVER-INFO][/color] - [color=lime]LOBBY-ID: " + str(data) + "\n[/color]")
	self.get_node(start_game_button_nodepath).show()

func _on_lobby_joined(data) -> void:
	_lobby_owner = SgGlobalReferences.get_reference("SteamLobby").get_lobby_owner()
	
	self.add_message_to_chat("[color=aqua][SERVER-INFO][/color] - [color=lime]JOINED ON LOBBY-ID: " + str(data) + "\n[/color]")
	SgGlobalReferences.get_reference("LobbyContainer").activate_manually_preparation_lobby()
	self.sync_players_in_lobby_slots()

func _on_lobby_join_requested(data) -> void:
	self.add_message_to_chat("[color=aqua][SERVER-INFO][/color] - [color=yellow]Requesting lobby entry...[/color]")
	SgGlobalReferences.get_reference("SteamLobby").join_lobby(data)

func _on_failed_to_create_lobby() -> void:
	self.add_message_to_chat("[color=aqua][SERVER-INFO][/color] - [color=red]FAILURE TO CREATE THE LOBBY ![/color]")

func _on_player_join_lobby(data) -> void:
	if SgGlobalReferences.get_reference("SteamLobby").get_lobby_members().has(data):
		self.add_message_to_chat("[color=aqua][SERVER-INFO][/color] - [color=lime][color=yellow]" + SgGlobalReferences.get_reference("SteamLobby").get_lobby_members()[data] + "[/color] joined on lobby\n[/color]")
		_members_on_lobby[data] = {
			"steam_name" : SgGlobalReferences.get_reference("SteamLobby").get_lobby_members()[data],
			"is_confirmed" : false
		}
		self._verify_to_start_game()
	else:
		self.add_message_to_chat("[color=aqua][SERVER-INFO][/color] - [color=lime][color=yellow]" + "New player" + "[/color] joined on lobby\n[/color]")
	self.sync_players_in_lobby_slots()

func _on_confirm_peer_on_lobby(data) -> void:
	if _members_on_lobby.has(data):
		_members_on_lobby[data]["is_confirmed"] = true
		
		if _members_on_lobby[data].has("slot_instance"):
			_members_on_lobby[data]["slot_instance"].enable_prepatation_slot()
		
	self._verify_to_start_game()

func _verify_to_start_game() -> void:
	for member in _members_on_lobby:
		if !_members_on_lobby[member]["is_confirmed"]:
			self.get_node(start_game_button_nodepath).set_disabled(true)
			return
	self.get_node(start_game_button_nodepath).set_disabled(false)

func _on_lobby_message(_sender_id, profile_name, message) -> void:
	self.add_message_to_chat("[color=yellow][" + profile_name + "][/color]: " + message)

func _on_player_left_lobby(data) -> void:
	if data != SgGlobalReferences.get_reference("SteamManager").get_my_steam_id():
		if data == _lobby_owner:
			self.leave_from_steam_lobby()
		else:
			if _members_on_lobby.has(data):
				self.add_message_to_chat("[color=aqua][SERVER-INFO][/color] - [color=lime][color=yellow]" + _members_on_lobby[data]["steam_name"] + "[/color] left lobby\n[/color]")
			else:
				self.add_message_to_chat("[color=aqua][SERVER-INFO][/color] - [color=lime][color=yellow]" + "Player" + "[/color] left lobby\n[/color]")
			self.sync_players_in_lobby_slots()

func leave_from_steam_lobby() -> void:
	SgGlobalReferences.get_reference("LobbyContainer").activate_manually_middle_menu()
	SgGlobalReferences.get_reference("SteamLobby").leave_lobby()
	
	_members_on_lobby.clear()
	
	self.clear_player_in_lobby_slots()
	self.clear_chat()

func _hide_preparation_buttons() -> void:
	self.get_node(start_game_button_nodepath).hide()
	self.get_node(leave_game_button_nodepath).hide()

func _start_game() -> void:
	self.add_message_to_chat("[color=aqua][SERVER-INFO][/color] - [color=lime]Starting the Game\n[/color]")
	
	if _lobby_owner == SgGlobalReferences.get_reference("SteamManager").get_my_steam_id():
		SgGlobalReferences.get_reference("ServerControl").start_timers()
		
		SgGlobalReferences.get_reference("ServerConnection").send_package_to_multicast(
			{
				"destined_node" : "ServerScenes",
				"method" : "rcp_load_scene",
				"data" : {
					"scene_path" : "res://scenes/game/scn_sanctum_abyssus_unus.tscn",
					"hide_lobby_buttons" : true
				}
			}
		)

func sync_players_in_lobby_slots() -> void:
	self.clear_player_in_lobby_slots()
	
	var member_ids = SgGlobalReferences.get_reference("SteamLobby").get_lobby_members().keys()
	var member_names = SgGlobalReferences.get_reference("SteamLobby").get_lobby_members()
	
	for member_id in member_ids:
		var player_slot_instance : Object = load("res://prefabs/game/lobby/preparation/pref_preparation_player_slot.tscn").instantiate()
		player_slot_instance.set_slot_data(
			{
				"player_name" : member_names[member_id]
			}
		)
		
		if _members_on_lobby.has(member_id):
			player_slot_instance.disable_prepatation_slot()
			_members_on_lobby[member_id]["slot_instance"] = player_slot_instance
			
		self.get_node(players_contianer_nodepath).add_child(player_slot_instance)

func clear_player_in_lobby_slots() -> void:
	for player_container in self.get_node(players_contianer_nodepath).get_children():
		player_container.queue_free()

func add_message_to_chat(message : String) -> void:
	self.get_node(chat_nodepath).add_message_to_chat(message)

func clear_chat() -> void:
	self.get_node(chat_nodepath).clear_chat()

func prepare_lobby_to_owner(lobby_type = SgEnumSteam.lobby_type.Friends) -> void:
	SgGlobalReferences.get_reference("SteamLobby").create_lobby(SgEnumSteam.lobby_type.Friends, 5)
	
	self.add_message_to_chat("[color=aqua][SERVER-INFO][/color] - [color=lime]CREATING LOBBY...[/color]")

func _on_send_button_down() -> void:
	if self.get_node(input_nodepath).get_text().length() > 0:
		if SgGlobalReferences.get_reference("SteamLobby").send_chat_message(self.get_node(input_nodepath).get_text()) != true : pass
		self.get_node(input_nodepath).set_text("")

func _on_Input_text_entered(input_text):
	if input_text.length() > 0:
		if SgGlobalReferences.get_reference("SteamLobby").send_chat_message(input_text) != true : pass
		self.get_node(input_nodepath).set_text("")
