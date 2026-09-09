class_name PlayerCarry
extends Node

const WORLD_COLLISION_MASK := 1 << 0

@export_range(1.0, 200.0, 1.0) var drop_distance: float = 48.0
@export var drop_query_size := Vector2(32.0, 32.0)
@export var drop_query_offset := Vector2(0.0, -16.0)
@export_range(0.0, 100.0, 1.0) var minimum_drop_distance: float = 28.0

@onready var _player: CharacterBody2D = get_parent() as CharacterBody2D
@onready var _hold_anchor: Marker2D = get_parent().get_node("HoldAnchor") as Marker2D
@onready var _visual_root: Node2D = get_parent().get_node("VisualRoot") as Node2D

var _held_item: Carryable = null


func _ready() -> void:
	_update_hold_anchor()


func _physics_process(_delta: float) -> void:
	_update_hold_anchor()


func has_item() -> bool:
	_validate_held_item()
	return _held_item != null


func get_held_item() -> Carryable:
	_validate_held_item()
	return _held_item


func pickup(item: Carryable) -> bool:
	_validate_held_item()
	if _held_item != null or item == null:
		return false
	if not item._set_held_state(self, _hold_anchor):
		return false

	_held_item = item
	return true


func place_on(surface: PlacementSurface) -> bool:
	_validate_held_item()
	if _held_item == null or surface == null:
		return false

	var item := _held_item
	if not surface.place_item(item):
		return false

	_held_item = null
	return true


func drop_to_world(world_position: Vector2) -> bool:
	_validate_held_item()
	if _held_item == null or not _is_drop_position_legal(world_position):
		return false

	var world_parent := _player.get_parent()
	if world_parent == null:
		return false

	var item := _held_item
	if not item._set_ground_state(world_parent, world_position):
		return false

	_held_item = null
	return true


func _is_drop_position_legal(world_position: Vector2) -> bool:
	if not _player.is_inside_tree():
		return false
	if world_position.distance_to(_player.global_position) < minimum_drop_distance:
		return false

	var query_shape := RectangleShape2D.new()
	query_shape.size = drop_query_size

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = query_shape
	query.transform = Transform2D(0.0, world_position + drop_query_offset)
	query.collision_mask = WORLD_COLLISION_MASK
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.exclude = [_player.get_rid()]

	var hits := _player.get_world_2d().direct_space_state.intersect_shape(query, 16)
	return hits.is_empty()


func _update_hold_anchor() -> void:
	_hold_anchor.z_index = 0
	match _player.facing:
		Vector2.UP:
			_hold_anchor.position = Vector2(0.0, -38.0)
			_move_hold_anchor_before_visual()
		Vector2.DOWN:
			_hold_anchor.position = Vector2(0.0, 8.0)
			_move_hold_anchor_after_visual()
		Vector2.LEFT:
			_hold_anchor.position = Vector2(-24.0, -12.0)
			_move_hold_anchor_after_visual()
		Vector2.RIGHT:
			_hold_anchor.position = Vector2(24.0, -12.0)
			_move_hold_anchor_after_visual()


func _move_hold_anchor_before_visual() -> void:
	if _hold_anchor.get_index() > _visual_root.get_index():
		_player.move_child(_hold_anchor, _visual_root.get_index())


func _move_hold_anchor_after_visual() -> void:
	if _hold_anchor.get_index() < _visual_root.get_index():
		_player.move_child(_hold_anchor, _visual_root.get_index())


func _validate_held_item() -> void:
	if _held_item != null and not is_instance_valid(_held_item):
		_held_item = null
