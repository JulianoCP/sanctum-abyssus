extends Label

func prepare_logger(message, logger_type, time_left) -> void:
	match logger_type:
		SgEnumDebug.debug_logger_type.WARNING:
			self.set("theme_override_colors/font_color", Color("#ffdf11"))
			self.set_text(str(message))
		SgEnumDebug.debug_logger_type.ERROR:
			self.set("theme_override_colors/font_color", Color("#ff1111"))
			self.set_text(str(message))
		SgEnumDebug.debug_logger_type.LOG:
			self.set("theme_override_colors/font_color", Color("#11ffeb"))
			self.set_text(str(message))
		
	var timer : Timer = Timer.new()
	self.add_child(timer)
	
	if timer.connect("timeout", Callable(self, "_on_timeout")) != null : pass
	timer.start(time_left)

func _on_timeout() -> void:
	self.queue_free()
