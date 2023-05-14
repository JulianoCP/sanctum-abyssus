extends Marker2D

@export var hide_in_game := true
@export var try_to_adjust_before_spawning := true

@export var spawn_variation := 15.0

func _ready():
	if hide_in_game:
		self.hide()

func get_possible_position_to_spawn() -> Vector2:
	randomize()
	return (self.get_position() + Vector2(randf_range(spawn_variation * (-1), spawn_variation), randf_range(spawn_variation * (-1), spawn_variation))).round()
