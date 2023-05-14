extends Node
class_name cBASE_MAP

@export var path_to_instances_node : NodePath = ""

func get_instances_node() -> Object:
	return get_node(path_to_instances_node)
