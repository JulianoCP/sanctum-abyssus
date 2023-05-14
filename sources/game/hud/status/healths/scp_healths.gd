extends Node

@onready var pref_health_status := load("res://prefabs/game/hud/status/health/pref_player_health_status.tscn")

func _ready() -> void:
	SgGlobalReferences.set_reference("Healths", self)

func create_player_health_status(data) -> void:
	var inst_health_status = pref_health_status.instantiate()
	inst_health_status.set_status_data(data)
	
	self.get_node("HealthContainer/VHealths").add_child(inst_health_status)

func update_health_status(entity_id, damage) -> void:
	for health in self.get_node("HealthContainer/VHealths").get_children():
		if health.get_entity_id() == entity_id:
			health.decrease_health(damage)

func restore_to_defaul() -> void:
	for health in self.get_node("HealthContainer/VHealths").get_children():
		health.queue_free()

func update_status(data) -> void:
	for health in self.get_node("HealthContainer/VHealths").get_children():
		if health.get_entity_id() == data["steam_id"]:
			health.set_status(data["player_health"])
