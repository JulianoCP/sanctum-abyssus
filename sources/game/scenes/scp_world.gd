extends Node

@export var global_time_to_sync_positions := 1.0
@export var global_time_to_sync_enemy_movement := 0.1
@export var global_time_to_sync_server_control := 1.0

func _ready() -> void:
	SgGlobalReferences.set_reference("World", self)
	TranslationServer.set_locale("en_US")
	
	SgGlobalReferences.get_reference("Transitions").start_anim("anim_transition_out")

func get_global_time_to_sync_enemy_movement() -> float:
	return global_time_to_sync_enemy_movement

func get_global_time_to_sync_server_control() -> float:
	return global_time_to_sync_server_control
	
func get_global_time_to_sync_positions() -> float:
	return global_time_to_sync_positions
