class_name PlayerController
extends CharacterBody3D

@export_category("Movement")
@export_range(0.0, 20.0, 0.1, "or_greater") var move_speed: float = 5.5
@export_range(0.0, 100.0, 0.5, "or_greater") var acceleration: float = 26.0
@export_range(0.0, 100.0, 0.5, "or_greater") var deceleration: float = 34.0
@export_range(0.0, 1440.0, 1.0, "or_greater") var turn_speed_degrees: float = 720.0

@onready var _visual_root: Node3D = %VisualRoot
@onready var _gravity: float = float(
	ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
)

var _move_intent: Vector3 = Vector3.ZERO


func set_move_intent(world_direction: Vector3) -> void:
	var planar_direction := Vector3(world_direction.x, 0.0, world_direction.z)
	_move_intent = planar_direction.limit_length(1.0)


func _physics_process(delta: float) -> void:
	_apply_horizontal_movement(delta)
	_apply_gravity(delta)
	_update_facing(delta)
	move_and_slide()


func _apply_horizontal_movement(delta: float) -> void:
	var horizontal_velocity := Vector2(velocity.x, velocity.z)
	var target_velocity := Vector2(_move_intent.x, _move_intent.z) * move_speed
	var change_rate := acceleration if not _move_intent.is_zero_approx() else deceleration
	horizontal_velocity = horizontal_velocity.move_toward(target_velocity, change_rate * delta)
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.y


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		if velocity.y < 0.0:
			velocity.y = 0.0
		return

	velocity.y -= _gravity * delta


func _update_facing(delta: float) -> void:
	if _move_intent.is_zero_approx():
		return

	var target_yaw := atan2(-_move_intent.x, -_move_intent.z)
	var turn_step := deg_to_rad(turn_speed_degrees) * delta
	_visual_root.rotation.y = rotate_toward(_visual_root.rotation.y, target_yaw, turn_step)
