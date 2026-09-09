class_name LocalPlayerInput
extends Node

@export_category("Player Assignment")
@export_range(0, 3, 1) var local_slot: int = 0
@export var input_device_id: int = -1

@export_category("Movement Input")
@export_range(0.0, 1.0, 0.01) var deadzone: float = 0.25
@export var move_left_action: StringName = &"gameplay_move_left"
@export var move_right_action: StringName = &"gameplay_move_right"
@export var move_up_action: StringName = &"gameplay_move_up"
@export var move_down_action: StringName = &"gameplay_move_down"

@onready var _player_controller: PlayerController = get_parent() as PlayerController


func _ready() -> void:
	process_physics_priority = -100


func _physics_process(_delta: float) -> void:
	var input_vector := Input.get_vector(
		move_left_action,
		move_right_action,
		move_up_action,
		move_down_action,
		deadzone
	)
	_player_controller.set_move_intent(_to_camera_relative_direction(input_vector))


func _to_camera_relative_direction(input_vector: Vector2) -> Vector3:
	if input_vector.is_zero_approx():
		return Vector3.ZERO

	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return Vector3.ZERO

	var camera_forward := -camera.global_transform.basis.z
	camera_forward.y = 0.0
	camera_forward = camera_forward.normalized()

	var camera_right := camera.global_transform.basis.x
	camera_right.y = 0.0
	camera_right = camera_right.normalized()

	var world_direction := camera_right * input_vector.x
	world_direction += camera_forward * -input_vector.y
	return world_direction.limit_length(1.0)
