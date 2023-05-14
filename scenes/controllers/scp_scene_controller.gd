extends Node

func _ready() -> void:
	SgGlobalReferences.set_reference("SceneController", self)

func end_game() -> void:
	SgGlobalReferences.get_reference("ServerConnection").send_package_to_multicast(
		{
			"destined_node" : "ServerScenes",
			"method" : "rcp_load_scene",
			"data" : {
				"show_result" : true,
				"scene_path" : "res://scenes/game/scn_lobby_scene.tscn",
				"score_result" : SgGlobalReferences.get_reference("Elimination").get_per_scores()
			}
		}
	)
