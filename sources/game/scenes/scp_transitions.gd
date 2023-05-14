extends Node

signal anim_finished
var in_transition := false

func _ready() -> void:
	SgGlobalReferences.set_reference("Transitions", self)

func is_in_transition() -> bool:
	return in_transition

func signal_anim_finished() -> void:
	self.emit_signal("anim_finished")

func start_anim(anim_name : String) -> void:
	self.get_node("TransitionsAnimation").play(anim_name)
	in_transition = true

func _on_transitions_animation_animation_finished(_anim_name):
	in_transition = false
	self.signal_anim_finished()
