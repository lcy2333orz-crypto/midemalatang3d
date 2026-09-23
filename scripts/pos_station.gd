class_name POSStation
extends Area2D

@export var order_registry_path: NodePath
@export var raw_order_rack_path: NodePath

@onready var _highlight: CanvasItem = $Highlight

var pending_request: OrderRequestData = null
var _order_registry: OrderRegistry = null
var _raw_order_rack: RawOrderRack = null


func _ready() -> void:
	_order_registry = get_node_or_null(order_registry_path) as OrderRegistry
	_raw_order_rack = get_node_or_null(raw_order_rack_path) as RawOrderRack


func has_pending_request() -> bool:
	return pending_request != null


func set_pending_request(request: OrderRequestData) -> bool:
	if has_pending_request() or request == null or not request.is_valid():
		return false
	pending_request = request
	return true


func clear_pending_request() -> void:
	pending_request = null


func can_accept_pending_request() -> bool:
	return (
		pending_request != null
		and pending_request.is_valid()
		and _order_registry != null
		and _raw_order_rack != null
		and _order_registry.can_accept_request(pending_request)
		and _raw_order_rack.has_capacity()
	)


func accept_pending_request() -> OrderData:
	if not can_accept_pending_request():
		return null

	var order := _order_registry.accept_request(pending_request)
	if order == null:
		return null
	if _raw_order_rack.enqueue_order(order) == null:
		push_error("POS accept invariant broken")
		return null

	pending_request = null
	return order


func can_interact(player_carry: PlayerCarry) -> bool:
	return player_carry != null and not player_carry.has_item() and can_accept_pending_request()


func interact(player_carry: PlayerCarry) -> bool:
	if not can_interact(player_carry):
		return false
	return accept_pending_request() != null


func set_highlighted(is_highlighted: bool) -> void:
	_highlight.visible = is_highlighted
