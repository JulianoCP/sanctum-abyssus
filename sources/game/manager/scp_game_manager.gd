extends Node

@export var first_scene_to_load := ""

var current_game_state = SgGlobalEnums.GAME_CONTEXT.NONE

func _ready() -> void:
	SgGlobalReferences.set_reference("GameManager", self)
	SgGlobalReferences.get_reference("SceneManager").load_scene(first_scene_to_load)

func set_current_game_state(value) -> void:
	current_game_state = value

func get_current_game_state() -> int:
	return current_game_state
