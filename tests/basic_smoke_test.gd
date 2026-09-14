extends SceneTree

const SCENE_PATHS := [
	"res://scenes/main.tscn",
	"res://scenes/movement_test.tscn",
	"res://scenes/player.tscn",
	"res://scenes/test_carryable.tscn",
	"res://scenes/test_counter.tscn",
	"res://scenes/order_bowl.tscn",
	"res://scenes/staple_station.tscn",
	"res://scenes/pot.tscn",
]
const MOVEMENT_ACTIONS := [
	&"gameplay_move_up",
	&"gameplay_move_down",
	&"gameplay_move_left",
	&"gameplay_move_right",
]

var _failures: Array[String] = []


class RejectingOrderBowl:
	extends OrderBowl

	func can_add_staple(_staple_id_to_add: StringName) -> bool:
		return true

	func add_staple(_staple_id_to_add: StringName) -> bool:
		return false


class RejectingReceivePot:
	extends Pot

	func receive_food_state(_state: FoodState) -> bool:
		return false


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	for scene_path in SCENE_PATHS:
		_check_scene_loads(scene_path)

	_check_player_root()
	_check_player_interaction_nodes()
	_check_camera()
	_check_world_draw_order_structure()
	_check_input_actions()
	_check_interaction_contracts()
	_check_carry_state_transitions()
	_check_order_and_food_data()
	_check_food_staple_rules()
	_check_order_bowl_business_rules()
	_check_order_bowl_staple_rules()
	_check_order_bowl_carry_integration()
	_check_staple_station_business_rules()
	_check_pot_business_rules()
	_check_pot_interaction_and_carry()
	_check_localization()

	if _failures.is_empty():
		print("BASIC SMOKE TEST PASSED")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)


func _check_scene_loads(scene_path: String) -> void:
	var packed_scene := load(scene_path) as PackedScene
	if packed_scene == null:
		_failures.append("Scene failed to load: %s" % scene_path)
		return
	var instance := packed_scene.instantiate()
	if instance == null:
		_failures.append("Scene failed to instantiate: %s" % scene_path)
		return
	instance.free()


func _check_player_root() -> void:
	var packed_scene := load("res://scenes/player.tscn") as PackedScene
	if packed_scene == null:
		return
	var player := packed_scene.instantiate()
	if not player is CharacterBody2D:
		_failures.append("Player root must be CharacterBody2D")
	player.free()


func _check_player_interaction_nodes() -> void:
	var packed_scene := load("res://scenes/player.tscn") as PackedScene
	if packed_scene == null:
		return
	var player := packed_scene.instantiate()
	if not player.get_node_or_null("HoldAnchor") is Marker2D:
		_failures.append("Player must contain HoldAnchor Marker2D")
	if not player.get_node_or_null("InteractionArea") is Area2D:
		_failures.append("Player must contain InteractionArea Area2D")
	if not player.get_node_or_null("PlayerCarry") is PlayerCarry:
		_failures.append("Player must contain PlayerCarry")
	if not player.get_node_or_null("PlayerInteractor") is PlayerInteractor:
		_failures.append("Player must contain PlayerInteractor")
	var hold_anchor := player.get_node("HoldAnchor") as Marker2D
	var visual_root := player.get_node("VisualRoot") as Node2D
	if hold_anchor.z_index != 0:
		_failures.append("HoldAnchor must remain at world z_index 0")
	if hold_anchor.get_index() <= visual_root.get_index():
		_failures.append("Initial DOWN HoldAnchor must draw after VisualRoot")
	player.free()


func _check_camera() -> void:
	var packed_scene := load("res://scenes/movement_test.tscn") as PackedScene
	if packed_scene == null:
		return
	var movement_test := packed_scene.instantiate()
	var camera := movement_test.get_node_or_null("Camera2D")
	if not camera is Camera2D:
		_failures.append("MovementTest/Camera2D must be Camera2D")
	elif not is_zero_approx(camera.rotation):
		_failures.append("Camera2D rotation must be 0")
	movement_test.free()


func _check_world_draw_order_structure() -> void:
	var packed_scene := load("res://scenes/movement_test.tscn") as PackedScene
	if packed_scene == null:
		return
	var movement_test := packed_scene.instantiate()
	var y_sort_world := movement_test.get_node("YSortWorld") as Node2D
	if not y_sort_world.y_sort_enabled:
		_failures.append("YSortWorld must keep y_sort_enabled")
	for node_name in [
		&"Player",
		&"TestCounterA",
		&"TestCounterB",
		&"TestCarryableA",
		&"TestCarryableB",
		&"OrderBowl",
		&"PotA",
		&"WideNoodleStation",
		&"InstantNoodleStation",
	]:
		var world_object := y_sort_world.get_node(NodePath(node_name)) as CanvasItem
		if world_object == null or world_object.get_parent() != y_sort_world:
			_failures.append("%s must be a direct YSortWorld child" % node_name)
		elif world_object.z_index != 0:
			_failures.append("%s must remain at world z_index 0" % node_name)
	movement_test.free()


func _check_input_actions() -> void:
	for action in MOVEMENT_ACTIONS:
		if not InputMap.has_action(action):
			_failures.append("Missing InputMap action: %s" % action)
	if not InputMap.has_action(&"gameplay_interact"):
		_failures.append("Missing InputMap action: gameplay_interact")


func _check_interaction_contracts() -> void:
	var carryable_scene := load("res://scenes/test_carryable.tscn") as PackedScene
	var counter_scene := load("res://scenes/test_counter.tscn") as PackedScene
	if carryable_scene == null or counter_scene == null:
		return

	var carryable := carryable_scene.instantiate() as Carryable
	var surface := counter_scene.instantiate() as PlacementSurface
	for method_name in [&"can_interact", &"interact"]:
		if not carryable.has_method(method_name):
			_failures.append("Carryable missing interaction method: %s" % method_name)
		if not surface.has_method(method_name):
			_failures.append("PlacementSurface missing interaction method: %s" % method_name)
	var carryable_highlight := carryable.get_node("Highlight") as Polygon2D
	var carryable_visual := carryable.get_node("Visual") as Polygon2D
	if carryable_highlight.z_index != 0:
		_failures.append("Carryable Highlight must remain at z_index 0")
	if carryable_highlight.get_index() >= carryable_visual.get_index():
		_failures.append("Carryable Highlight must draw before Visual by sibling order")
	var item_anchor := surface.get_node("ItemAnchor") as Marker2D
	var counter_highlight := surface.get_node("Highlight") as Polygon2D
	var counter_top := surface.get_node("CounterTop") as Polygon2D
	var counter_front := surface.get_node("CounterFront") as Polygon2D
	if surface.z_index != 0 or carryable.z_index != 0 or item_anchor.z_index != 0:
		_failures.append("Counter, Carryable, and ItemAnchor must remain at z_index 0")
	if counter_highlight.z_index != 0:
		_failures.append("Counter Highlight must remain at z_index 0")
	if (
		counter_highlight.get_index() >= counter_top.get_index()
		or counter_highlight.get_index() >= counter_front.get_index()
	):
		_failures.append("Counter Highlight must draw before Counter visuals by sibling order")
	if item_anchor.get_index() <= counter_front.get_index():
		_failures.append("ItemAnchor must draw after Counter visuals by sibling order")
	carryable.free()
	surface.free()


func _check_carry_state_transitions() -> void:
	var player_scene := load("res://scenes/player.tscn") as PackedScene
	var carryable_scene := load("res://scenes/test_carryable.tscn") as PackedScene
	var counter_scene := load("res://scenes/test_counter.tscn") as PackedScene
	if player_scene == null or carryable_scene == null or counter_scene == null:
		return

	var test_world := Node2D.new()
	get_root().add_child(test_world)
	var player := player_scene.instantiate()
	var second_player := player_scene.instantiate()
	second_player.name = "SecondPlayer"
	var item_a := carryable_scene.instantiate() as Carryable
	var item_b := carryable_scene.instantiate() as Carryable
	var surface := counter_scene.instantiate() as PlacementSurface
	test_world.add_child(player)
	test_world.add_child(second_player)
	test_world.add_child(item_a)
	test_world.add_child(item_b)
	test_world.add_child(surface)

	var player_carry := player.get_node("PlayerCarry") as PlayerCarry
	var second_player_carry := second_player.get_node("PlayerCarry") as PlayerCarry
	var hold_anchor := player.get_node("HoldAnchor") as Marker2D
	var visual_root := player.get_node("VisualRoot") as Node2D
	player.set("facing", Vector2.UP)
	player_carry.call("_physics_process", 0.0)
	if hold_anchor.z_index != 0 or hold_anchor.get_index() >= visual_root.get_index():
		_failures.append("UP held item must draw behind VisualRoot at local z_index 0")
	player.set("facing", Vector2.DOWN)
	player_carry.call("_physics_process", 0.0)
	if hold_anchor.z_index != 0 or hold_anchor.get_index() <= visual_root.get_index():
		_failures.append("DOWN held item must draw in front of VisualRoot at local z_index 0")

	if not player_carry.pickup(item_a):
		_failures.append("Pickup must succeed for an empty PlayerCarry")
	if player_carry.get_held_item() != item_a:
		_failures.append("Pickup must set held_item to item A")

	if player_carry.pickup(item_b):
		_failures.append("Double pickup must fail")
	if player_carry.get_held_item() != item_a:
		_failures.append("Failed double pickup must keep item A held")

	if not player_carry.place_on(surface):
		_failures.append("Place must succeed on an empty surface")
	if player_carry.has_item() or surface.occupied_item != item_a:
		_failures.append("Place must transfer item A to the surface")
	if item_a.get_parent() != surface.get_node("ItemAnchor") or item_a.z_index != 0:
		_failures.append("Placed item must remain in the Counter local z_index 0 unit")

	if not player_carry.pickup(item_b):
		_failures.append("Pickup of item B must succeed after placing item A")
	if player_carry.place_on(surface):
		_failures.append("Place must fail on an occupied surface")
	if surface.occupied_item != item_a or player_carry.get_held_item() != item_b:
		_failures.append("Occupied place failure must preserve both items")

	if not surface.interact(second_player_carry):
		_failures.append("Take must succeed for an empty PlayerCarry")
	if second_player_carry.get_held_item() != item_a or surface.occupied_item != null:
		_failures.append("Take must transfer item A from the surface")

	test_world.free()


func _check_order_and_food_data() -> void:
	var order := OrderData.new(&"order_test_001", &"wide_noodle")
	if not order.is_valid():
		_failures.append("OrderData with a non-empty order_id must be valid")
	if order.order_id != &"order_test_001":
		_failures.append("OrderData must preserve order_id")
	if order.required_staple_id != &"wide_noodle":
		_failures.append("OrderData must preserve required_staple_id")
	var order_value: Variant = order
	if order_value is Node:
		_failures.append("OrderData must not be a Node")

	var invalid_order := OrderData.new(&"", &"wide_noodle")
	if invalid_order.is_valid():
		_failures.append("OrderData with an empty order_id must be invalid")
	if invalid_order.order_id != &"" or invalid_order.required_staple_id != &"":
		_failures.append("Invalid OrderData must keep its fields empty")

	var raw_food := FoodState.new(&"order_test_001", true, &"")
	if not raw_food.is_valid() or not raw_food.has_base_food():
		_failures.append("Raw FoodState must be valid and contain base food")
	if raw_food.has_staple() or raw_food.is_empty():
		_failures.append("Raw FoodState must have no staple and must not be empty")

	var valid_empty_food := FoodState.new(&"order_test_001", false, &"")
	if not valid_empty_food.is_valid() or not valid_empty_food.is_empty():
		_failures.append("FoodState validity must be independent from empty contents")

	var invalid_food := FoodState.new(&"", false, &"")
	if invalid_food.is_valid():
		_failures.append("FoodState with an empty order_id must be invalid")


func _check_food_staple_rules() -> void:
	var food := FoodState.new(&"order_test_001", true, &"")
	if not food.can_add_staple(&"wide_noodle"):
		_failures.append("Valid FoodState without a staple must accept a non-empty staple ID")
	if not food.try_add_staple(&"wide_noodle"):
		_failures.append("FoodState must add its first valid staple")
	if food.staple_id != &"wide_noodle" or not food.has_staple():
		_failures.append("FoodState must record the actual added staple")

	if food.can_add_staple(&"instant_noodle") or food.try_add_staple(&"instant_noodle"):
		_failures.append("FoodState must reject a second staple")
	if food.staple_id != &"wide_noodle":
		_failures.append("Rejected second staple must preserve the original staple")

	var empty_id_food := FoodState.new(&"order_test_002", true, &"")
	if empty_id_food.can_add_staple(&"") or empty_id_food.try_add_staple(&""):
		_failures.append("FoodState must reject an empty staple ID")
	if empty_id_food.staple_id != &"":
		_failures.append("Rejected empty staple ID must not mutate FoodState")

	var invalid_food := FoodState.new(&"", true, &"")
	if invalid_food.can_add_staple(&"wide_noodle") or invalid_food.try_add_staple(&"wide_noodle"):
		_failures.append("Invalid FoodState must reject staple addition")
	if invalid_food.staple_id != &"":
		_failures.append("Rejected addition must not repair invalid FoodState")


func _check_order_bowl_business_rules() -> void:
	var bowl_scene := load("res://scenes/order_bowl.tscn") as PackedScene
	if bowl_scene == null:
		return

	var order := OrderData.new(&"order_test_001", &"wide_noodle")
	var other_order := OrderData.new(&"order_test_002", &"wide_noodle")
	var invalid_order := OrderData.new(&"", &"wide_noodle")
	var bowl := bowl_scene.instantiate() as OrderBowl
	if bowl == null:
		_failures.append("OrderBowl scene must instantiate as OrderBowl")
		return
	if not bowl is Carryable:
		_failures.append("OrderBowl must inherit Carryable")

	var highlight := bowl.get_node("Highlight") as Polygon2D
	var bowl_visual := bowl.get_node("BowlVisual") as Polygon2D
	var food_visual := bowl.get_node("FoodVisual") as Polygon2D
	if bowl.z_index != 0 or highlight.z_index != 0 or bowl_visual.z_index != 0 or food_visual.z_index != 0:
		_failures.append("OrderBowl and its visuals must remain at z_index 0")
	if highlight.get_index() >= bowl_visual.get_index() or bowl_visual.get_index() >= food_visual.get_index():
		_failures.append("OrderBowl visuals must use Highlight, BowlVisual, FoodVisual sibling order")
	if food_visual.visible:
		_failures.append("Unbound OrderBowl must hide FoodVisual")

	var bowl_script := bowl.get_script() as Script
	for method_data: Dictionary in bowl_script.get_script_method_list():
		var method_name := StringName(method_data.get("name", ""))
		if method_name == &"_process" or method_name == &"_physics_process":
			_failures.append("OrderBowl must not refresh visuals every frame")

	if bowl.bind_to_order(null):
		_failures.append("OrderBowl must reject a null OrderData")
	if bowl.bind_to_order(invalid_order):
		_failures.append("OrderBowl must reject invalid OrderData")
	if not bowl.bind_to_order(order):
		_failures.append("OrderBowl must bind a valid OrderData")

	var raw_food := bowl.food_state
	if bowl.order_id != order.order_id or raw_food == null:
		_failures.append("Binding must set order_id and create raw FoodState")
	elif (
		raw_food.order_id != order.order_id
		or not raw_food.base_food_present
		or raw_food.staple_id != &""
	):
		_failures.append("Bound OrderBowl must create the expected raw FoodState")
	if not food_visual.visible:
		_failures.append("Bound raw OrderBowl must show FoodVisual")

	if not bowl.bind_to_order(order) or bowl.food_state != raw_food:
		_failures.append("Same-order bind must be idempotent and preserve FoodState")
	if bowl.bind_to_order(other_order):
		_failures.append("OrderBowl must reject rebinding to another order")
	if bowl.order_id != order.order_id or bowl.food_state != raw_food:
		_failures.append("Failed rebind must preserve OrderBowl state")

	var taken_food := bowl.take_food_state()
	if taken_food != raw_food:
		_failures.append("take_food_state must return the same FoodState instance")
	if bowl.food_state != null or bowl.order_id != order.order_id:
		_failures.append("Empty OrderBowl must retain order_id")
	if food_visual.visible:
		_failures.append("Empty OrderBowl must hide FoodVisual")
	if not bowl.bind_to_order(order) or bowl.food_state != null:
		_failures.append("Same-order bind must not restore taken FoodState")

	var wrong_order_food := FoodState.new(other_order.order_id, true, &"")
	if bowl.can_receive_food_state(wrong_order_food) or bowl.receive_food_state(wrong_order_food):
		_failures.append("OrderBowl must reject FoodState from another order")
	if bowl.food_state != null:
		_failures.append("Wrong-order receive must keep OrderBowl empty")

	if not bowl.can_receive_food_state(taken_food) or not bowl.receive_food_state(taken_food):
		_failures.append("Empty OrderBowl must receive matching FoodState")
	if bowl.food_state != taken_food or not food_visual.visible:
		_failures.append("receive_food_state must preserve identity and refresh FoodVisual")

	var second_same_order_food := FoodState.new(order.order_id, true, &"")
	if bowl.can_receive_food_state(second_same_order_food) or bowl.receive_food_state(second_same_order_food):
		_failures.append("Occupied OrderBowl must reject a second FoodState")
	if bowl.food_state != taken_food:
		_failures.append("Occupied receive failure must preserve existing FoodState")

	bowl.free()
	if not order.is_valid() or order.order_id != &"order_test_001":
		_failures.append("Freeing a physical Bowl must not destroy OrderData")

	var replacement_bowl := bowl_scene.instantiate() as OrderBowl
	if not replacement_bowl.bind_to_order(order):
		_failures.append("Replacement Bowl must bind the surviving OrderData")
	elif (
		replacement_bowl.order_id != order.order_id
		or replacement_bowl.food_state == null
		or replacement_bowl.food_state == raw_food
	):
		_failures.append("Replacement Bowl must create a new raw FoodState for the same order")
	replacement_bowl.free()


func _check_order_bowl_staple_rules() -> void:
	var bowl_scene := load("res://scenes/order_bowl.tscn") as PackedScene
	if bowl_scene == null:
		return

	var order := OrderData.new(&"order_staple_test", &"wide_noodle")
	var bowl := bowl_scene.instantiate() as OrderBowl
	if bowl == null:
		_failures.append("OrderBowl staple test must instantiate OrderBowl")
		return
	var staple_visual := bowl.get_node("StapleVisual") as Polygon2D
	if not bowl.bind_to_order(order):
		_failures.append("OrderBowl staple test must bind a valid order")
	var original_food := bowl.food_state
	if original_food == null:
		_failures.append("Bound OrderBowl must contain FoodState before staple addition")
	elif original_food.has_staple() or staple_visual.visible:
		_failures.append("Newly bound OrderBowl must begin without a visible staple")
	elif not bowl.can_add_staple(&"wide_noodle") or not bowl.add_staple(&"wide_noodle"):
		_failures.append("OrderBowl must add the first staple through its business API")
	elif (
		bowl.food_state != original_food
		or bowl.food_state.staple_id != &"wide_noodle"
		or not staple_visual.visible
	):
		_failures.append("OrderBowl staple addition must preserve FoodState identity and refresh visuals")
	if bowl.add_staple(&"instant_noodle"):
		_failures.append("OrderBowl must reject replacing an existing staple")
	if bowl.food_state != original_food or bowl.food_state.staple_id != &"wide_noodle":
		_failures.append("Rejected replacement must preserve OrderBowl FoodState")
	bowl.free()

	var wrong_order := OrderData.new(&"order_wrong_test", &"wide_noodle")
	var wrong_bowl := bowl_scene.instantiate() as OrderBowl
	if not wrong_bowl.bind_to_order(wrong_order):
		_failures.append("Wrong-staple Bowl must bind its order")
	var wrong_food := wrong_bowl.food_state
	if not wrong_bowl.add_staple(&"instant_noodle"):
		_failures.append("OrderBowl must allow a staple that differs from the order requirement")
	if (
		wrong_order.required_staple_id != &"wide_noodle"
		or wrong_bowl.food_state != wrong_food
		or wrong_bowl.food_state.staple_id != &"instant_noodle"
	):
		_failures.append("Wrong staple must remain the actual station choice without correction")
	wrong_bowl.free()

	var empty_id_bowl := bowl_scene.instantiate() as OrderBowl
	empty_id_bowl.bind_to_order(order)
	var empty_id_food := empty_id_bowl.food_state
	if empty_id_bowl.can_add_staple(&"") or empty_id_bowl.add_staple(&""):
		_failures.append("OrderBowl must reject an empty staple ID")
	if empty_id_bowl.food_state != empty_id_food or empty_id_food.staple_id != &"":
		_failures.append("Empty staple failure must not replace or mutate FoodState")
	empty_id_bowl.free()

	var unbound_bowl := bowl_scene.instantiate() as OrderBowl
	if unbound_bowl.can_add_staple(&"wide_noodle") or unbound_bowl.add_staple(&"wide_noodle"):
		_failures.append("Unbound OrderBowl must reject staple addition")
	if unbound_bowl.order_id != &"" or unbound_bowl.food_state != null:
		_failures.append("Staple failure must not repair an unbound OrderBowl")
	unbound_bowl.free()

	var empty_bowl := bowl_scene.instantiate() as OrderBowl
	empty_bowl.bind_to_order(order)
	var removed_food := empty_bowl.take_food_state()
	var empty_bowl_order_id := empty_bowl.order_id
	if empty_bowl.can_add_staple(&"wide_noodle") or empty_bowl.add_staple(&"wide_noodle"):
		_failures.append("Empty OrderBowl must reject staple addition")
	if empty_bowl.food_state != null or empty_bowl.order_id != empty_bowl_order_id:
		_failures.append("Staple failure must not rebuild Empty Bowl FoodState")
	if removed_food == null:
		_failures.append("Empty Bowl setup must retain the removed FoodState instance")
	empty_bowl.free()

	var mismatch_bowl := bowl_scene.instantiate() as OrderBowl
	mismatch_bowl.bind_to_order(order)
	var mismatch_food := FoodState.new(&"different_order", true, &"")
	mismatch_bowl.food_state = mismatch_food
	if mismatch_bowl.can_add_staple(&"wide_noodle") or mismatch_bowl.add_staple(&"wide_noodle"):
		_failures.append("OrderBowl must reject staple addition for mismatched FoodState order_id")
	if mismatch_bowl.food_state != mismatch_food or mismatch_food.staple_id != &"":
		_failures.append("Order mismatch failure must preserve the original FoodState reference and contents")
	mismatch_bowl.free()


func _check_order_bowl_carry_integration() -> void:
	var player_scene := load("res://scenes/player.tscn") as PackedScene
	var counter_scene := load("res://scenes/test_counter.tscn") as PackedScene
	var bowl_scene := load("res://scenes/order_bowl.tscn") as PackedScene
	if player_scene == null or counter_scene == null or bowl_scene == null:
		return

	var test_world := Node2D.new()
	get_root().add_child(test_world)
	var player := player_scene.instantiate()
	var second_player := player_scene.instantiate()
	second_player.name = "SecondPlayer"
	var surface := counter_scene.instantiate() as PlacementSurface
	var bowl := bowl_scene.instantiate() as OrderBowl
	test_world.add_child(player)
	test_world.add_child(second_player)
	test_world.add_child(surface)
	test_world.add_child(bowl)

	var order := OrderData.new(&"order_test_001", &"wide_noodle")
	if not bowl.bind_to_order(order):
		_failures.append("Carry integration Bowl must bind OrderData")
	var original_food := bowl.food_state
	var player_carry := player.get_node("PlayerCarry") as PlayerCarry
	var second_player_carry := second_player.get_node("PlayerCarry") as PlayerCarry

	if not player_carry.pickup(bowl):
		_failures.append("PlayerCarry must pick up OrderBowl through Carryable")
	if not player_carry.place_on(surface):
		_failures.append("PlayerCarry must place OrderBowl on generic PlacementSurface")
	if surface.occupied_item != bowl:
		_failures.append("PlacementSurface must hold OrderBowl as a Carryable")
	if not surface.interact(second_player_carry):
		_failures.append("Generic PlacementSurface must return OrderBowl to an empty PlayerCarry")
	if (
		second_player_carry.get_held_item() != bowl
		or bowl.order_id != order.order_id
		or bowl.food_state != original_food
	):
		_failures.append("Filled OrderBowl carry flow must preserve business state")

	var removed_food := bowl.take_food_state()
	if removed_food != original_food or bowl.order_id != order.order_id:
		_failures.append("Emptying a carried OrderBowl must preserve order identity")
	if not second_player_carry.place_on(surface):
		_failures.append("Empty OrderBowl must still place on a generic surface")
	if not surface.interact(player_carry):
		_failures.append("Empty OrderBowl must still be taken from a generic surface")
	if (
		player_carry.get_held_item() != bowl
		or bowl.order_id != order.order_id
		or bowl.food_state != null
	):
		_failures.append("Empty OrderBowl carry flow must preserve empty order state")

	test_world.free()


func _check_staple_station_business_rules() -> void:
	var station_scene := load("res://scenes/staple_station.tscn") as PackedScene
	var player_scene := load("res://scenes/player.tscn") as PackedScene
	var carryable_scene := load("res://scenes/test_carryable.tscn") as PackedScene
	var bowl_scene := load("res://scenes/order_bowl.tscn") as PackedScene
	var counter_scene := load("res://scenes/test_counter.tscn") as PackedScene
	if (
		station_scene == null
		or player_scene == null
		or carryable_scene == null
		or bowl_scene == null
		or counter_scene == null
	):
		return

	var station := station_scene.instantiate() as StapleStation
	if station == null:
		_failures.append("StapleStation scene must instantiate as StapleStation")
		return
	var highlight := station.get_node("Highlight") as Polygon2D
	var station_top := station.get_node("StationTop") as Polygon2D
	var station_front := station.get_node("StationFront") as Polygon2D
	var interaction_shape := station.get_node("InteractionShape") as CollisionShape2D
	var static_body := station.get_node("StaticBody2D") as StaticBody2D
	var static_shape := station.get_node("StaticBody2D/CollisionShape2D") as CollisionShape2D
	if station.z_index != 0 or highlight.z_index != 0:
		_failures.append("StapleStation root and Highlight must remain at z_index 0")
	if station_top.z_index != 0 or station_front.z_index != 0:
		_failures.append("StapleStation visuals must remain at z_index 0")
	if highlight.get_index() >= station_top.get_index() or highlight.get_index() >= station_front.get_index():
		_failures.append("StapleStation Highlight must draw before station visuals by sibling order")
	if interaction_shape.get_parent() != station:
		_failures.append("StapleStation interaction collision must remain on the Area2D root")
	if static_body.get_parent() != station or static_shape.get_parent() != static_body:
		_failures.append("StapleStation must contain a separate StaticBody2D collision")
	if station.collision_layer != 4 or static_body.collision_layer != 1:
		_failures.append("StapleStation must use interaction layer 3 and world collision layer 1")
	for method_name in [&"can_interact", &"interact", &"set_highlighted"]:
		if not station.has_method(method_name):
			_failures.append("StapleStation missing generic interaction method: %s" % method_name)
	for property_data: Dictionary in station.get_property_list():
		var property_name := StringName(property_data.get("name", ""))
		if property_name in [&"current_bowl", &"current_player", &"current_carry"]:
			_failures.append("StapleStation must not retain long-lived interaction reference: %s" % property_name)

	var movement_scene := load("res://scenes/movement_test.tscn") as PackedScene
	if movement_scene != null:
		var movement_test := movement_scene.instantiate()
		var y_sort_world := movement_test.get_node("YSortWorld") as Node2D
		var wide_station := y_sort_world.get_node("WideNoodleStation") as StapleStation
		var instant_station := y_sort_world.get_node("InstantNoodleStation") as StapleStation
		if wide_station.staple_id != &"wide_noodle":
			_failures.append("WideNoodleStation must use the stable wide_noodle gameplay ID")
		if instant_station.staple_id != &"instant_noodle":
			_failures.append("InstantNoodleStation must use the stable instant_noodle gameplay ID")
		if wide_station.get_parent() != y_sort_world or instant_station.get_parent() != y_sort_world:
			_failures.append("Staple stations must be direct YSortWorld children")
		movement_test.free()

	var test_world := Node2D.new()
	get_root().add_child(test_world)
	test_world.add_child(station)
	station.set_highlighted(true)
	if not highlight.visible:
		_failures.append("StapleStation must show Highlight when selected")
	station.set_highlighted(false)
	if highlight.visible:
		_failures.append("StapleStation must hide Highlight when deselected")

	var empty_player := player_scene.instantiate()
	empty_player.name = "EmptyHandPlayer"
	test_world.add_child(empty_player)
	var empty_carry := empty_player.get_node("PlayerCarry") as PlayerCarry
	station.staple_id = &"wide_noodle"
	if station.can_interact(empty_carry) or station.interact(empty_carry):
		_failures.append("StapleStation must reject empty-hand interaction")

	var generic_player := player_scene.instantiate()
	generic_player.name = "GenericCarryPlayer"
	var generic_item := carryable_scene.instantiate() as Carryable
	generic_item.name = "GenericCarryItem"
	test_world.add_child(generic_player)
	test_world.add_child(generic_item)
	var generic_carry := generic_player.get_node("PlayerCarry") as PlayerCarry
	if not generic_carry.pickup(generic_item):
		_failures.append("Generic carry setup must pick up TestCarryable")
	if station.can_interact(generic_carry) or station.interact(generic_carry):
		_failures.append("StapleStation must reject a non-OrderBowl Carryable")

	var unbound_player := player_scene.instantiate()
	unbound_player.name = "UnboundBowlPlayer"
	var unbound_bowl := bowl_scene.instantiate() as OrderBowl
	unbound_bowl.name = "UnboundBowl"
	test_world.add_child(unbound_player)
	test_world.add_child(unbound_bowl)
	var unbound_carry := unbound_player.get_node("PlayerCarry") as PlayerCarry
	unbound_carry.pickup(unbound_bowl)
	if station.can_interact(unbound_carry) or station.interact(unbound_carry):
		_failures.append("StapleStation must reject an unbound OrderBowl")
	if unbound_bowl.food_state != null:
		_failures.append("StapleStation must not create FoodState for an unbound Bowl")

	var empty_bowl_player := player_scene.instantiate()
	empty_bowl_player.name = "EmptyBowlPlayer"
	var empty_bowl := bowl_scene.instantiate() as OrderBowl
	empty_bowl.name = "EmptyOrderBowl"
	empty_bowl.bind_to_order(OrderData.new(&"empty_bowl_order", &"wide_noodle"))
	empty_bowl.take_food_state()
	test_world.add_child(empty_bowl_player)
	test_world.add_child(empty_bowl)
	var empty_bowl_carry := empty_bowl_player.get_node("PlayerCarry") as PlayerCarry
	empty_bowl_carry.pickup(empty_bowl)
	if station.can_interact(empty_bowl_carry) or station.interact(empty_bowl_carry):
		_failures.append("StapleStation must reject an Empty Order Bowl")
	if empty_bowl.food_state != null:
		_failures.append("StapleStation must not restore Empty Bowl FoodState")

	var valid_player := player_scene.instantiate()
	valid_player.name = "ValidBowlPlayer"
	var valid_bowl := bowl_scene.instantiate() as OrderBowl
	valid_bowl.name = "ValidOrderBowl"
	var required_wide_order := OrderData.new(&"station_wrong_staple_order", &"wide_noodle")
	valid_bowl.bind_to_order(required_wide_order)
	test_world.add_child(valid_player)
	test_world.add_child(valid_bowl)
	var valid_carry := valid_player.get_node("PlayerCarry") as PlayerCarry
	valid_carry.pickup(valid_bowl)
	var valid_food := valid_bowl.food_state
	var held_parent := valid_bowl.get_parent()
	station.staple_id = &""
	if station.can_interact(valid_carry) or station.interact(valid_carry):
		_failures.append("StapleStation with an empty staple_id must reject a valid Bowl")
	if valid_carry.get_held_item() != valid_bowl or valid_bowl.get_parent() != held_parent:
		_failures.append("Empty station interaction must preserve Bowl carry state")

	station.staple_id = &"instant_noodle"
	if not station.can_interact(valid_carry):
		_failures.append("Wrong StapleStation must remain interactable for a valid Bowl")
	if not station.interact(valid_carry):
		_failures.append("Wrong StapleStation interaction must succeed")
	if (
		required_wide_order.required_staple_id != &"wide_noodle"
		or valid_carry.get_held_item() != valid_bowl
		or valid_bowl.food_state != valid_food
		or valid_food.staple_id != &"instant_noodle"
	):
		_failures.append("Wrong station must record instant_noodle without replacing Bowl or FoodState")

	station.staple_id = &"wide_noodle"
	var second_attempt_parent := valid_bowl.get_parent()
	var second_attempt_position := valid_bowl.position
	if station.can_interact(valid_carry) or station.interact(valid_carry):
		_failures.append("A second StapleStation must not replace the existing staple")
	if (
		valid_carry.get_held_item() != valid_bowl
		or valid_bowl.get_parent() != second_attempt_parent
		or valid_bowl.position != second_attempt_position
		or valid_bowl.food_state != valid_food
		or valid_food.staple_id != &"instant_noodle"
	):
		_failures.append("Rejected second station interaction must be atomic")

	var rejecting_player := player_scene.instantiate()
	rejecting_player.name = "RejectingBowlPlayer"
	var rejecting_bowl := RejectingOrderBowl.new()
	rejecting_bowl.name = "RejectingOrderBowl"
	var rejecting_highlight := Polygon2D.new()
	rejecting_highlight.name = "Highlight"
	rejecting_bowl.add_child(rejecting_highlight)
	rejecting_bowl.order_id = &"rejecting_order"
	rejecting_bowl.food_state = FoodState.new(&"rejecting_order", true, &"")
	test_world.add_child(rejecting_player)
	test_world.add_child(rejecting_bowl)
	var rejecting_carry := rejecting_player.get_node("PlayerCarry") as PlayerCarry
	rejecting_carry.pickup(rejecting_bowl)
	station.staple_id = &"instant_noodle"
	var rejecting_food := rejecting_bowl.food_state
	var rejecting_parent := rejecting_bowl.get_parent()
	var rejecting_position := rejecting_bowl.position
	var rejecting_holder := rejecting_bowl.current_holder
	if not station.can_interact(rejecting_carry):
		_failures.append("Atomic failure test Bowl must pass Station preconditions")
	if station.interact(rejecting_carry):
		_failures.append("StapleStation must return Bowl.add_staple failure unchanged")
	if (
		rejecting_carry.get_held_item() != rejecting_bowl
		or rejecting_bowl.current_holder != rejecting_holder
		or rejecting_bowl.get_parent() != rejecting_parent
		or rejecting_bowl.position != rejecting_position
		or rejecting_bowl.food_state != rejecting_food
		or rejecting_food.staple_id != &""
	):
		_failures.append("Bowl.add_staple failure must not reparent, drop, place, or mutate state")

	var surface := counter_scene.instantiate() as PlacementSurface
	surface.name = "StapleCarryRegressionCounter"
	var receiving_player := player_scene.instantiate()
	receiving_player.name = "StapleCarryReceivingPlayer"
	test_world.add_child(surface)
	test_world.add_child(receiving_player)
	var receiving_carry := receiving_player.get_node("PlayerCarry") as PlayerCarry
	if not valid_carry.place_on(surface):
		_failures.append("OrderBowl with a staple must still place on a Counter")
	if not surface.interact(receiving_carry):
		_failures.append("OrderBowl with a staple must still be taken from a Counter")
	if (
		receiving_carry.get_held_item() != valid_bowl
		or valid_bowl.order_id != required_wide_order.order_id
		or valid_bowl.food_state != valid_food
		or valid_food.staple_id != &"instant_noodle"
	):
		_failures.append("Counter carry flow must preserve staple Bowl business state")
	if not receiving_carry.drop_to_world(Vector2(320.0, 220.0)):
		_failures.append("OrderBowl with a staple must still support Floor Drop")
	elif (
		valid_bowl.get_parent() != test_world
		or valid_bowl.order_id != required_wide_order.order_id
		or valid_bowl.food_state != valid_food
		or valid_food.staple_id != &"instant_noodle"
	):
		_failures.append("Floor Drop must preserve staple Bowl business state")

	test_world.free()


func _check_pot_business_rules() -> void:
	var pot_scene := load("res://scenes/pot.tscn") as PackedScene
	var bowl_scene := load("res://scenes/order_bowl.tscn") as PackedScene
	if pot_scene == null or bowl_scene == null:
		return

	var pot := pot_scene.instantiate() as Pot
	if pot == null:
		_failures.append("Pot scene must instantiate as Pot")
		return
	if not pot is Carryable:
		_failures.append("Pot must inherit Carryable")
	if pot.order_id != &"" or pot.food_state != null:
		_failures.append("New Pot must begin unbound and empty")
	if pot.collision_layer != Carryable.INTERACTABLE_LAYER:
		_failures.append("Ground Pot must use the existing interactable layer 3")
	if pot.get_node_or_null("StaticBody2D") != null:
		_failures.append("Pot must not contain a StaticBody2D")

	var highlight := pot.get_node("Highlight") as Polygon2D
	var pot_visual := pot.get_node("PotVisual") as Polygon2D
	var food_visual := pot.get_node("FoodVisual") as Polygon2D
	var collision_shape := pot.get_node("CollisionShape2D") as CollisionShape2D
	if (
		pot.z_index != 0
		or highlight.z_index != 0
		or pot_visual.z_index != 0
		or food_visual.z_index != 0
	):
		_failures.append("Pot and all visuals must remain at z_index 0")
	if (
		highlight.get_index() >= pot_visual.get_index()
		or pot_visual.get_index() >= food_visual.get_index()
		or food_visual.get_index() >= collision_shape.get_index()
	):
		_failures.append("Pot must use Highlight, PotVisual, FoodVisual, CollisionShape2D sibling order")
	if not pot_visual.visible or food_visual.visible:
		_failures.append("New Pot must show PotVisual and hide FoodVisual")
	for method_name in [
		&"can_receive_food_state",
		&"receive_food_state",
		&"can_receive_from_bowl",
		&"receive_from_bowl",
		&"can_interact",
		&"interact",
	]:
		if not pot.has_method(method_name):
			_failures.append("Pot missing required method: %s" % method_name)
	for forbidden_method in [&"take_food_state", &"pour_to_bowl", &"serve_to_bowl", &"transfer_to_bowl"]:
		if pot.has_method(forbidden_method):
			_failures.append("Pot must not expose reverse transfer method: %s" % forbidden_method)

	var food := FoodState.new(&"order_pot_001", true, &"wide_noodle")
	var food_order_id := food.order_id
	var food_base_present := food.base_food_present
	var food_staple_id := food.staple_id
	if not pot.can_receive_food_state(food) or not pot.receive_food_state(food):
		_failures.append("Empty Pot must receive a valid FoodState")
	if pot.order_id != &"order_pot_001" or pot.food_state != food:
		_failures.append("Pot must bind from and preserve the same FoodState instance")
	if (
		food.order_id != food_order_id
		or food.base_food_present != food_base_present
		or food.staple_id != food_staple_id
	):
		_failures.append("Pot receipt must not mutate FoodState contents")
	if not food_visual.visible:
		_failures.append("Pot with non-empty FoodState must show FoodVisual")

	var same_order_food := FoodState.new(&"order_pot_001", true, &"instant_noodle")
	var other_order_food := FoodState.new(&"order_pot_002", true, &"instant_noodle")
	if (
		pot.can_receive_food_state(same_order_food)
		or pot.receive_food_state(same_order_food)
		or pot.can_receive_food_state(other_order_food)
		or pot.receive_food_state(other_order_food)
	):
		_failures.append("Occupied Pot must reject every second FoodState")
	if pot.order_id != &"order_pot_001" or pot.food_state != food:
		_failures.append("Occupied Pot failure must preserve the original order and FoodState")
	pot.free()

	var valid_empty_food := FoodState.new(&"order_empty_contents", false, &"")
	var empty_contents_pot := pot_scene.instantiate() as Pot
	if not empty_contents_pot.receive_food_state(valid_empty_food):
		_failures.append("Pot must accept a valid FoodState even when its contents are empty")
	if empty_contents_pot.food_state != valid_empty_food:
		_failures.append("Pot must preserve valid empty FoodState identity")
	if (empty_contents_pot.get_node("FoodVisual") as CanvasItem).visible:
		_failures.append("Pot must hide FoodVisual for an empty FoodState")
	empty_contents_pot.free()

	var bound_empty_pot := pot_scene.instantiate() as Pot
	bound_empty_pot.order_id = &"bound_pot_order"
	var matching_food := FoodState.new(&"bound_pot_order", true, &"wide_noodle")
	var mismatching_food := FoodState.new(&"other_pot_order", true, &"wide_noodle")
	if bound_empty_pot.can_receive_food_state(mismatching_food) or bound_empty_pot.receive_food_state(mismatching_food):
		_failures.append("Bound empty Pot must reject a different order")
	if bound_empty_pot.order_id != &"bound_pot_order" or bound_empty_pot.food_state != null:
		_failures.append("Order mismatch must not mutate a bound empty Pot")
	if not bound_empty_pot.can_receive_food_state(matching_food):
		_failures.append("Bound empty Pot must accept a matching order")
	bound_empty_pot.free()

	var invalid_receive_pot := pot_scene.instantiate() as Pot
	var invalid_food := FoodState.new(&"", true, &"wide_noodle")
	if (
		invalid_receive_pot.can_receive_food_state(null)
		or invalid_receive_pot.receive_food_state(null)
		or invalid_receive_pot.can_receive_food_state(invalid_food)
		or invalid_receive_pot.receive_food_state(invalid_food)
	):
		_failures.append("Pot must reject null and invalid FoodState")
	if invalid_receive_pot.order_id != &"" or invalid_receive_pot.food_state != null:
		_failures.append("Invalid FoodState failure must not bind or fill Pot")
	invalid_receive_pot.free()

	var transfer_order := OrderData.new(&"order_transfer_001", &"wide_noodle")
	var transfer_bowl := bowl_scene.instantiate() as OrderBowl
	var transfer_pot := pot_scene.instantiate() as Pot
	transfer_bowl.bind_to_order(transfer_order)
	transfer_bowl.add_staple(&"wide_noodle")
	var original_food := transfer_bowl.food_state
	var original_food_order := original_food.order_id
	var original_base_present := original_food.base_food_present
	var original_staple := original_food.staple_id
	if not transfer_pot.can_receive_from_bowl(transfer_bowl):
		_failures.append("Free ground Pot must accept a valid filled OrderBowl")
	if not transfer_pot.receive_from_bowl(transfer_bowl):
		_failures.append("Bowl to Pot transfer must succeed")
	if transfer_bowl.order_id != transfer_order.order_id or transfer_bowl.food_state != null:
		_failures.append("Successful transfer must leave an Empty Order Bowl with its order_id")
	if transfer_pot.order_id != transfer_order.order_id or transfer_pot.food_state != original_food:
		_failures.append("Successful transfer must move the exact FoodState instance into Pot")
	if (
		original_food.order_id != original_food_order
		or original_food.base_food_present != original_base_present
		or original_food.staple_id != original_staple
	):
		_failures.append("Bowl to Pot transfer must not mutate FoodState data")
	if (
		(transfer_bowl.get_node("FoodVisual") as CanvasItem).visible
		or (transfer_bowl.get_node("StapleVisual") as CanvasItem).visible
	):
		_failures.append("Transferred-from Bowl must hide FoodVisual and StapleVisual")
	if not (transfer_pot.get_node("FoodVisual") as CanvasItem).visible:
		_failures.append("Transferred-to Pot must show FoodVisual")
	transfer_bowl.free()
	transfer_pot.free()

	var wrong_order := OrderData.new(&"order_wrong_pot_transfer", &"wide_noodle")
	var wrong_bowl := bowl_scene.instantiate() as OrderBowl
	var wrong_pot := pot_scene.instantiate() as Pot
	wrong_bowl.bind_to_order(wrong_order)
	wrong_bowl.add_staple(&"instant_noodle")
	var wrong_food := wrong_bowl.food_state
	if not wrong_pot.receive_from_bowl(wrong_bowl):
		_failures.append("Pot must accept a wrong staple selected by the player")
	if (
		wrong_order.required_staple_id != &"wide_noodle"
		or wrong_pot.food_state != wrong_food
		or wrong_pot.food_state.staple_id != &"instant_noodle"
	):
		_failures.append("Wrong staple transfer must preserve instant_noodle without correction")
	wrong_bowl.free()
	wrong_pot.free()

	var unbound_bowl := bowl_scene.instantiate() as OrderBowl
	var unbound_target_pot := pot_scene.instantiate() as Pot
	if (
		unbound_target_pot.can_receive_from_bowl(unbound_bowl)
		or unbound_target_pot.receive_from_bowl(unbound_bowl)
	):
		_failures.append("Pot must reject an unbound OrderBowl")
	if unbound_bowl.food_state != null or unbound_target_pot.food_state != null:
		_failures.append("Unbound Bowl transfer failure must not create FoodState")
	unbound_bowl.free()
	unbound_target_pot.free()

	var empty_bowl := bowl_scene.instantiate() as OrderBowl
	var empty_target_pot := pot_scene.instantiate() as Pot
	empty_bowl.bind_to_order(OrderData.new(&"empty_transfer_order", &"wide_noodle"))
	var removed_food := empty_bowl.take_food_state()
	if empty_target_pot.can_receive_from_bowl(empty_bowl) or empty_target_pot.receive_from_bowl(empty_bowl):
		_failures.append("Pot must reject an Empty Order Bowl")
	if empty_bowl.food_state != null or empty_target_pot.food_state != null or removed_food == null:
		_failures.append("Empty Bowl transfer failure must preserve empty container states")
	empty_bowl.free()
	empty_target_pot.free()

	var invalid_bowl := bowl_scene.instantiate() as OrderBowl
	var invalid_target_pot := pot_scene.instantiate() as Pot
	invalid_bowl.bind_to_order(OrderData.new(&"invalid_food_order", &"wide_noodle"))
	var invalid_bowl_food := FoodState.new(&"", true, &"wide_noodle")
	invalid_bowl.food_state = invalid_bowl_food
	if (
		invalid_target_pot.can_receive_from_bowl(invalid_bowl)
		or invalid_target_pot.receive_from_bowl(invalid_bowl)
	):
		_failures.append("Pot must reject invalid FoodState in a Bowl")
	if invalid_bowl.food_state != invalid_bowl_food or invalid_target_pot.food_state != null:
		_failures.append("Invalid Bowl FoodState failure must preserve both containers")
	invalid_bowl.free()
	invalid_target_pot.free()

	var mismatch_bowl := bowl_scene.instantiate() as OrderBowl
	var mismatch_target_pot := pot_scene.instantiate() as Pot
	mismatch_bowl.bind_to_order(OrderData.new(&"mismatch_bowl_order", &"wide_noodle"))
	var mismatch_food := FoodState.new(&"different_food_order", true, &"wide_noodle")
	mismatch_bowl.food_state = mismatch_food
	if (
		mismatch_target_pot.can_receive_from_bowl(mismatch_bowl)
		or mismatch_target_pot.receive_from_bowl(mismatch_bowl)
	):
		_failures.append("Pot must reject Bowl and FoodState order mismatch")
	if mismatch_bowl.food_state != mismatch_food or mismatch_target_pot.food_state != null:
		_failures.append("Bowl order mismatch failure must preserve both containers")
	mismatch_bowl.free()
	mismatch_target_pot.free()

	var rollback_bowl := bowl_scene.instantiate() as OrderBowl
	rollback_bowl.bind_to_order(OrderData.new(&"rollback_order", &"wide_noodle"))
	var rollback_food := rollback_bowl.food_state
	var rejecting_pot := RejectingReceivePot.new()
	if not rejecting_pot.can_receive_from_bowl(rollback_bowl):
		_failures.append("RejectingReceivePot setup must pass transfer precheck")
	if rejecting_pot.receive_from_bowl(rollback_bowl):
		_failures.append("RejectingReceivePot must report transfer failure")
	if (
		rollback_bowl.order_id != &"rollback_order"
		or rollback_bowl.food_state != rollback_food
		or rejecting_pot.order_id != &""
		or rejecting_pot.food_state != null
	):
		_failures.append("Failed Pot receipt must roll the exact FoodState back into its Bowl")
	rollback_bowl.free()
	rejecting_pot.free()


func _check_pot_interaction_and_carry() -> void:
	var pot_scene := load("res://scenes/pot.tscn") as PackedScene
	var bowl_scene := load("res://scenes/order_bowl.tscn") as PackedScene
	var player_scene := load("res://scenes/player.tscn") as PackedScene
	var carryable_scene := load("res://scenes/test_carryable.tscn") as PackedScene
	var counter_scene := load("res://scenes/test_counter.tscn") as PackedScene
	if (
		pot_scene == null
		or bowl_scene == null
		or player_scene == null
		or carryable_scene == null
		or counter_scene == null
	):
		return

	var movement_scene := load("res://scenes/movement_test.tscn") as PackedScene
	if movement_scene != null:
		var movement_test := movement_scene.instantiate()
		var y_sort_world := movement_test.get_node("YSortWorld") as Node2D
		var movement_pot := y_sort_world.get_node("PotA") as Pot
		if movement_pot == null or movement_pot.get_parent() != y_sort_world:
			_failures.append("MovementTest PotA must be a direct YSortWorld Pot")
		elif movement_pot.z_index != 0 or movement_pot.position != Vector2(400.0, 160.0):
			_failures.append("MovementTest PotA must keep its Phase 5 position and z_index 0")
		movement_test.free()

	var test_world := Node2D.new()
	get_root().add_child(test_world)

	var transfer_pot := pot_scene.instantiate() as Pot
	transfer_pot.name = "InteractionTransferPot"
	transfer_pot.position = Vector2(120.0, 40.0)
	var source_player := player_scene.instantiate()
	source_player.name = "PotTransferPlayer"
	var source_bowl := bowl_scene.instantiate() as OrderBowl
	source_bowl.name = "PotTransferBowl"
	var source_order := OrderData.new(&"pot_interaction_order", &"wide_noodle")
	source_bowl.bind_to_order(source_order)
	source_bowl.add_staple(&"instant_noodle")
	test_world.add_child(transfer_pot)
	test_world.add_child(source_player)
	test_world.add_child(source_bowl)
	var source_carry := source_player.get_node("PlayerCarry") as PlayerCarry
	source_carry.pickup(source_bowl)
	var source_food := source_bowl.food_state
	var transfer_pot_parent := transfer_pot.get_parent()
	var transfer_pot_position := transfer_pot.position
	transfer_pot.set_highlighted(true)
	if not (transfer_pot.get_node("Highlight") as CanvasItem).visible:
		_failures.append("Pot must inherit working Carryable highlight behavior")
	transfer_pot.set_highlighted(false)
	if not transfer_pot.can_interact(source_carry):
		_failures.append("Ground empty Pot must be interactable while Player holds a valid Bowl")
	if not transfer_pot.interact(source_carry):
		_failures.append("Pot interaction must transfer FoodState from held OrderBowl")
	if (
		source_carry.get_held_item() != source_bowl
		or source_bowl.order_id != source_order.order_id
		or source_bowl.food_state != null
		or transfer_pot.order_id != source_order.order_id
		or transfer_pot.food_state != source_food
		or source_food.staple_id != &"instant_noodle"
		or transfer_pot.get_parent() != transfer_pot_parent
		or transfer_pot.position != transfer_pot_position
	):
		_failures.append("Pot interaction must move only the FoodState and keep Bowl held and Pot grounded")

	var occupied_player := player_scene.instantiate()
	occupied_player.name = "OccupiedPotPlayer"
	var occupied_source_bowl := bowl_scene.instantiate() as OrderBowl
	occupied_source_bowl.name = "OccupiedPotSourceBowl"
	var occupied_source_order := OrderData.new(&"occupied_source_order", &"wide_noodle")
	occupied_source_bowl.bind_to_order(occupied_source_order)
	test_world.add_child(occupied_player)
	test_world.add_child(occupied_source_bowl)
	var occupied_carry := occupied_player.get_node("PlayerCarry") as PlayerCarry
	occupied_carry.pickup(occupied_source_bowl)
	var occupied_source_food := occupied_source_bowl.food_state
	var occupied_source_parent := occupied_source_bowl.get_parent()
	var occupied_source_position := occupied_source_bowl.position
	var occupied_source_holder := occupied_source_bowl.current_holder
	var occupied_pot_food := transfer_pot.food_state
	var occupied_pot_order := transfer_pot.order_id
	var occupied_pot_parent := transfer_pot.get_parent()
	var occupied_pot_position := transfer_pot.position
	if transfer_pot.can_interact(occupied_carry) or transfer_pot.interact(occupied_carry):
		_failures.append("Occupied Pot must reject a second held OrderBowl")
	if (
		occupied_carry.get_held_item() != occupied_source_bowl
		or occupied_source_bowl.current_holder != occupied_source_holder
		or occupied_source_bowl.get_parent() != occupied_source_parent
		or occupied_source_bowl.position != occupied_source_position
		or occupied_source_bowl.order_id != occupied_source_order.order_id
		or occupied_source_bowl.food_state != occupied_source_food
		or occupied_source_food.staple_id != &""
		or transfer_pot.food_state != occupied_pot_food
		or transfer_pot.order_id != occupied_pot_order
		or transfer_pot.get_parent() != occupied_pot_parent
		or transfer_pot.position != occupied_pot_position
	):
		_failures.append("Occupied Pot interaction failure must preserve Bowl, PlayerCarry, and Pot atomically")

	var generic_target_pot := pot_scene.instantiate() as Pot
	generic_target_pot.name = "GenericRejectionPot"
	var generic_player := player_scene.instantiate()
	generic_player.name = "PotGenericCarryPlayer"
	var generic_item := carryable_scene.instantiate() as Carryable
	generic_item.name = "PotGenericCarryItem"
	test_world.add_child(generic_target_pot)
	test_world.add_child(generic_player)
	test_world.add_child(generic_item)
	var generic_carry := generic_player.get_node("PlayerCarry") as PlayerCarry
	generic_carry.pickup(generic_item)
	if generic_target_pot.can_interact(generic_carry) or generic_target_pot.interact(generic_carry):
		_failures.append("Pot must reject interaction while Player holds TestCarryable")
	if generic_carry.get_held_item() != generic_item or generic_target_pot.food_state != null:
		_failures.append("Generic Carryable rejection must preserve held item and Pot state")

	var pot_carry_player := player_scene.instantiate()
	pot_carry_player.name = "PotHoldingPotPlayer"
	var held_input_pot := pot_scene.instantiate() as Pot
	held_input_pot.name = "HeldInputPot"
	test_world.add_child(pot_carry_player)
	test_world.add_child(held_input_pot)
	var pot_carry := pot_carry_player.get_node("PlayerCarry") as PlayerCarry
	pot_carry.pickup(held_input_pot)
	if generic_target_pot.can_interact(pot_carry) or generic_target_pot.interact(pot_carry):
		_failures.append("Pot must reject interaction while Player holds another Pot")
	if pot_carry.get_held_item() != held_input_pot or generic_target_pot.food_state != null:
		_failures.append("Held Pot rejection must not swap or fill either Pot")

	var empty_pickup_player := player_scene.instantiate()
	empty_pickup_player.name = "EmptyPotPickupPlayer"
	test_world.add_child(empty_pickup_player)
	var empty_pickup_carry := empty_pickup_player.get_node("PlayerCarry") as PlayerCarry
	if not generic_target_pot.can_interact(empty_pickup_carry):
		_failures.append("Empty-hand Player must be able to interact with a free empty Pot")
	if not generic_target_pot.interact(empty_pickup_carry):
		_failures.append("Empty-hand Pot interaction must use Carryable pickup")
	if empty_pickup_carry.get_held_item() != generic_target_pot:
		_failures.append("Pot pickup must place the same Pot in PlayerCarry")

	var constrained_pot := pot_scene.instantiate() as Pot
	constrained_pot.name = "ConstrainedPot"
	var constrained_player := player_scene.instantiate()
	constrained_player.name = "ConstrainedPotPlayer"
	var constrained_surface := counter_scene.instantiate() as PlacementSurface
	constrained_surface.name = "ConstrainedPotCounter"
	var constrained_source_bowl := bowl_scene.instantiate() as OrderBowl
	constrained_source_bowl.name = "ConstrainedPotSourceBowl"
	constrained_source_bowl.bind_to_order(OrderData.new(&"constrained_order", &"wide_noodle"))
	test_world.add_child(constrained_pot)
	test_world.add_child(constrained_player)
	test_world.add_child(constrained_surface)
	test_world.add_child(constrained_source_bowl)
	var constrained_carry := constrained_player.get_node("PlayerCarry") as PlayerCarry
	constrained_carry.pickup(constrained_pot)
	var constrained_food := constrained_source_bowl.food_state
	if (
		constrained_pot.can_receive_from_bowl(constrained_source_bowl)
		or constrained_pot.receive_from_bowl(constrained_source_bowl)
	):
		_failures.append("Held Pot public transfer API must reject Bowl input")
	if constrained_source_bowl.food_state != constrained_food or constrained_pot.food_state != null:
		_failures.append("Held Pot transfer rejection must preserve both containers")
	if not constrained_carry.place_on(constrained_surface):
		_failures.append("Empty Pot setup must place Pot on Counter")
	if (
		constrained_pot.can_receive_from_bowl(constrained_source_bowl)
		or constrained_pot.receive_from_bowl(constrained_source_bowl)
	):
		_failures.append("Counter-placed Pot public transfer API must reject Bowl input")
	if (
		constrained_pot.current_surface != constrained_surface
		or constrained_source_bowl.food_state != constrained_food
		or constrained_pot.food_state != null
	):
		_failures.append("Counter Pot transfer rejection must preserve placement and container states")

	var full_pot_food := transfer_pot.food_state
	var full_pot_order := transfer_pot.order_id
	var full_pot_staple := full_pot_food.staple_id
	var full_pot_carrier := player_scene.instantiate()
	full_pot_carrier.name = "FullPotCarrier"
	var full_pot_receiver := player_scene.instantiate()
	full_pot_receiver.name = "FullPotReceiver"
	var full_pot_surface := counter_scene.instantiate() as PlacementSurface
	full_pot_surface.name = "FullPotCounter"
	test_world.add_child(full_pot_carrier)
	test_world.add_child(full_pot_receiver)
	test_world.add_child(full_pot_surface)
	var full_pot_carry := full_pot_carrier.get_node("PlayerCarry") as PlayerCarry
	var full_pot_receive_carry := full_pot_receiver.get_node("PlayerCarry") as PlayerCarry
	if not transfer_pot.can_interact(full_pot_carry) or not transfer_pot.interact(full_pot_carry):
		_failures.append("Empty-hand Player must be able to pick up a full Pot")
	if not full_pot_carry.place_on(full_pot_surface):
		_failures.append("Full Pot must place on a generic Counter")
	if not full_pot_surface.interact(full_pot_receive_carry):
		_failures.append("Empty PlayerCarry must take a full Pot from Counter")
	if (
		full_pot_receive_carry.get_held_item() != transfer_pot
		or transfer_pot.order_id != full_pot_order
		or transfer_pot.food_state != full_pot_food
		or full_pot_food.staple_id != full_pot_staple
	):
		_failures.append("Full Pot pickup, Counter, and take flow must preserve business state")
	if not full_pot_receive_carry.drop_to_world(Vector2(520.0, 240.0)):
		_failures.append("Full Pot must support Floor Drop")
	elif (
		transfer_pot.get_parent() != test_world
		or transfer_pot.current_holder != null
		or transfer_pot.current_surface != null
		or transfer_pot.order_id != full_pot_order
		or transfer_pot.food_state != full_pot_food
		or full_pot_food.staple_id != full_pot_staple
	):
		_failures.append("Full Pot Floor Drop must preserve FoodState identity and order")

	test_world.free()


func _check_localization() -> void:
	var zh_keys := _load_json_keys("res://localization/zh_CN.json")
	var en_keys := _load_json_keys("res://localization/en_US.json")
	if zh_keys != en_keys:
		_failures.append("Localization key sets do not match")


func _load_json_keys(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_failures.append("Localization file failed to open: %s" % path)
		return []
	var data: Variant = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		_failures.append("Localization file is not a JSON object: %s" % path)
		return []
	var keys: Array = data.keys()
	keys.sort()
	return keys
