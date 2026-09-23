class_name TrashStation
extends Area2D

@export var order_registry_path: NodePath
@export var raw_order_rack_path: NodePath

@onready var _highlight: CanvasItem = $Highlight

var _order_registry: OrderRegistry = null
var _raw_order_rack: RawOrderRack = null


func _ready() -> void:
	_order_registry = get_node_or_null(order_registry_path) as OrderRegistry
	_raw_order_rack = get_node_or_null(raw_order_rack_path) as RawOrderRack


func can_interact(player_carry: PlayerCarry) -> bool:
	if (
		player_carry == null
		or not player_carry.has_item()
		or _order_registry == null
		or _raw_order_rack == null
		or not _raw_order_rack.has_capacity()
	):
		return false

	var held_item := player_carry.get_held_item()
	if not held_item is OrderBowl:
		return false
	var bowl := held_item as OrderBowl
	return (
		not bowl.order_id.is_empty()
		and bowl.food_state != null
		and _order_registry.has_order(bowl.order_id)
	)


func interact(player_carry: PlayerCarry) -> bool:
	if not can_interact(player_carry):
		return false

	var bowl := player_carry.get_held_item() as OrderBowl
	var order := _order_registry.get_order(bowl.order_id)
	if order == null or not player_carry.discard_held_item(bowl):
		return false
	if _raw_order_rack.enqueue_order(order) == null:
		push_error("Trash reissue invariant broken")
		return false
	return true


func set_highlighted(is_highlighted: bool) -> void:
	_highlight.visible = is_highlighted
