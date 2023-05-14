extends Node2D

@onready var pref_enemy_blood : Object = preload("res://prefabs/game/entities/bloods/enemies/pref_enemy_blood.tscn")

func _ready() -> void:
	SgGlobalReferences.set_reference("DecalBloods", self)

func spawn_blood(location) -> void:
	var inst_blood : Object = pref_enemy_blood.instantiate()
	inst_blood.set_position(location)
	
	self.call_deferred("add_child", inst_blood)
