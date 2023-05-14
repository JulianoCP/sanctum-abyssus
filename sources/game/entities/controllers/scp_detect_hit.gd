extends Area2D

func apply_damage(damage, emitter_id) -> void:
	self.get_parent()._on_take_damage(damage, emitter_id)

func disable_detection() -> void:
	self.set_deferred("monitorable", false)

func enable_detection() -> void:
	self.set_deferred("monitorable", true)
