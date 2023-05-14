extends Control

@export var password_input_path : NodePath = "";
@export var preparation_container : NodePath = "";
@export var multiplayer_options_container : NodePath = "";

func _ready():
	self.get_node("Background/VBox_1/HBox_1/OptionsButton").add_item("KEY_INVISIBLE")
	self.get_node("Background/VBox_1/HBox_1/OptionsButton").add_item("KEY_PRIVATE")
	self.get_node("Background/VBox_1/HBox_1/OptionsButton").add_item("KEY_FRIENDS")
	self.get_node("Background/VBox_1/HBox_1/OptionsButton").add_item("KEY_PUBLIC")
	self.get_node("Background/VBox_1/HBox_1/OptionsButton").select(2)

func _on_back_button() -> void:
	self.hide()
	self.get_node(multiplayer_options_container).show()

func _on_create_game_button() -> void:
	self.hide()
	
	SgGlobalReferences.get_reference("SteamLobby").set_steam_lobby_password(get_node(password_input_path).get_text())
	self.get_node(preparation_container).prepare_lobby_to_owner()
	self.get_node(preparation_container).show()
	
	self.get_node("Background/VBox_1/Input").set_text("")

func _on_OptionsButton_item_selected(index):
	match index:
		0:
			self.get_node(password_input_path).hide()
		3:
			self.get_node(password_input_path).hide()
		_:
			self.get_node(password_input_path).show()
