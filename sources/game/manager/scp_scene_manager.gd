extends Node

signal scene_loaded

func _ready() -> void:
	SgGlobalReferences.set_reference("SceneManager", self)

func load_scene(scene_path : String) -> void:
	SgGlobalSceneManagement.change_scene(scene_path)
	await SgGlobalSceneManagement.SceneChanged
	emit_signal("scene_loaded")

func get_current_scene() -> Object:
	if get_children().size() > 0:
		return get_child(get_children().size() - 1)
	return null
