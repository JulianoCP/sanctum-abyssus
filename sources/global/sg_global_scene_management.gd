extends Node

signal SceneChanged

#Loading thread with new scene.
func th_load_scene(scene_path : String) -> void:
	ResourceLoader.load_threaded_request(scene_path)
	
	var scene_progress : Array = []
	var resource_interactive_status = ResourceLoader.THREAD_LOAD_IN_PROGRESS
	
	while resource_interactive_status != ResourceLoader.THREAD_LOAD_LOADED:
		resource_interactive_status = ResourceLoader.load_threaded_get_status(scene_path, scene_progress)
	
	self.call_deferred("th_done", scene_path)

#Result after thread done.
func th_done(scene_path : String) -> void:
	SgGlobalReferences.get_reference("SceneManager").add_child(ResourceLoader.load_threaded_get(scene_path).instantiate())
	emit_signal("SceneChanged")

#Start thread to change scene.
func change_scene(scene_path : String) -> void:
	if scene_path != "":
		if SgGlobalReferences.get_reference("SceneManager").get_current_scene() != null:
			SgGlobalReferences.get_reference("SceneManager").get_current_scene().queue_free()
		self.th_load_scene(scene_path)
	else:
		SgGlobalReferences.get_reference("DebugLogger").debug_logger("Scene Path is empty or null")
