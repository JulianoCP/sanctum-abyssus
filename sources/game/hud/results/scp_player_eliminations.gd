extends HBoxContainer

func set_player_result(player, kills) -> void:
	self.get_node("PlayerName").set_text(str(player) + " - ")
	self.get_node("Kills").set_text(str(kills) + "x")
