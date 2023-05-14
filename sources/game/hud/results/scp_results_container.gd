extends Control

var pref_player_elimination = preload("res://prefabs/game/hud/score/pref_player_eliminations.tscn")

func set_results(data) -> void:
	var total := 0
	self.clear_results()
	
	if data.has("score_result"):
		for player in data["score_result"]:
			var inst_player_elimination = pref_player_elimination.instantiate()
			inst_player_elimination.set_player_result(player, data["score_result"][player])
			
			self.get_node("Elimination/CenterDatas/PlayerResults").add_child(inst_player_elimination)
			total += int(data["score_result"][player])
	
	self.get_node("Elimination/CenterDatas/TotalEliminations/TotalLabel").set_text("TOTAL - " + str(total) + "x")
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)
	self.get_node("AnimationContainer").play("anim_show_results")

func _on_back() -> void:
	self.get_node("AnimationContainer").play("anim_hide_results")
	
	await self.get_tree().create_timer(0.5).timeout
	SgGlobalReferences.get_reference("Transitions").start_anim("anim_transition_out")

func clear_results() -> void:
	for result in self.get_node("Elimination/CenterDatas/PlayerResults").get_children():
		result.queue_free()
