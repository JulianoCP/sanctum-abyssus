extends Node

func _ready() -> void:
	SgGlobalReferences.set_reference("ServerScenes", self)

func rcp_load_scene(data : Dictionary) -> void:
	if data.has("hide_lobby_buttons") and data["hide_lobby_buttons"]:
		SgGlobalReferences.get_reference("PreparationLobby")._hide_preparation_buttons()
	if data.has("show_result") and data["show_result"]:
		SgGlobalReferences.get_reference("HUD").anim_hide_hud()
	
	SgGlobalReferences.get_reference("Transitions").start_anim("anim_transition_in")
	await SgGlobalReferences.get_reference("Transitions").anim_finished
	
	SgGlobalReferences.get_reference("SceneManager").load_scene(data["scene_path"])
	await SgGlobalReferences.get_reference("SceneManager").scene_loaded
	
	if SgGlobalReferences.get_reference("SceneManager").get_current_scene().has_method("load_scene_data"):
		SgGlobalReferences.get_reference("SceneManager").get_current_scene().load_scene_data(data)
	
	if data.has("show_result") and data["show_result"]:
		SgGlobalReferences.get_reference("HUD").show_game_results(data)
