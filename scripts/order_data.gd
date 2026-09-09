class_name OrderData
extends RefCounted

var order_id: StringName = &""
var required_staple_id: StringName = &""


func _init(p_order_id: StringName, p_required_staple_id: StringName) -> void:
	if p_order_id.is_empty():
		return

	order_id = p_order_id
	required_staple_id = p_required_staple_id


func is_valid() -> bool:
	return not order_id.is_empty()
