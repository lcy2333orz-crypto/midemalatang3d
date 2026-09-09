class_name Carryable
extends Area2D

const INTERACTABLE_LAYER := 1 << 2

@onready var _highlight: CanvasItem = $Highlight

var current_holder: PlayerCarry = null
var current_surface: PlacementSurface = null


func can_interact(player_carry: PlayerCarry) -> bool:
	return (
		player_carry != null
		and not player_carry.has_item()
		and current_holder == null
		and current_surface == null
	)


func interact(player_carry: PlayerCarry) -> bool:
	if not can_interact(player_carry):
		return false
	return player_carry.pickup(self)


func set_highlighted(is_highlighted: bool) -> void:
	_highlight.visible = is_highlighted


func _set_held_state(holder: PlayerCarry, hold_anchor: Marker2D) -> bool:
	if holder == null or hold_anchor == null or current_holder != null:
		return false

	if current_surface != null and not current_surface.release_item(self):
		return false

	current_holder = holder
	current_surface = null
	_set_interaction_enabled(false)
	reparent(hold_anchor, false)
	position = Vector2.ZERO
	return true


func _set_placed_state(surface: PlacementSurface, item_anchor: Marker2D) -> bool:
	if surface == null or item_anchor == null or current_holder == null or current_surface != null:
		return false

	current_holder = null
	current_surface = surface
	_set_interaction_enabled(false)
	reparent(item_anchor, false)
	position = Vector2.ZERO
	return true


func _set_ground_state(world_parent: Node, world_position: Vector2) -> bool:
	if world_parent == null or current_holder == null:
		return false

	current_holder = null
	current_surface = null
	reparent(world_parent, false)
	global_position = world_position
	_set_interaction_enabled(true)
	return true


func _set_interaction_enabled(is_enabled: bool) -> void:
	collision_layer = INTERACTABLE_LAYER if is_enabled else 0
	collision_mask = 0
	monitoring = false
	monitorable = is_enabled
	if not is_enabled:
		set_highlighted(false)
