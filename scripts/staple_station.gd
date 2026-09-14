class_name StapleStation
extends Area2D

@export var staple_id: StringName = &""

@onready var _highlight: CanvasItem = $Highlight


func can_interact(player_carry: PlayerCarry) -> bool:
	if staple_id.is_empty() or player_carry == null or not player_carry.has_item():
		return false

	var held_item := player_carry.get_held_item()
	if not held_item is OrderBowl:
		return false

	var bowl := held_item as OrderBowl
	return bowl.can_add_staple(staple_id)


func interact(player_carry: PlayerCarry) -> bool:
	if not can_interact(player_carry):
		return false

	var bowl := player_carry.get_held_item() as OrderBowl
	if bowl == null:
		return false
	return bowl.add_staple(staple_id)


func set_highlighted(is_highlighted: bool) -> void:
	_highlight.visible = is_highlighted
