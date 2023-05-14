extends Node2D

#func _ready() -> void:
#	self.set_physics_process(false)
#
#func _enable_physics_process() -> void:
#	self.set_physics_process(true)
#
#func _disable_physics_process() -> void:
#	self.set_physics_process(false)
#
#func _physics_process(_delta):
#	if self.get_parent().is_possible_sync():
#		SgGlobalReferences.get_reference("ServerConnection").udp_method_on_multicast(
#				"receive_enemy_movement_on_multicast",
#				[current_enemy_id, enemy_next_path_point.x, enemy_next_path_point.y, self.get_parent().get_target_id()], 
#				SgGlobalEnums.CHANNELS.CHANNEL_4
#			)
