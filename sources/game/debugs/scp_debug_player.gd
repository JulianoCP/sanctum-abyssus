extends Node2D

@export var enable_position_debug := false
@export var enable_id_debug := false

func _ready():
	if enable_position_debug:
		self.get_node("Position").show()
		self.get_node("Position/PositionTimer").start()
	if enable_position_debug:
		self.get_node("ID").show()
		self.get_node("ID/IDTimer").start()

func _on_position_timer_timeout():
	self.get_node("Position").set_text(str(self.get_parent().get_position().round()))

func _on_id_timer_timeout():
	self.get_node("ID").set_text(str(self.get_parent().ENTITY_ID))
