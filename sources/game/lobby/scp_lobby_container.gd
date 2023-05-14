extends Control

@export var middle_menu_container : NodePath = "";
@export var multiplayer_container : NodePath = "";
@export var multiplayer_options_container : NodePath = "";
@export var multiplayer_join_lobby_container : NodePath = "";
@export var multiplayer_preparation_container : NodePath = "";
@export var multiplayer_configuration_container : NodePath = "";

func _ready() -> void:
	SgGlobalReferences.set_reference("LobbyContainer", self)
	
	self.hide_all_containers()
	self.get_node(middle_menu_container).show()

func hide_all_containers() -> void:
	self.get_node(middle_menu_container).hide()
	self.get_node(multiplayer_container).hide()
	self.get_node(multiplayer_options_container).hide()
	self.get_node(multiplayer_join_lobby_container).hide()
	self.get_node(multiplayer_preparation_container).hide()
	self.get_node(multiplayer_configuration_container).hide()

func activate_manually_preparation_lobby() -> void:
	self.hide_all_containers()
	self.get_node(multiplayer_container).show()
	self.get_node(multiplayer_preparation_container).show()

func activate_manually_middle_menu() -> void:
	self.hide_all_containers()
	self.get_node(middle_menu_container).show()

func activate_manually_multiplayer_options_menu() -> void:
	self.hide_all_containers()
	self.get_node(multiplayer_container).show()
	self.get_node(multiplayer_options_container).show()

func activate_manually_join_lobby() -> void:
	self.hide_all_containers()
	self.get_node(multiplayer_container).show()
	self.get_node(multiplayer_join_lobby_container).show()
