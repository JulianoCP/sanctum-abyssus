extends cBASE_PROJECTILE

var emitter_id := ""

func _ready() -> void:
	self.get_node("TimeLeft").start(life_span)

func _on_time_left_timeout() -> void:
	self.queue_free()

func _on_body_shape_entered(_body_rid, body, _body_shape_index, _local_shape_index) -> void:
	if body.is_in_group("LowPavement"):
		self.set_physics_process(false)
		
		self.get_node("BulletSprite").hide()
		self.get_node("Spread").play()

func _on_spread_animation_finished() -> void:
	self.queue_free()

func set_client_emitter(value) -> void:
	emitter_id = str(value)

func _on_area_entered(area) -> void:
	if area.is_in_group("Enemy"):
		self.set_physics_process(false)
		
		self.get_node("BulletSprite").hide()
		self.get_node("Spread").play()
		
		area.apply_damage(damage, emitter_id)
