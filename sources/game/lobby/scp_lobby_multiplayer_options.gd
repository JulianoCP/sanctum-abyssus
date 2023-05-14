extends Control

@export var configuration_container : NodePath = "";
@export var multiplayer_container : NodePath = "";
@export var middle_menu_container : NodePath = "";

func _join_game() -> void:
	SgGlobalReferences.get_reference("LobbyContainer").activate_manually_join_lobby()

func _host_game() -> void:
	self.hide()
	self.get_node(configuration_container).show()

func _back() -> void:
	SgGlobalReferences.get_reference("LobbyContainer").activate_manually_middle_menu()

func _hide_containers() -> void:
	self.get_node(configuration_container).hide()
	self.get_node(multiplayer_container).hide()
	self.get_node(middle_menu_container).hide()
