extends Node

func _ready() -> void:
	SgGlobalReferences.set_reference("Steam", self)
