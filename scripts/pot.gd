class_name Pot
extends Carryable

var order_id: StringName = &""
var food_state: FoodState = null


func _ready() -> void:
	_refresh_visuals()


func can_receive_food_state(state: FoodState) -> bool:
	return (
		state != null
		and state.is_valid()
		and food_state == null
		and (order_id.is_empty() or order_id == state.order_id)
	)


func receive_food_state(state: FoodState) -> bool:
	if not can_receive_food_state(state):
		return false

	if order_id.is_empty():
		order_id = state.order_id
	food_state = state
	_refresh_visuals()
	return true


func can_receive_from_bowl(bowl: OrderBowl) -> bool:
	return (
		current_holder == null
		and current_surface == null
		and bowl != null
		and not bowl.order_id.is_empty()
		and bowl.food_state != null
		and bowl.food_state.is_valid()
		and bowl.food_state.order_id == bowl.order_id
		and can_receive_food_state(bowl.food_state)
	)


func receive_from_bowl(bowl: OrderBowl) -> bool:
	if not can_receive_from_bowl(bowl):
		return false

	var original_food := bowl.food_state
	var previous_pot_order_id := order_id
	var previous_pot_food := food_state
	var taken_food := bowl.take_food_state()
	if taken_food != original_food:
		if bowl.food_state != original_food and not bowl.receive_food_state(original_food):
			push_error("Pot transfer invariant broken: unexpected Bowl take result could not be restored")
		return false

	if receive_food_state(taken_food):
		return true

	order_id = previous_pot_order_id
	food_state = previous_pot_food
	_refresh_visuals()
	if not bowl.receive_food_state(taken_food):
		push_error("Pot transfer rollback failed: FoodState could not be restored to its OrderBowl")
	return false


func can_transfer_to_bowl(bowl: OrderBowl) -> bool:
	return (
		current_holder == null
		and current_surface == null
		and food_state != null
		and not order_id.is_empty()
		and food_state.order_id == order_id
		and food_state.is_cooked_or_beyond()
		and bowl != null
		and not bowl.order_id.is_empty()
		and bowl.food_state == null
		and bowl.order_id == order_id
	)


func transfer_to_bowl(bowl: OrderBowl) -> bool:
	var state := food_state
	if not can_transfer_to_bowl(bowl):
		return false
	if not bowl.receive_food_state(state):
		return false

	food_state = null
	order_id = &""
	_refresh_visuals()
	return true


func can_interact(player_carry: PlayerCarry) -> bool:
	if player_carry == null:
		return false
	if not player_carry.has_item():
		return super.can_interact(player_carry)

	var held_item := player_carry.get_held_item()
	if not held_item is OrderBowl:
		return false
	var held_bowl := held_item as OrderBowl
	if held_bowl.food_state != null:
		return can_receive_from_bowl(held_bowl)
	return can_transfer_to_bowl(held_bowl)


func interact(player_carry: PlayerCarry) -> bool:
	if not can_interact(player_carry):
		return false
	if player_carry.has_item():
		var held_bowl := player_carry.get_held_item() as OrderBowl
		if held_bowl.food_state != null:
			return receive_from_bowl(held_bowl)
		return transfer_to_bowl(held_bowl)
	return super.interact(player_carry)


func _refresh_visuals() -> void:
	var pot_visual := get_node_or_null("PotVisual") as CanvasItem
	var food_visual := get_node_or_null("FoodVisual") as CanvasItem
	if pot_visual != null:
		pot_visual.visible = true
	if food_visual != null:
		food_visual.visible = food_state != null and not food_state.is_empty()
