extends Node

@onready var pref_enemy_01 := load("res://prefabs/game/entities/enemy/pref_enemy_01.tscn")
@onready var pref_enemy_02 := load("res://prefabs/game/entities/enemy/pref_enemy_02.tscn")
@onready var pref_enemy_03 := load("res://prefabs/game/entities/enemy/pref_enemy_03.tscn")

@export var path_from_enemies_container : NodePath = ""
@export var path_from_enemies_spawns : NodePath = ""
@export var time_left_to_spawn_enemies := 0.2
@export var time_left_to_start_waves := 3
@export var max_enemies := 60

var enemy_chances := [0, 0, 0, 0, 0, 2, 2, 2, 2, 1]
var current_enemy_index := 0
var spawns_nodes := []
var enemies := {}

func _ready() -> void:
	SgGlobalReferences.set_reference("WavesControl", self)
	
	if SgGlobalReferences.get_reference("SteamLobby").is_owner():
		for spawn in self.get_node(path_from_enemies_spawns).get_children():
			spawns_nodes.append(spawn)
		
		if self.get_node("TimeLeftToStart").connect("timeout", Callable(self, "_on_time_out_to_start_waves")) != OK: pass
		if self.get_node("SpawnEnemies").connect("timeout", Callable(self, "_on_time_out_to_spawn_enemies")) != OK: pass
		
		self.get_node("TimeLeftToStart").start(time_left_to_start_waves)

func _on_time_out_to_start_waves() -> void:
		self.get_node("SpawnEnemies").start(time_left_to_spawn_enemies)

func _on_time_out_to_spawn_enemies() -> void:
	if SgGlobalReferences.get_reference("SteamLobby").is_owner() && current_enemy_index < max_enemies && SgGlobalReferences.get_reference("CharactersControl").get_have_alive_players():
		enemies[current_enemy_index] = {
			"enemy_id" : current_enemy_index,
			"enemy_type" : enemy_chances[randi() % enemy_chances.size()],
			"enemy_position" : spawns_nodes[randi() % spawns_nodes.size()].get_possible_position_to_spawn(),
			"enemy_target_id" : SgGlobalReferences.get_reference("CharactersControl")._get_random_character_target()
		}
		
		SgGlobalReferences.get_reference("ServerConnection").tcp_method_on_multicast(
			"receive_spawn_enemy_on_multicast", 
			[current_enemy_index, enemies[current_enemy_index]["enemy_position"].x, enemies[current_enemy_index]["enemy_position"].y, enemies[current_enemy_index]["enemy_target_id"], enemies[current_enemy_index]["enemy_type"]], 
			SgGlobalEnums.CHANNELS.CHANNEL_3
		)
		
		# ID For next enemy.
		current_enemy_index += 1
	else:
		self.get_node("SpawnEnemies").stop()

func _notify_enemy_death(enemy_id : int) -> void:
	if enemies.has(enemy_id):
		self._respawn_enemy(enemy_id)
	else:
		SgGlobalReferences.get_reference("DebugLogger").debug_logger("Enemy ID N/A")

func notify_player_death(peer_id) -> void:
	if SgGlobalReferences.get_reference("CharactersControl").get_have_alive_players():
		for enemy_id in enemies:
			if enemies[enemy_id].has("enemy_target_id") && enemies[enemy_id]["enemy_target_id"] == peer_id && enemies[enemy_id].has("enemy_reference") && is_instance_valid(enemies[enemy_id]["enemy_reference"]):
				enemies[enemy_id]["enemy_reference"].set_target_id(SgGlobalReferences.get_reference("CharactersControl")._get_random_character_target())

func _respawn_enemy(enemy_id : int) -> void:
	if enemies.has(enemy_id) && SgGlobalReferences.get_reference("CharactersControl").get_have_alive_players():
		enemies[enemy_id]["enemy_type"] = enemy_chances[randi() % enemy_chances.size()]
		enemies[enemy_id]["enemy_position"] = spawns_nodes[randi() % spawns_nodes.size()].get_possible_position_to_spawn()
		enemies[enemy_id]["enemy_target_id"] = SgGlobalReferences.get_reference("CharactersControl")._get_random_character_target()
		
		SgGlobalReferences.get_reference("ServerConnection").tcp_method_on_multicast(
			"receive_spawn_enemy_on_multicast", 
			[enemy_id, enemies[enemy_id]["enemy_position"].x, enemies[enemy_id]["enemy_position"].y, enemies[enemy_id]["enemy_target_id"], enemies[enemy_id]["enemy_type"]], 
			SgGlobalEnums.CHANNELS.CHANNEL_3
		)

func remote_spawn_enemy(data) -> void:
	if SgGlobalReferences.get_reference("CharactersControl").get_have_alive_players():
		var inst_enemy : Object = null
		
		if data[5] == 1:
			inst_enemy = pref_enemy_02.instantiate()
		elif data[5] == 2:
			inst_enemy = pref_enemy_03.instantiate()
		else:
			inst_enemy = pref_enemy_01.instantiate()
			
		inst_enemy.set_enemy_props(data)
		
		if enemies.has(data[1]):
			if enemies[data[1]].has("enemy_reference") && is_instance_valid(enemies[data[1]]["enemy_reference"]):
				enemies[data[1]]["enemy_reference"].queue_free()
			enemies[data[1]]["enemy_reference"] = inst_enemy
		else:
			enemies[data[1]] = {
				"enemy_reference" : inst_enemy
			}
		
		self.get_node(path_from_enemies_container).call_deferred("add_child", inst_enemy)

func remote_sync_enemy_movement(data) -> void:
	if enemies.has(data[1]):
		if is_instance_valid(enemies[data[1]]["enemy_reference"]):
			enemies[data[1]]["enemy_reference"].set_target_id(data[4])
			enemies[data[1]]["enemy_reference"].remote_sync_enemy_movement(Vector2(data[2], data[3]))
