extends Node

@export var path_score_container : NodePath = ""

func _ready() -> void:
	SgGlobalReferences.set_reference("HUD", self)
	self.force_hide_hud()

func force_hide_hud() -> void:
	self.get_node(path_score_container).hide()

func anim_show_hud() -> void:
	self.get_node(path_score_container).show_container()

func anim_hide_hud() -> void:
	self.get_node(path_score_container).hide_container()

func show_game_results(data) -> void:
	SgGlobalReferences.get_reference("SteamLobby").leave_lobby()
	self.get_node("Score/ResultsContainer").set_results(data)
