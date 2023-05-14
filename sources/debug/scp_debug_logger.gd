extends Node

@export var enable_logger := true
@export var print_on_output := true
@export var print_on_screen := true
@export var time_to_remove_logger : int = 3 

func _ready() -> void:
	SgGlobalReferences.set_reference("DebugLogger", self)

func debug_logger(message, logger_type = SgEnumDebug.debug_logger_type.LOG) -> void:
	if enable_logger:
		if print_on_output:
			print(str(message))
		
		if print_on_screen:
			match logger_type:
				SgEnumDebug.debug_logger_type.WARNING:
					self.logger_instance(message, logger_type)
				SgEnumDebug.debug_logger_type.ERROR:
					self.logger_instance(message, logger_type)
				SgEnumDebug.debug_logger_type.LOG:
					self.logger_instance(message, logger_type)

func logger_instance(message, logger_type) -> void:
	var message_instance : Object = load("res://prefabs/debug/pref_logger_message.tscn").instantiate()
	self.get_node("LoggerCanvas/LoggerContainer").add_child(message_instance)
	
	message_instance.prepare_logger(message, logger_type, time_to_remove_logger)

func update_latency(value) -> void:
	self.get_node("LoggerCanvas/LatencyLabel").set_text(str(Engine.get_frames_per_second()) + " FPS  " + str(value) + " MS")
