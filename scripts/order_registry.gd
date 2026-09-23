class_name OrderRegistry
extends Node

var _orders_by_id: Dictionary = {}
var _accepted_request_ids: Dictionary = {}
var _next_order_number: int = 1


func can_accept_request(request: OrderRequestData) -> bool:
	return (
		request != null
		and request.is_valid()
		and not has_accepted_request(request.request_id)
	)


func accept_request(request: OrderRequestData) -> OrderData:
	if not can_accept_request(request):
		return null

	var order_id := StringName("order_%04d" % _next_order_number)
	var order := OrderData.new(order_id, request.required_staple_id, request.request_id)
	_orders_by_id[order_id] = order
	_accepted_request_ids[request.request_id] = true
	_next_order_number += 1
	return order


func has_order(order_id: StringName) -> bool:
	return _orders_by_id.has(order_id)


func get_order(order_id: StringName) -> OrderData:
	return _orders_by_id.get(order_id) as OrderData


func has_accepted_request(request_id: StringName) -> bool:
	return _accepted_request_ids.has(request_id)


func get_active_order_count() -> int:
	return _orders_by_id.size()
