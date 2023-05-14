extends Node

var steam_info := {}

func _ready() -> void:
	SgGlobalReferences.set_reference("SteamManager", self)
	
	if not is_steam_enabled():
		return
	
	var init = Steam.steamInit()
	SgGlobalReferences.get_reference("DebugLogger").debug_logger("Steam status: " + str(init))
	
	if init['status'] != 1:
		SgGlobalReferences.get_reference("DebugLogger").debug_logger("Failed to initialize Steam. " + str(init['verbal']) + " Shutting down...")
		get_tree().quit()
	
	steam_info["steam_id"] = Steam.getSteamID()
	steam_info["is_online"] = Steam.loggedOn()
	steam_info["steam_name"] = Steam.getPersonaName()
	steam_info["is_game_owned"] = Steam.isSubscribed()
	
	if steam_info["is_game_owned"] == false:
		SgGlobalReferences.get_reference("DebugLogger").debug_logger("User does not own this game")
		get_tree().quit()

func get_steam_info(key : String):
	if steam_info.has(key):
		return steam_info[key]
	else: 
		return null

func get_my_steam_id() -> int:
	if steam_info.has("steam_id"):
		return steam_info["steam_id"]
	return 0

func get_my_steam_name() -> String:
	if steam_info.has("steam_name"):
		return steam_info["steam_name"]
	return "Unknown"

func _process(_delta) -> void:
	Steam.run_callbacks()

func get_profile_name() -> String:
	return Steam.getPersonaName()

func is_steam_enabled() -> bool:
	return OS.has_feature("steam") or OS.is_debug_build()
