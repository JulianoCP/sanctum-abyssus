extends Control

@export var multiplayer_container : NodePath = "";
@export var join_lobby_container : NodePath = "";
@export var multiplayer_options_container : NodePath = "";

func _single_player() -> void:
	print("single_player")

func _multiplayer() -> void:
	SgGlobalReferences.get_reference("LobbyContainer").activate_manually_multiplayer_options_menu()

func _setting() -> void:
	print("_setting")

func _credits() -> void:
	self.get_node("CreditsPopup").show()

func _on_credits_back_button() -> void:
	self.get_node("CreditsPopup").hide()
