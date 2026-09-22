class_name FoodState
extends RefCounted

enum CookingState {
	RAW,
	COOKING,
	COOKED,
	OVERCOOKING,
	BURNT,
}

var order_id: StringName = &""
var base_food_present: bool = true
var staple_id: StringName = &""
var heat_progress: float = 0.0
var cooking_state: CookingState = CookingState.RAW
var condiment_ids: Array[StringName] = []


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


func can_receive_heat() -> bool:
	return is_valid() and not is_empty() and cooking_state != CookingState.BURNT


func add_heat(amount: float) -> bool:
	if amount <= 0.0 or not can_receive_heat():
		return false

	heat_progress = clampf(heat_progress + amount, 0.0, 3.0)
	_refresh_cooking_state()
	return true


func is_cooked_or_beyond() -> bool:
	return cooking_state >= CookingState.COOKED


func has_condiment(condiment_id: StringName) -> bool:
	return condiment_id in condiment_ids


func can_add_condiment(condiment_id: StringName) -> bool:
	return (
		is_valid()
		and not is_empty()
		and is_cooked_or_beyond()
		and not condiment_id.is_empty()
		and not has_condiment(condiment_id)
	)


func try_add_condiment(condiment_id: StringName) -> bool:
	if not can_add_condiment(condiment_id):
		return false

	condiment_ids.append(condiment_id)
	return true


func _refresh_cooking_state() -> void:
	if heat_progress >= 3.0:
		cooking_state = CookingState.BURNT
	elif heat_progress >= 2.0:
		cooking_state = CookingState.OVERCOOKING
	elif heat_progress >= 1.0:
		cooking_state = CookingState.COOKED
	elif heat_progress > 0.0:
		cooking_state = CookingState.COOKING
	else:
		cooking_state = CookingState.RAW
