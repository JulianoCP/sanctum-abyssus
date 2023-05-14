extends Control

func _join_game() -> void:
	if self.get_node("Input").get_text().length() > 1:
		SgGlobalReferences.get_reference("SteamLobby").join_lobby(int(self.get_node("Input").get_text()))

func _back() -> void:
	SgGlobalReferences.get_reference("LobbyContainer").activate_manually_multiplayer_options_menu()
