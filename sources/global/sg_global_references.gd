extends Node

var global_references = {} # Dictionary with references.

# Set reference in dictionary.
func set_reference(node_name : String, node_reference : Object) -> void:
	global_references[node_name] = node_reference

# Get reference in dictionary.
func get_reference(node_name : String) -> Object:
	if global_references.has(node_name) and global_references[node_name] != null:
		return global_references[node_name]
	return null

# Has reference in dictionary.
func has_reference(node_name : String) -> bool:
	if global_references.has(node_name) and global_references[node_name] != null:
		return true
	return false
