extends Button

@export var nodepath_to_call_method : NodePath = ""
@export var call_the_method : String = ""
@export var translate_key : String = ""

func _enter_tree():
	self.set_text(translate_key)

func _on_PrefabLobbyMiddleButton_button_down():
	if nodepath_to_call_method != null:
		if call_the_method != "":
			if self.get_node(nodepath_to_call_method).has_method(call_the_method):
				self.get_node(nodepath_to_call_method).call(call_the_method)
			else:
				SgGlobalReferences.get_reference("DebugLogger").debug_logger(
					"Method not found",
					SgEnumDebug.debug_logger_type.ERROR
				)
		else:
			SgGlobalReferences.get_reference("DebugLogger").debug_logger(
				"The method is empty",
				SgEnumDebug.debug_logger_type.ERROR
			)
	else:
		SgGlobalReferences.get_reference("DebugLogger").debug_logger(
			"The nodepath is null",
			SgEnumDebug.debug_logger_type.ERROR
		)
