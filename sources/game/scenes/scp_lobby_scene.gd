extends Node

func _ready():
	SgGlobalReferences.set_reference("LobbyScene", self)
	SgGlobalReferences.get_reference("GameManager").set_current_game_state(SgGlobalEnums.GAME_CONTEXT.LOBBY)
