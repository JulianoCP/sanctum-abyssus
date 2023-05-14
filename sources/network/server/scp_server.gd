extends Node

var _server_info : Dictionary = {}

func _enter_tree():
	SgGlobalReferences.set_reference("Server", self)

func has_key_on_server_info(key : String) -> bool:
	if _server_info.has(key):
		return true
	return false

func set_server_info(key : String, value) -> void:
	_server_info[key] = value

func get_server_info(key):
	if _server_info.has(key):
		return _server_info[key]
	return null

func has_internal_node(node_name : String) -> bool:
	return self.has_node(node_name)

func get_internal_node(node_name : String) -> Object:
	if self.has_node(node_name):
		return self.get_node(node_name)
	return null
