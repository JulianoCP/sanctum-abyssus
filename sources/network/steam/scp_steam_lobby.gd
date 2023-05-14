extends Node

signal failed_to_create_lobby
signal lobby_joined(lobby_id)
signal lobby_created(lobby_id)
signal player_left_lobby(steam_id)
signal lobby_data_updated(steam_id)
signal player_joined_lobby(steam_id)
signal lobby_join_requested(lobby_id)
signal lobby_owner_changed(previous_owner, new_owner)
signal chat_message_received(sender_steam_id, profile_name, message)

var _steam_lobby_id := 0
var _steam_lobby_host := 0
var _creating_lobby := false
var _members : Dictionary = {}
var _steam_lobby_password := ""

func _ready() -> void:
	SgGlobalReferences.set_reference("SteamLobby", self)
	
	if SgGlobalReferences.get_reference("SteamManager").get_my_steam_id() == 0:
		SgGlobalReferences.get_reference("DebugLogger").debug_logger("Unable to get steam id of user, check steam has been initialized first.")
		return
	
	if Steam.connect("lobby_created", Callable(self, "_on_lobby_created")) != OK : pass
	if Steam.connect("lobby_match_list", Callable(self, "_on_match_list")) != OK : pass
	if Steam.connect("lobby_joined", Callable(self, "_on_lobby_joined")) != OK : pass
	if Steam.connect("lobby_chat_update", Callable(self, "_on_lobby_chat_update")) != OK : pass
	if Steam.connect("lobby_message", Callable(self, "_on_lobby_message")) != OK : pass
	if Steam.connect("lobby_data_update", Callable(self, "_on_lobby_data_update")) != OK : pass
	if Steam.connect("lobby_invite", Callable(self, "_on_lobby_invite")) != OK : pass
	if Steam.connect("join_requested", Callable(self, "_on_lobby_join_requested")) != OK : pass
	
	# Check for command line arguments
	_check_command_line()

func get_steam_lobby_password() -> String:
	return _steam_lobby_password

func set_steam_lobby_password(value : String) -> void:
	_steam_lobby_password = value

func get_lobby_id() -> int:
	return _steam_lobby_id

func in_lobby() -> bool:
	return not _steam_lobby_id == 0

func is_owner(steam_id = -1) -> bool:
	if steam_id > 0:
		return get_lobby_owner() == steam_id
	return get_lobby_owner() == SgGlobalReferences.get_reference("SteamManager").get_my_steam_id()

func get_lobby_owner():
	return Steam.getLobbyOwner(_steam_lobby_id)

func create_lobby(lobby_type: int, max_players: int) -> void:
	if _creating_lobby:
		return
	_creating_lobby = true
	if _steam_lobby_id == 0:
		SgGlobalReferences.get_reference("DebugLogger").debug_logger("Trying to create lobby of type %s" % lobby_type)
		
		Steam.createLobby(lobby_type, max_players)

func join_lobby(lobby_id: int) -> void:
	SgGlobalReferences.get_reference("DebugLogger").debug_logger("Trying to join lobby %s" % lobby_id)
	
	_members.clear()
	Steam.joinLobby(lobby_id)

func leave_lobby() -> void:
	# If in a lobby, leave it
	if _steam_lobby_id != 0:
		SgGlobalReferences.get_reference("Healths").restore_to_defaul()
		SgGlobalReferences.get_reference("Elimination").restore_to_defaul()
		SgGlobalReferences.get_reference("ServerConnection").restore_to_defaul()
		SgGlobalReferences.get_reference("DebugLogger").debug_logger("Leaving Lobby %s" % _steam_lobby_id)
		
		# Send leave request to Steam
		Steam.leaveLobby(_steam_lobby_id)
		# Wipe the Steam lobby ID then display the default lobby ID and player list title
		_steam_lobby_id = 0
		# Close session with all users
		# This is a bit of a hack for now to keep SteamNetwork isolated
		for steam_id in _members.keys():
			var session_state = Steam.getP2PSessionState(steam_id)
			if session_state.has("connection_active") and session_state["connection_active"]:
				# warning-ignore:return_value_discarded
				Steam.closeP2PSessionWithUser(steam_id)
				SgGlobalReferences.get_reference("SteamConnection")._close_p2p_session(steam_id)
		# Clear the local lobby list
		_members.clear()
		emit_signal("player_left_lobby", SgGlobalReferences.get_reference("SteamManager").get_my_steam_id())

func get_lobby_members() -> Dictionary:
	_update_lobby_members()
	return _members
	
func send_chat_message(message: String) -> bool:
	return Steam.sendLobbyChatMsg(_steam_lobby_id, message)

func _on_lobby_created(connect_id, lobby_id) -> void:
	SgGlobalReferences.get_reference("DebugLogger").debug_logger("Lobby Created called")
	
	_creating_lobby = false
	if connect_id == 1:
		_steam_lobby_id = lobby_id
		SgGlobalReferences.get_reference("DebugLogger").debug_logger("Created Steam Lobby with id: %s" % lobby_id)
		
		var relay = Steam.allowP2PPacketRelay(true)
		SgGlobalReferences.get_reference("DebugLogger").debug_logger("Relay configuration response: %s" % relay)
		
		emit_signal("lobby_created", lobby_id)
	else:
		SgGlobalReferences.get_reference("DebugLogger").debug_logger("Failed to create lobby: %s" % connect_id)
		emit_signal("failed_to_create_lobby")

# warning-ignore:unused_argument
func _on_lobby_joined(lobby_id: int, _permissions, _locked: bool, _response) -> void:
	SgGlobalReferences.get_reference("DebugLogger").debug_logger("Lobby Joined!")
	
	_steam_lobby_id = lobby_id
	_update_lobby_members()
	emit_signal("lobby_joined", lobby_id)

# warning-ignore:unused_argument
func _on_lobby_join_requested(lobby_id: int, _friend_id) -> void:
	SgGlobalReferences.get_reference("DebugLogger").debug_logger("Attempting to join lobby %s from request" % lobby_id)
	
	# Attempt to join the lobby
	emit_signal("lobby_join_requested", lobby_id)
#	join_lobby(lobby_id)

func get_steam_lobby_host() -> int:
	return _steam_lobby_host

func _update_lobby_members() -> void:
	# Clear your previous lobby list
	_members.clear()

	_steam_lobby_host = Steam.getLobbyOwner(_steam_lobby_id)

	# Get the number of members from this lobby from Steam
	var num_members: int = Steam.getNumLobbyMembers(_steam_lobby_id)

	# Get the data of these players from Steam
	for member_index in range(0, num_members):

		# Get the member's Steam ID
		var member_steam_id = Steam.getLobbyMemberByIndex(_steam_lobby_id, member_index)

		# Get the member's Steam name
		var member_steam_name = Steam.getFriendPersonaName(member_steam_id)

		# Add them to the list
		_members[member_steam_id] = member_steam_name

# warning-ignore:unused_argument
func _on_lobby_invite(_inviter, _lobby, _game) -> void:
	pass
	
# warning-ignore:unused_argument
func _on_lobby_data_update(success, _lobby_id, member_id) -> void:
	if success:
		# check for host change
		var host = Steam.getLobbyOwner(_steam_lobby_id)
		if host != _steam_lobby_host and host > 0:
			_owner_changed(_steam_lobby_host, host)
			_steam_lobby_host = host
		emit_signal("lobby_data_updated", member_id)

func _owner_changed(was_steam_id, now_steam_id) -> void:
	emit_signal("lobby_owner_changed", was_steam_id, now_steam_id)

func _on_lobby_message(result, sender_steam_id, message, chat_type) -> void:
	if result == 0:
		SgGlobalReferences.get_reference("DebugLogger").debug_logger("Received lobby message, but 0 bytes were retrieved!")
	match(chat_type):
		Steam.CHAT_ENTRY_TYPE_CHAT_MSG:
			if not _members.has(sender_steam_id):
				SgGlobalReferences.get_reference("DebugLogger").debug_logger("Received a message from a user we dont have locally!")
			var profile_name = _members[sender_steam_id]
			emit_signal("chat_message_received", sender_steam_id, profile_name, message)
		_:
			SgGlobalReferences.get_reference("DebugLogger").debug_logger("Unhandled chat message type received: %s" % chat_type)

# warning-ignore:unused_argument
func _on_lobby_chat_update(_lobby_id, changed_user_steam_id, user_made_change_steam_id, chat_state) -> void:
	match chat_state:
		Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
			SgGlobalReferences.get_reference("DebugLogger").debug_logger("Player joined lobby %s" % changed_user_steam_id)
			emit_signal("player_joined_lobby", changed_user_steam_id)
		Steam.CHAT_MEMBER_STATE_CHANGE_LEFT:
			SgGlobalReferences.get_reference("DebugLogger").debug_logger("Player left the lobby %s" % changed_user_steam_id)
			emit_signal("player_left_lobby", changed_user_steam_id)
		Steam.CHAT_MEMBER_STATE_CHANGE_KICKED:
			SgGlobalReferences.get_reference("DebugLogger").debug_logger("Player %s was kicked by %s" % [changed_user_steam_id, user_made_change_steam_id])
			emit_signal("player_left_lobby", changed_user_steam_id)
		Steam.CHAT_MEMBER_STATE_CHANGE_BANNED:
			SgGlobalReferences.get_reference("DebugLogger").debug_logger("Player %s was banned by %s" % [changed_user_steam_id, user_made_change_steam_id])
			emit_signal("player_left_lobby", changed_user_steam_id)
		Steam.CHAT_MEMBER_STATE_CHANGE_DISCONNECTED:
			SgGlobalReferences.get_reference("DebugLogger").debug_logger("Player disconnected %s" % [changed_user_steam_id, user_made_change_steam_id])
			emit_signal("player_left_lobby", changed_user_steam_id)

# warning-ignore:unused_argument
func _on_match_list(_lobbies) -> void:
	pass
	
func _check_command_line() -> void:
	var args = OS.get_cmdline_args()

	# There are arguments to process
	if args.size() > 0:
		var _lobby_invite_arg := false
		# Loop through them and get the useful ones
		for arg in args:
			print("Command line: "+str(arg))

			# An invite argument was passed
			if _lobby_invite_arg:
				emit_signal("lobby_join_requested", int(arg))
#				join_lobby(int(arg))

			# A Steam connection argument exists
			if arg == "+connect_lobby":
				_lobby_invite_arg = true

func _exit_tree() -> void:
	leave_lobby()
