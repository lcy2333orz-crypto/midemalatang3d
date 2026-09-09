class_name PlayerInteractor
extends Node

@export_range(-1.0, 1.0, 0.05) var facing_dot_threshold: float = -0.25
@export_range(0.0, 200.0, 1.0) var facing_score_weight: float = 36.0

@onready var _player: CharacterBody2D = get_parent() as CharacterBody2D
@onready var _player_carry: PlayerCarry = get_parent().get_node("PlayerCarry") as PlayerCarry
@onready var _interaction_area: Area2D = get_parent().get_node("InteractionArea") as Area2D

var _candidates: Dictionary = {}
var _current_target: Area2D = null


func _ready() -> void:
	_interaction_area.area_entered.connect(_on_interaction_area_entered)
	_interaction_area.area_exited.connect(_on_interaction_area_exited)


func _physics_process(_delta: float) -> void:
	_prune_candidates()
	_update_current_target()


func request_interact() -> void:
	_prune_candidates()
	_update_current_target()

	if _current_target != null:
		_current_target.call(&"interact", _player_carry)
	elif _player_carry.has_item() and not _has_blocking_candidate_in_front():
		var player_facing: Vector2 = _player.facing
		var drop_position: Vector2 = _player.global_position + player_facing * _player_carry.drop_distance
		_player_carry.drop_to_world(drop_position)

	call_deferred(&"_refresh_after_interaction")


func _on_interaction_area_entered(area: Area2D) -> void:
	if _is_generic_interaction_target(area):
		_candidates[area.get_instance_id()] = area


func _on_interaction_area_exited(area: Area2D) -> void:
	_candidates.erase(area.get_instance_id())
	if area == _current_target:
		_set_current_target(null)


func _update_current_target() -> void:
	var best_target: Area2D = null
	var best_score: float = INF
	var best_distance: float = INF
	var best_facing_dot: float = -INF
	var best_instance_id: int = 0
	var player_facing: Vector2 = _player.facing

	for candidate_value: Variant in _candidates.values():
		var candidate := candidate_value as Area2D
		if candidate == null or not bool(candidate.call(&"can_interact", _player_carry)):
			continue

		var offset: Vector2 = candidate.global_position - _player.global_position
		var distance: float = offset.length()
		var facing_dot: float = 1.0 if distance <= 0.001 else player_facing.dot(offset / distance)
		if facing_dot < facing_dot_threshold:
			continue

		var score: float = distance + (1.0 - facing_dot) * facing_score_weight
		var instance_id: int = candidate.get_instance_id()
		var is_better: bool = score < best_score - 0.001
		if is_equal_approx(score, best_score):
			is_better = distance < best_distance - 0.001
			if is_equal_approx(distance, best_distance):
				is_better = facing_dot > best_facing_dot + 0.001
				if is_equal_approx(facing_dot, best_facing_dot):
					is_better = best_target == null or instance_id < best_instance_id

		if is_better:
			best_target = candidate
			best_score = score
			best_distance = distance
			best_facing_dot = facing_dot
			best_instance_id = instance_id

	_set_current_target(best_target)


func _has_blocking_candidate_in_front() -> bool:
	var player_facing: Vector2 = _player.facing
	for candidate_value: Variant in _candidates.values():
		var candidate := candidate_value as Area2D
		if candidate == null:
			continue
		var offset: Vector2 = candidate.global_position - _player.global_position
		var distance: float = offset.length()
		var facing_dot: float = 1.0 if distance <= 0.001 else player_facing.dot(offset / distance)
		if facing_dot >= facing_dot_threshold:
			return true
	return false


func _set_current_target(target: Area2D) -> void:
	if target == _current_target:
		return
	if _current_target != null and is_instance_valid(_current_target):
		_current_target.call(&"set_highlighted", false)
	_current_target = target
	if _current_target != null:
		_current_target.call(&"set_highlighted", true)


func _prune_candidates() -> void:
	for instance_id: Variant in _candidates.keys():
		var candidate := _candidates[instance_id] as Area2D
		if candidate == null or not is_instance_valid(candidate):
			_candidates.erase(instance_id)


func _is_generic_interaction_target(area: Area2D) -> bool:
	return (
		area != null
		and area.has_method(&"can_interact")
		and area.has_method(&"interact")
		and area.has_method(&"set_highlighted")
	)


func _refresh_after_interaction() -> void:
	_prune_candidates()
	_update_current_target()
