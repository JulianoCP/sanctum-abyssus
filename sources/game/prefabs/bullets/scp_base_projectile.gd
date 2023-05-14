extends Area2D
class_name cBASE_PROJECTILE

@export var damage := 10.0
@export var life_span := 3
@export var bullet_speed := 4.0

func _physics_process(_delta):
	self.position += transform.x * bullet_speed
