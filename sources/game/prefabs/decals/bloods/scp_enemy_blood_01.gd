extends Marker2D

func _ready() -> void:
	self.get_node("Sprite").set_scale(Vector2(randf_range(0.6, 1.2), randf_range(0.6, 1.2)))
	self.get_node("Sprite").set_rotation_degrees(randf_range(-360, 360))

func destroy_decal() -> void:
	self.queue_free()
