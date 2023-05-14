extends Control

func set_slot_data(data : Dictionary) -> void:
	self.get_node("PlayerName").set_text(data["player_name"])

func disable_prepatation_slot() -> void:
	pass
#	self.get_node("PlayerName").set_self_modulate(Color(0.8, 0.8, 0.8, 0.8))
#	self.get_node("Icon").set_self_modulate(Color(0.8, 0.8, 0.8, 0.8))
#	self.get_node("LoadingIcon").show()
#	self.get_node("LoadingAnim").play("anim_loading_icon_on_player_slot")

func enable_prepatation_slot() -> void:
	pass
#	self.get_node("PlayerName").set_self_modulate(Color(1.0, 1.0, 1.0, 1.0))
#	self.get_node("Icon").set_self_modulate(Color(1.0, 1.0, 1.0, 1.0))
#	self.get_node("LoadingIcon").hide()
#	self.get_node("LoadingAnim").stop()
