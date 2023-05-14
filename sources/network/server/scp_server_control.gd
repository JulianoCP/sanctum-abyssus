extends Node

var last_latency_time := 0
var current_latency := 0

func _ready() -> void:
	SgGlobalReferences.set_reference("ServerControl", self)
	
	if self.get_node("ControlTimer").connect("timeout", Callable(self, "_server_control")) != OK : pass

func start_timers() -> void:
	self.get_node("ControlTimer").start(SgGlobalReferences.get_reference("World").get_global_time_to_sync_server_control())

func stop_timers() -> void:
	self.get_node("ControlTimer").stop()

func _server_control() -> void:
	SgGlobalReferences.get_reference("ServerConnection").send_package_to_multicast(
		{
			"destined_node" : "ServerControl",
			"method" : "remote_verify_latency",
			"data" : {}
		}
	)

func rpc_calculate_latency(data : Dictionary) -> void:
	SgGlobalReferences.get_reference("ServerConnection").send_package_to_client(
		data["steam_id"],
		{
			"destined_node" : "ServerControl",
			"method" : "remote_calculate_latency",
			"data" : {}
		}
	)

func remote_verify_latency(_data : Dictionary) -> void:
	last_latency_time = SgGlobalUtils.get_time_msecs()
	SgGlobalReferences.get_reference("ServerConnection").send_package_to_server(
		{
			"destined_node" : "ServerControl",
			"method" : "rpc_calculate_latency",
			"data" : {
				"steam_id" : SgGlobalReferences.get_reference("SteamManager").get_my_steam_id()
			}
		}
	)

func remote_calculate_latency(_data : Dictionary) -> void:
	current_latency = int(abs(SgGlobalUtils.get_time_msecs() - last_latency_time))
	SgGlobalReferences.get_reference("DebugLogger").update_latency(current_latency)

func get_current_latency() -> int:
	return current_latency
