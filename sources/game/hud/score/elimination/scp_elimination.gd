extends Control

@onready var enemy_count_label : RichTextLabel = self.get_node("EnemyCount/EnemyCountLabel")
@onready var animation_label : AnimationPlayer = self.get_node("EnemyCount/AnimationLabel")

var current_score := 0
var score_per_client := {}

func _ready() -> void:
	SgGlobalReferences.set_reference("Elimination", self)

func increase_score(emitter_id) -> void:
	current_score += 1
	
	if score_per_client.has(emitter_id):
		score_per_client[emitter_id] += 1
	else:
		score_per_client[emitter_id] = 1
	
	animation_label.play("anim_enemy_count_label")
	enemy_count_label.set_text("[right][shake rate=10.0 level=5]" + str(current_score) + "x[/shake][/right]")

func get_per_scores() -> Dictionary:
	return score_per_client

func restore_to_defaul() -> void:
	score_per_client.clear()
	current_score = 0
	
	enemy_count_label.set_text("[right][shake rate=10.0 level=5]" + str(current_score) + "x[/shake][/right]")
