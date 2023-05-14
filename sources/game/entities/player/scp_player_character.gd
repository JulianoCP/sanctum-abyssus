extends cBASE_CHARACTER

@onready var player_cam := self.get_node("Camera")
@onready var aim := self.get_node("Body/BodySheet/Aim")
@onready var body_sheet := self.get_node("Body/BodySheet")
@onready var anim_fx := self.get_node("Body/BodySheet/AnimationFx")
@onready var anim_flares := self.get_node("Body/BodySheet/AnimFlares")
@onready var anim_states := self.get_node("Body/BodySheet/AnimationStates")

@export var path_player_name : NodePath = ""

var pref_projectile := preload("res://prefabs/game/bullets/pref_projectile_001.tscn")
var sync_movement_is_enabled := false
var direction_vector := Vector2.ZERO

var player_character_info := {
	"steam_id" : 0,
	"steam_name" : "",
	"is_owner" : false
}

############################################################
################### | NETWORK--CONTEXT | ###################
############################################################

var v_server_position := Vector2.ZERO
var b_shot_available := true
var is_correcting := false

func get_is_correcting() -> bool:
	return is_correcting

func notify_player_was_created() -> void:
	if SgGlobalReferences.get_reference("SteamLobby").is_owner():
		SgGlobalReferences.get_reference("ServerEntities")._notify_spawn_character(player_character_info["steam_id"], self.get_position())

func remote_sync_character_movement(data : Array) -> void:
	if data.size() >= 7: 
		var move_data : Vector2 = Vector2.ZERO
		
		if (bool(1 & (data[2] >> 0))):
			move_data.x += -1
		if (bool(1 & (data[2] >> 1))):
			move_data.x += 1
		if (bool(1 & (data[2] >> 2))):
			move_data.y += -1
		if (bool(1 & (data[2] >> 3))):
			move_data.y += 1
		if (bool(1 & (data[2] >> 4))):
			if b_shot_available:
				self.server_shot(data[3], data[4], data[5], player_character_info["steam_name"])
		
		# Sync player position
		v_server_position = Vector2(data[6], data[7])
		
		# Sync player inputs
		direction_vector = move_data
		
		# Sync player Rotation
		self.remote_sync_player_rotation(data[5])

func _process(_delta) -> void:
	if ALIVE && sync_movement_is_enabled && v_server_position != Vector2.ZERO:
		if (self.get_position().distance_to(v_server_position) >= 12.0) || (is_correcting):
			is_correcting = true
			
			velocity = (v_server_position - self.get_position()).normalized() * (SPEED * 3)
			self.move_and_slide()
			
			if self.get_position().distance_to(v_server_position) <= 6.0:
				is_correcting = false

func server_shot(start_pos_x, start_pos_y, start_angle, peer_id) -> void:
	if SgGlobalReferences.get_reference("SteamLobby").is_owner():
		b_shot_available = false
	
		var inst_projectile = pref_projectile.instantiate()
		inst_projectile.set_position(Vector2i(start_pos_x, start_pos_y))
		inst_projectile.set_rotation_degrees(start_angle)
		inst_projectile.set_client_emitter(peer_id)
		
		if SgGlobalReferences.get_reference("SanctumMap").get_instances_node() != null:
			SgGlobalReferences.get_reference("SanctumMap").get_instances_node().add_child(inst_projectile)
		
		#Notify clients
		anim_flares.play(("anim_flare_0" + str(randi() % 3)))
		
		SgGlobalReferences.get_reference("ServerConnection").udp_method_on_multicast(
			"receive_shot_from_server", 
			[player_character_info["steam_id"], start_pos_x, start_pos_y, start_angle], 
			SgGlobalEnums.CHANNELS.CHANNEL_2
		)

func remote_shot_from_server(data) -> void:
	if !is_locally_controlled():
		body_sheet.set_rotation_degrees(data[4])
		
	if !SgGlobalReferences.get_reference("SteamLobby").is_owner():
		var inst_projectile = pref_projectile.instantiate()
		inst_projectile.set_position(Vector2i(data[2], data[3]))
		anim_flares.play(("anim_flare_0" + str(randi() % 3)))
		inst_projectile.set_rotation_degrees(data[4])
		
		if SgGlobalReferences.get_reference("SanctumMap").get_instances_node() != null:
			SgGlobalReferences.get_reference("SanctumMap").get_instances_node().add_child(inst_projectile)

func remote_sync_player_rotation(data) -> void:
	if !is_locally_controlled():
		body_sheet.set_rotation_degrees(data)

##############################################################
#################### | LOCALLY--CONTEXT | ####################
##############################################################

func _ready() -> void:
	self.get_node(path_player_name).set_text(player_character_info["steam_name"])
	self.set_process(false)
	
	SPEED = 120
	MAX_LIFE = 250
	CURRENT_LIFE = MAX_LIFE
	
	#IF Server
	if SgGlobalReferences.get_reference("SteamLobby").is_owner():
		self.get_node("PlayerControllerSync/FireReloading").start()
		self.get_node("PlayerControllerSync/SyncPlayerStatus").start()
	else:
		self.set_process(true)
		
	#IF Client
	if player_character_info["steam_id"] == SgGlobalReferences.get_reference("SteamManager").get_my_steam_id():
		self.enable_player_camera()
		self.set_player_character_info("is_owner", true)
		
		# Transition OUT
		player_cam.force_update_player_cam()
		SgGlobalReferences.get_reference("Transitions").start_anim("anim_transition_out")
		
		# Wait transitions
		await SgGlobalReferences.get_reference("Transitions").anim_finished
		SgGlobalReferences.get_reference("HUD").anim_show_hud()
	
	# Creating health status on HUD
	SgGlobalReferences.get_reference("Healths").create_player_health_status(
		{
			"steam_name" : player_character_info["steam_name"],
			"steam_id" : player_character_info["steam_id"],
			"max_life" : MAX_LIFE
		}
	)
	
	ENTITY_ID = player_character_info["steam_id"]
	anim_states.play("anim_player_spawn")

func enable_player_camera() -> void:
	player_cam.set_enabled(true)

func set_player_character_info(key : String, value) -> void:
	player_character_info[key] = value

func _enable_movement_sync() -> void:
	sync_movement_is_enabled = true
	
	if is_locally_controlled():
		self.get_node("PlayerControllerSync")._enable_physics_process()
		aim.show()

func _disable_movement_sync() -> void:
	sync_movement_is_enabled = false
	
	if is_locally_controlled():
		self.get_node("PlayerControllerSync")._disable_physics_process()
		aim.hide()

func get_movement_sync() -> bool:
	return sync_movement_is_enabled

func get_player_character_id() -> int:
	return player_character_info["steam_id"]

func is_possible_sync() -> bool:
	if self.is_locally_controlled() and !self.get_is_correcting() and ALIVE:
		return true
	return false

func is_locally_controlled() -> bool:
	return player_character_info["is_owner"]

func _on_take_damage(damage) -> void:
	if ALIVE:
		anim_fx.play("anim_player_hit")
		
		CURRENT_LIFE -= damage
		SgGlobalReferences.get_reference("Healths").update_health_status(ENTITY_ID, damage)
		
		#Check if its died.
		if CURRENT_LIFE <= 0:
			ALIVE = false
			self._locally_death()

func _locally_death() -> void:
	self.set_physics_process(false)
	self._disable_movement_sync()
	self.set_process(false)
	
	if SgGlobalReferences.get_reference("SteamLobby").is_owner():
		self._notify_player_death()

func _notify_player_death() -> void:
	SgGlobalReferences.get_reference("ServerConnection").send_package_to_multicast(
		{
			"destined_node" : "ServerEntities",
			"method" : "_notify_player_death",
			"data" : {
				"steam_id" : ENTITY_ID
			}
		}
	)

func remote_on_death() -> void:
	anim_states.play("anim_player_death")
	
	if SgGlobalReferences.get_reference("SteamLobby").is_owner():
		SgGlobalReferences.get_reference("ServerConnection").send_package_to_multicast(
				{
					"destined_node" : "ServerEntities",
					"method" : "_notify_player_status",
					"data" : {
						"steam_id" : ENTITY_ID,
						"player_health" : 0
					}
				}
			)

func _after_death() -> void:
	if SgGlobalReferences.get_reference("SteamLobby").is_owner():
		SgGlobalReferences.get_reference("CharactersControl").set_player_death(ENTITY_ID)
	if is_locally_controlled():
		if SgGlobalReferences.get_reference("CharactersControl").try_spectate():
			player_cam.set_enabled(false)

func is_alive() -> bool:
	return ALIVE

func _physics_process(_delta) -> void:
	if ALIVE:
		if direction_vector.x || direction_vector.y:
			velocity.x = direction_vector.x * SPEED
			velocity.y = direction_vector.y * SPEED
			velocity.round()
		else:
			velocity = Vector2.ZERO
		self.move_and_slide()

func _on_fire_reloading_timeout():
	b_shot_available = true

func _on_sync_player_status_timeout():
	if ALIVE:
		SgGlobalReferences.get_reference("ServerConnection").send_package_to_multicast(
			{
				"destined_node" : "ServerEntities",
				"method" : "_notify_player_status",
				"data" : {
					"steam_id" : ENTITY_ID,
					"player_health" : CURRENT_LIFE
				}
			}
		)
