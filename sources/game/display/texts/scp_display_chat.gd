extends RichTextLabel

func add_message_to_chat(message : String) -> void:
	self.set_text(self.get_text() + str(message) + "\n")

func clear_chat() -> void:
	self.set_text("")
