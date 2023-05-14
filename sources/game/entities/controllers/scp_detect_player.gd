extends Node2D

var distance_offset := 16.0
var damage := 10

func start_timers() -> void:
	self.get_node("TryHitPlayer").start()

func _on_try_hit_player_timeout() -> void:
	if self.get_parent().get_target() != null:
		if self.get_parent().get_distance_to_target() <= self.get_parent().get_distance_to_attack_player() + distance_offset:
			self.get_parent().get_target()._on_take_damage(damage)
