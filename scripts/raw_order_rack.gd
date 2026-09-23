class_name RawOrderRack
extends Area2D

const MAX_SLOTS := 4

@export var order_bowl_scene: PackedScene

@onready var _highlight: CanvasItem = $Highlight
@onready var _slots: Array[Marker2D] = [$Slot0, $Slot1, $Slot2, $Slot3]

var _slot_items: Array[OrderBowl] = [null, null, null, null]


func has_capacity() -> bool:
	return _slot_items.has(null)


func get_occupied_count() -> int:
	return MAX_SLOTS - _slot_items.count(null)


func enqueue_order(order: OrderData) -> OrderBowl:
	if (
		order == null
		or not order.is_valid()
		or not has_capacity()
		or order_bowl_scene == null
		or _slots.size() != MAX_SLOTS
	):
		return null

	var instance := order_bowl_scene.instantiate()
	if not instance is OrderBowl:
		instance.free()
		return null
	var bowl := instance as OrderBowl
	if not bowl.bind_to_order(order):
		bowl.free()
		return null

	for slot_index in MAX_SLOTS:
		if _slot_items[slot_index] != null:
			continue
		_slots[slot_index].add_child(bowl)
		bowl.position = Vector2.ZERO
		bowl._set_interaction_enabled(false)
		_slot_items[slot_index] = bowl
		return bowl

	bowl.free()
	return null


func can_interact(player_carry: PlayerCarry) -> bool:
	return player_carry != null and not player_carry.has_item() and get_occupied_count() > 0


func interact(player_carry: PlayerCarry) -> bool:
	if not can_interact(player_carry):
		return false

	for slot_index in MAX_SLOTS:
		var bowl := _slot_items[slot_index]
		if bowl == null:
			continue
		if not player_carry.pickup(bowl):
			return false
		_slot_items[slot_index] = null
		return true
	return false


func set_highlighted(is_highlighted: bool) -> void:
	_highlight.visible = is_highlighted
