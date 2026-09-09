class_name PlacementSurface
extends Area2D

@onready var _highlight: CanvasItem = $Highlight
@onready var _item_anchor: Marker2D = $ItemAnchor

var occupied_item: Carryable = null


func can_interact(player_carry: PlayerCarry) -> bool:
	if player_carry == null:
		return false

	_validate_occupied_item()
	if player_carry.has_item():
		return occupied_item == null and player_carry.get_held_item() is Carryable
	return occupied_item != null


func interact(player_carry: PlayerCarry) -> bool:
	if not can_interact(player_carry):
		return false

	if player_carry.has_item():
		return player_carry.place_on(self)
	return player_carry.pickup(occupied_item)


func place_item(item: Carryable) -> bool:
	_validate_occupied_item()
	if occupied_item != null or item == null:
		return false
	if not item._set_placed_state(self, _item_anchor):
		return false

	occupied_item = item
	return true


func release_item(item: Carryable) -> bool:
	_validate_occupied_item()
	if item == null or occupied_item != item:
		return false

	occupied_item = null
	return true


func set_highlighted(is_highlighted: bool) -> void:
	_highlight.visible = is_highlighted


func _validate_occupied_item() -> void:
	if occupied_item != null and not is_instance_valid(occupied_item):
		occupied_item = null
