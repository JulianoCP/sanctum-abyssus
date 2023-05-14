extends Control

func show_container() -> void:
	self.get_node("AnimationContainer").play("anim_score_container")

func hide_container() -> void:
	self.get_node("AnimationContainer").play("anim_hide_score_container")
