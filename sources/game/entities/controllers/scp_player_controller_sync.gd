extends Node2D

@onready var aim := self.get_node("../Body/BodySheet/Aim")
@onready var body_sheet := self.get_node("../Body/BodySheet")
@onready var point := self.get_node("../Body/BodySheet/Aim/Point")
@onready var aim_pivot := self.get_node("../Body/BodySheet/Aim/Pivot")
@onready var aim_pivot_location := self.get_node("../Body/BodySheet/Aim/Pivot/Location")

var aim_pivot_position := Vector2i.ZERO
var parent_position := Vector2i.ZERO
var aim_position := Vector2i.ZERO
var move_state := 0
var distance := 0.0

func _ready() -> void:
	self.set_physics_process(false)

func _enable_physics_process() -> void:
	self.set_physics_process(true)

func _disable_physics_process() -> void:
	self.set_physics_process(false)

func _physics_process(_delta) -> void:
	if self.get_parent().is_possible_sync():
		body_sheet.look_at(get_global_mouse_position())
		
		distance = (get_parent().get_position().distance_to(get_global_mouse_position()))
		
		aim.set_target_position(Vector2(distance, 0))
		aim_pivot.set_target_position(Vector2(16, 0))
		
		aim_pivot_location.set_position(aim_pivot.get_target_position().round())
		aim_pivot_position = aim_pivot_location.get_global_position()
		point.set_position(aim.get_target_position().round())
		
		# Bitwise
		if Input.is_action_pressed("move_left_action"):
			move_state |= (1 << 0)
		if Input.is_action_pressed("move_right_action"):
			move_state |= (1 << 1)
		if Input.is_action_pressed("move_up_action"):
			move_state |= (1 << 2)
		if Input.is_action_pressed("move_down_action"):
			move_state |= (1 << 3)
		if Input.is_action_pressed("shoot"):
			move_state |= (1 << 4)
		
		# Send inputs
		# [ MOVE STATE : 0 - LEFT INPUT | 1 - RIGHT INPUT | 2 - UP INPUT | 3 - DOWN INPUT ] 1 AIM POS_X 2 - AIM_POS_Y 3 - Aim Angle
		SgGlobalReferences.get_reference("ServerConnection").udp_method_on_server("receive_movement_on_server", [move_state, aim_pivot_position.x, aim_pivot_position.y, body_sheet.get_rotation_degrees()], SgGlobalEnums.CHANNELS.CHANNEL_1)
		
		# Restore inputs
		move_state = 0
