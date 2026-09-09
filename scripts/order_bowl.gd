class_name OrderBowl
extends Carryable

var order_id: StringName = &""
var food_state: FoodState = null


func _ready() -> void:
	_refresh_visuals()


func bind_to_order(order: OrderData) -> bool:
	if order == null or not order.is_valid():
		return false

	if not order_id.is_empty():
		return order_id == order.order_id

	order_id = order.order_id
	food_state = FoodState.new(order_id, true, &"")
	_refresh_visuals()
	return true


func take_food_state() -> FoodState:
	if food_state == null:
		return null

	var taken_state := food_state
	food_state = null
	_refresh_visuals()
	return taken_state


func can_receive_food_state(state: FoodState) -> bool:
	return (
		not order_id.is_empty()
		and food_state == null
		and state != null
		and state.is_valid()
		and state.order_id == order_id
	)


func receive_food_state(state: FoodState) -> bool:
	if not can_receive_food_state(state):
		return false

	food_state = state
	_refresh_visuals()
	return true


func _refresh_visuals() -> void:
	var bowl_visual := get_node_or_null("BowlVisual") as CanvasItem
	var food_visual := get_node_or_null("FoodVisual") as CanvasItem
	if bowl_visual != null:
		bowl_visual.visible = true
	if food_visual != null:
		food_visual.visible = food_state != null and not food_state.is_empty()
