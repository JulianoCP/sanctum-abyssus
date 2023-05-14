extends Control

var entity_id := 0
var current_value := 0

func set_status_data(data) -> void:
	if data.has("steam_id"):
		entity_id = data["steam_id"]
	if data.has("steam_name"):
		self.get_node("PlayerName").set_text(data["steam_name"])
	if data.has("max_life"):
		self.get_node("ProgressBar").set_max(int(data["max_life"]))
		self.get_node("ProgressBar").set_value(int(data["max_life"]))
		current_value = int(data["max_life"])
	self.get_node("Animation").play("anim_show")

func get_entity_id() -> int:
	return entity_id

func decrease_health(damage) -> void:
	current_value -= damage
	self.get_node("ProgressBar").set_value(current_value)
	
	if current_value <= 0:
		self.get_node("Animation").play("anim_hide")

func set_status(value) -> void:
	current_value = int(value)
	self.get_node("ProgressBar").set_value(value)
	
	if current_value <= 0 && self.is_visible():
		self.get_node("Animation").play("anim_hide")
