class_name FoodState
extends RefCounted

var order_id: StringName = &""
var base_food_present: bool = true
var staple_id: StringName = &""


func _init(
	p_order_id: StringName,
	p_base_food_present: bool = true,
	p_staple_id: StringName = &""
) -> void:
	order_id = p_order_id
	base_food_present = p_base_food_present
	staple_id = p_staple_id


func is_valid() -> bool:
	return not order_id.is_empty()


func has_base_food() -> bool:
	return base_food_present


func has_staple() -> bool:
	return not staple_id.is_empty()


func can_add_staple(new_staple_id: StringName) -> bool:
	return is_valid() and not new_staple_id.is_empty() and not has_staple()


func try_add_staple(new_staple_id: StringName) -> bool:
	if not can_add_staple(new_staple_id):
		return false

	staple_id = new_staple_id
	return true


func is_empty() -> bool:
	return not has_base_food() and not has_staple()
