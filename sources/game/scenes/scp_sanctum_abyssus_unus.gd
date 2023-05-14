extends Node

func _ready() -> void:
	SgGlobalReferences.set_reference("SanctumAbyssusUnus", self)
	SgGlobalReferences.get_reference("ServerEntities").request_character()

func load_scene_data(_data : Dictionary) -> void:
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_HIDDEN)
