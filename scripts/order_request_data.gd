class_name OrderRequestData
extends RefCounted

var request_id: StringName = &""
var required_staple_id: StringName = &""


func _init(p_request_id: StringName, p_required_staple_id: StringName) -> void:
	request_id = p_request_id
	required_staple_id = p_required_staple_id


func is_valid() -> bool:
	return not request_id.is_empty()
