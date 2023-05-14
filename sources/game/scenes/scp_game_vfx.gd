extends Node

@export var enable_vhs_fx : bool = true

func _ready():
	if enable_vhs_fx:
		self.get_node("VHS_FX").show()

