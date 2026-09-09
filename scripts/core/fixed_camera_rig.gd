@tool
class_name FixedCameraRig
extends Node3D

@export_category("Fixed Camera")
@export var target: Vector3 = Vector3.ZERO:
	set(value):
		target = value
		_update_camera()
@export_range(-180.0, 180.0, 0.5) var yaw: float = 0.0:
	set(value):
		yaw = value
		_update_camera()
@export_range(-89.0, -1.0, 0.5) var pitch: float = -55.0:
	set(value):
		pitch = value
		_update_camera()
@export_range(1.0, 100.0, 0.5, "or_greater") var distance: float = 18.0:
	set(value):
		distance = value
		_update_camera()
@export_range(1.0, 100.0, 0.5, "or_greater") var orthographic_size: float = 18.0:
	set(value):
		orthographic_size = value
		_update_camera()


func _ready() -> void:
	_update_camera()


func _update_camera() -> void:
	var camera := get_node_or_null("Camera3D") as Camera3D
	if camera == null or not is_inside_tree():
		return

	position = target
	rotation = Vector3.ZERO

	var yaw_radians := deg_to_rad(yaw)
	var pitch_radians := deg_to_rad(pitch)
	var horizontal_distance := cos(pitch_radians) * distance
	var offset := Vector3(
		sin(yaw_radians) * horizontal_distance,
		-sin(pitch_radians) * distance,
		cos(yaw_radians) * horizontal_distance
	)

	camera.position = offset
	camera.look_at(target, Vector3.UP)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = orthographic_size
	camera.current = true
