extends SceneTree

const SCENE_PATHS := [
	"res://scenes/main.tscn",
	"res://scenes/movement_test.tscn",
	"res://scenes/player.tscn",
	"res://scenes/test_carryable.tscn",
	"res://scenes/test_counter.tscn",
]
const MOVEMENT_ACTIONS := [
	&"gameplay_move_up",
	&"gameplay_move_down",
	&"gameplay_move_left",
	&"gameplay_move_right",
]

var _failures: Array[String] = []


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
	var item_anchor := surface.get_node("ItemAnchor") as Marker2D
	var counter_front := surface.get_node("CounterFront") as Polygon2D
	if surface.z_index != 0 or carryable.z_index != 0 or item_anchor.z_index != 0:
		_failures.append("Counter, Carryable, and ItemAnchor must remain at z_index 0")
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
