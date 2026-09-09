extends CharacterBody2D

@export_range(1.0, 1000.0, 1.0, "or_greater") var move_speed: float = 240.0
@export_range(1.0, 10000.0, 1.0, "or_greater") var acceleration: float = 2400.0
@export_range(1.0, 10000.0, 1.0, "or_greater") var deceleration: float = 3000.0

@onready var _facing_marker: Polygon2D = $VisualRoot/FacingMarker

var facing: Vector2 = Vector2.DOWN
var _move_intent: Vector2 = Vector2.ZERO


func set_move_intent(direction: Vector2) -> void:
	_move_intent = direction.limit_length(1.0)


func _physics_process(delta: float) -> void:
	if _move_intent.is_zero_approx():
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
	else:
		var target_velocity := _move_intent * move_speed
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
		_update_facing(_move_intent)

	move_and_slide()


func _update_facing(direction: Vector2) -> void:
	if absf(direction.x) > absf(direction.y):
		facing = Vector2.RIGHT if direction.x > 0.0 else Vector2.LEFT
	else:
		facing = Vector2.DOWN if direction.y > 0.0 else Vector2.UP

	match facing:
		Vector2.UP:
			_facing_marker.position = Vector2(0.0, -48.0)
		Vector2.DOWN:
			_facing_marker.position = Vector2(0.0, 5.0)
		Vector2.LEFT:
			_facing_marker.position = Vector2(-23.0, -22.0)
		Vector2.RIGHT:
			_facing_marker.position = Vector2(23.0, -22.0)
