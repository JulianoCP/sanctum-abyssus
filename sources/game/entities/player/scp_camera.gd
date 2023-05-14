extends Camera2D

func force_update_player_cam() -> void:
	self.force_update_transform()
	self.force_update_scroll()
