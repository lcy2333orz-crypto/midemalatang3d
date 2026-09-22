class_name StoveStation
extends PlacementSurface

@export var is_powered: bool = true
@export_range(0.0, 10.0, 0.1) var heat_rate_per_second: float = 0.5


func can_interact(player_carry: PlayerCarry) -> bool:
	if player_carry != null and player_carry.has_item():
		return player_carry.get_held_item() is Pot and super.can_interact(player_carry)
	return super.can_interact(player_carry)


func place_item(item: Carryable) -> bool:
	if not item is Pot:
		return false
	return super.place_item(item)


func _physics_process(delta: float) -> void:
	if not is_powered or heat_rate_per_second <= 0.0 or not occupied_item is Pot:
		return

	var pot := occupied_item as Pot
	if pot.food_state != null:
		pot.food_state.add_heat(delta * heat_rate_per_second)
