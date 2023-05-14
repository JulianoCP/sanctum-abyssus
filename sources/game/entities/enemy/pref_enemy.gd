extends cBASE_CHARACTER

@export var enemy_max_life := 50
@export var enemy_speed := 60

@onready var navigation_agent : NavigationAgent2D = self.get_node("NavigationAgent")
@onready var animation_body: AnimationPlayer = self.get_node("Body/AnimationStates")
@onready var animation_fx: AnimationPlayer = self.get_node("Body/AnimationFX")

var current_path_point := Vector2.ZERO
var v_server_position := Vector2.ZERO
var distance_to_attack_player := 8.0
var old_path_point := Vector2.ZERO
var target_id := 0

func _ready() -> void:
	self.set_physics_process(false)
	
	SPEED = enemy_speed
	MAX_LIFE = enemy_max_life
	CURRENT_LIFE = MAX_LIFE
	
	if SgGlobalReferences.get_reference("SteamLobby").is_owner():
		if self.get_node("NavigationAgent/SyncTargetPosition").connect("timeout", Callable(self, "_sync_target_position_timer")) != OK : pass
		self.get_node("NavigationAgent/SyncTargetPosition").start()
		
		if SgGlobalReferences.get_reference("CharactersControl") != null && SgGlobalReferences.get_reference("CharactersControl")._get_character_reference(target_id) != null:
			navigation_agent.set_target_position(SgGlobalReferences.get_reference("CharactersControl")._get_character_reference(target_id).get_global_position())
		else:
			SgGlobalReferences.get_reference("DebugLogger").debug_logger("CharactersControl N/A")
			self.queue_free()
	
	# Try hits player
	self.get_node("DetectPlayer").start_timers()

func _sync_target_position_timer() -> void:
	if ALIVE && SgGlobalReferences.get_reference("CharactersControl")._get_character_reference(target_id) != null:
		navigation_agent.set_target_position(SgGlobalReferences.get_reference("CharactersControl")._get_character_reference(target_id).get_global_position())
	else:
		self.get_node("NavigationAgent/SyncTargetPosition").stop()

func _sync_navigation_path() -> void:
	if navigation_agent.is_navigation_finished():
		current_path_point = Vector2.ZERO
	else:
		current_path_point = navigation_agent.get_next_path_position().round()

func is_alive() -> bool:
	return ALIVE

func get_target_id() -> int:
	return target_id

func set_target_id(value) -> void:
	target_id = value

func get_distance_to_attack_player() -> float:
	return distance_to_attack_player

func remote_sync_enemy_movement(data) -> void:
	v_server_position = data

func set_enemy_props(data : Array) -> void:
	if data.size() >= 4:
		ENTITY_ID = data[1]
		target_id = data[4]
		self.set_position(Vector2(data[2], data[3]))
	else:
		SgGlobalReferences.get_reference("DebugLogger").debug_logger("Enemy props < 4 - FREE ENEMY")
		self.queue_free()

func get_distance_to_target() -> float:
	if SgGlobalReferences.get_reference("CharactersControl")._get_character_reference(target_id) != null:
		return self.get_position().distance_to(SgGlobalReferences.get_reference("CharactersControl")._get_character_reference(target_id).get_position())
	return 100.0

func get_target() -> Object:
	return SgGlobalReferences.get_reference("CharactersControl")._get_character_reference(target_id)

func _physics_process(_delta):
	if ALIVE:
		if SgGlobalReferences.get_reference("SteamLobby").is_owner():
			if old_path_point.distance_to(current_path_point) <= 1.0:
				if navigation_agent.is_navigation_finished():
					current_path_point = Vector2.ZERO
				else:
					current_path_point = navigation_agent.get_next_path_position().round()
				old_path_point = current_path_point
			
			if current_path_point != Vector2.ZERO:
				if self.get_distance_to_target() > distance_to_attack_player:
					velocity = (current_path_point - self.get_position().round()).normalized() * SPEED
					self.move_and_slide()
				
			SgGlobalReferences.get_reference("ServerConnection").udp_method_on_multicast(
				"receive_enemy_movement_on_multicast",
				[ENTITY_ID, position.x, position.y, target_id], 
				SgGlobalEnums.CHANNELS.CHANNEL_4
			)
		else:
			if v_server_position != Vector2.ZERO:
				if self.get_position().distance_to(v_server_position) >= 3.0 && self.get_distance_to_target() > distance_to_attack_player:
					velocity = (v_server_position - self.get_position().round()).normalized() * SPEED
					self.move_and_slide()

func _on_take_damage(damage, emitter_id) -> void:
	if ALIVE:
		CURRENT_LIFE -= damage
		animation_fx.play("anim_enemy_hit")
		
		#Check if its died.
		if CURRENT_LIFE <= 0:
			ALIVE = false
			self._on_death(emitter_id)

func _on_death(emitter_id) -> void:
	animation_body.play("anim_enemy_death")
	SgGlobalReferences.get_reference("Elimination").increase_score(emitter_id)
	SgGlobalReferences.get_reference("DecalBloods").spawn_blood(self.get_position())
	
	self.get_node("DetectHit").disable_detection()
	self.set_process(false)

func _on_spawn() -> void:
	self.get_node("DetectHit").enable_detection()
	self.set_physics_process(true)

func _after_death() -> void:
	if SgGlobalReferences.get_reference("SteamLobby").is_owner():
		SgGlobalReferences.get_reference("WavesControl")._notify_enemy_death(ENTITY_ID)
