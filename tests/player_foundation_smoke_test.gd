extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/core/main.tscn"
const PLAYER_SCENE_PATH := "res://scenes/player/player.tscn"
const CAMERA_SCENE_PATH := "res://scenes/core/fixed_camera_rig.tscn"
const LEVEL_SCENE_PATH := "res://scenes/levels/player_movement_test.tscn"
const PLAYER_CONTROLLER_PATH := "res://scripts/player/player_controller.gd"

const MOVE_ACTIONS: Dictionary = {
	"gameplay_move_left": {
		"physical_key": KEY_A,
		"arrow_key": KEY_LEFT,
		"axis": JOY_AXIS_LEFT_X,
		"axis_value": -1.0,
		"dpad_button": JOY_BUTTON_DPAD_LEFT,
	},
	"gameplay_move_right": {
		"physical_key": KEY_D,
		"arrow_key": KEY_RIGHT,
		"axis": JOY_AXIS_LEFT_X,
		"axis_value": 1.0,
		"dpad_button": JOY_BUTTON_DPAD_RIGHT,
	},
	"gameplay_move_up": {
		"physical_key": KEY_W,
		"arrow_key": KEY_UP,
		"axis": JOY_AXIS_LEFT_Y,
		"axis_value": -1.0,
		"dpad_button": JOY_BUTTON_DPAD_UP,
	},
	"gameplay_move_down": {
		"physical_key": KEY_S,
		"arrow_key": KEY_DOWN,
		"axis": JOY_AXIS_LEFT_Y,
		"axis_value": 1.0,
		"dpad_button": JOY_BUTTON_DPAD_DOWN,
	},
}

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	_test_input_map()
	_test_player_scene()
	await _test_camera_scene()
	_test_level_scene()
	await _test_main_scene()

	if _failures == 0:
		print("PLAYER_FOUNDATION_SMOKE_TEST: PASS")
	else:
		printerr("PLAYER_FOUNDATION_SMOKE_TEST: FAIL (%d failure(s))" % _failures)

	quit(1 if _failures > 0 else 0)


func _test_input_map() -> void:
	for action_value: Variant in MOVE_ACTIONS.keys():
		var action := StringName(action_value)
		var expected: Dictionary = MOVE_ACTIONS[action_value]
		_expect(InputMap.has_action(action), "InputMap action exists: %s" % action)
		if not InputMap.has_action(action):
			continue

		_expect(
			is_equal_approx(InputMap.action_get_deadzone(action), 0.25),
			"InputMap deadzone is 0.25: %s" % action
		)
		_expect(
			_has_key_binding(action, expected["physical_key"], true),
			"physical keyboard binding exists: %s" % action
		)
		_expect(
			_has_key_binding(action, expected["arrow_key"], false),
			"arrow keyboard binding exists: %s" % action
		)
		_expect(
			_has_axis_binding(action, expected["axis"], expected["axis_value"]),
			"left stick binding exists: %s" % action
		)
		_expect(
			_has_button_binding(action, expected["dpad_button"]),
			"D-Pad binding exists: %s" % action
		)


func _test_player_scene() -> void:
	var player := _instantiate_scene(PLAYER_SCENE_PATH, "Player")
	if player == null:
		return

	_expect(player is CharacterBody3D, "Player root is CharacterBody3D")
	_expect(player.has_method("set_move_intent"), "Player exposes set_move_intent")
	_expect_equal(player.collision_layer, 2, "Player collision layer")
	_expect_equal(player.collision_mask, 3, "Player collision mask")
	_expect(player.position.is_zero_approx(), "Player root origin represents foot position")

	var collision := player.get_node_or_null("CollisionShape3D") as CollisionShape3D
	_expect(collision != null, "Player has CollisionShape3D")
	if collision != null:
		_expect(collision.shape is CapsuleShape3D, "Player collision uses CapsuleShape3D")
		_expect(is_equal_approx(collision.position.y, 0.7), "Capsule center is offset upward")
		if collision.shape is CapsuleShape3D:
			var capsule := collision.shape as CapsuleShape3D
			_expect(is_equal_approx(capsule.radius, 0.35), "Capsule radius")
			_expect(is_equal_approx(capsule.height, 1.4), "Capsule height")

	var visual_root := player.get_node_or_null("VisualRoot") as Node3D
	_expect(visual_root != null, "Player has VisualRoot")
	if visual_root != null:
		_expect(is_equal_approx(visual_root.position.y, 0.7), "VisualRoot is offset upward")
		_expect(
			visual_root.get_node_or_null("FacingMarker") is MeshInstance3D,
			"Player has non-text FacingMarker"
		)

	var local_input := player.get_node_or_null("LocalPlayerInput")
	var identity := player.get_node_or_null("PlayerIdentity")
	_expect(local_input != null, "Player has LocalPlayerInput")
	_expect(identity != null, "Player has PlayerIdentity")
	if local_input != null:
		_expect(local_input.get_script() != player.get_script(), "Input and Controller scripts are separate")
		_expect_equal(local_input.get("local_slot"), 0, "Local input slot")
		_expect_equal(local_input.get("input_device_id"), -1, "Unassigned input device")
		_expect(is_equal_approx(local_input.get("deadzone"), 0.25), "Local input deadzone")
	if identity != null:
		_expect_equal(identity.get("player_id"), 1, "Identity player_id")
		_expect_equal(identity.get("local_slot"), 0, "Identity local_slot")
		_expect_equal(identity.get("network_peer_id"), 0, "Identity network_peer_id")

	var controller_source := FileAccess.get_file_as_string(PLAYER_CONTROLLER_PATH)
	_expect(not controller_source.contains("Input."), "PlayerController does not read Input")
	player.free()


func _test_camera_scene() -> void:
	var rig := _instantiate_scene(CAMERA_SCENE_PATH, "Fixed Camera Rig")
	if rig == null:
		return

	root.add_child(rig)
	await process_frame

	var camera := rig.get_node_or_null("Camera3D") as Camera3D
	_expect(camera != null, "Camera Rig has Camera3D")
	if camera != null:
		_expect_equal(camera.projection, Camera3D.PROJECTION_ORTHOGONAL, "Camera projection")
		_expect(is_zero_approx(float(rig.get("yaw"))), "Camera yaw aligns world and screen axes")
		_expect(is_equal_approx(float(rig.get("pitch")), -55.0), "Camera keeps angled top-down pitch")
		_expect(is_equal_approx(camera.size, rig.get("orthographic_size")), "Camera size from rig")

		var yaw_radians := deg_to_rad(float(rig.get("yaw")))
		var pitch_radians := deg_to_rad(float(rig.get("pitch")))
		var camera_distance := float(rig.get("distance"))
		var horizontal_distance := cos(pitch_radians) * camera_distance
		var expected_offset := Vector3(
			sin(yaw_radians) * horizontal_distance,
			-sin(pitch_radians) * camera_distance,
			cos(yaw_radians) * horizontal_distance
		)
		_expect(camera.position.is_equal_approx(expected_offset), "Camera transform comes from rig")
		_expect(rig.position.is_equal_approx(rig.get("target")), "Camera target drives rig position")

	rig.queue_free()
	await process_frame


func _test_level_scene() -> void:
	var level := _instantiate_scene(LEVEL_SCENE_PATH, "Movement Test Level")
	if level == null:
		return

	_expect(level.get_node_or_null("Floor") is StaticBody3D, "Level has physical floor")
	_expect(level.get_node_or_null("NorthWall") is StaticBody3D, "Level has outer walls")
	_expect(level.get_node_or_null("SquareObstacle") is StaticBody3D, "Level has square obstacle")
	_expect(
		level.get_node_or_null("LongCounterObstacle") is StaticBody3D,
		"Level has long counter obstacle"
	)
	_expect(
		level.get_node_or_null("NarrowCorridorLeft") is StaticBody3D
		and level.get_node_or_null("NarrowCorridorRight") is StaticBody3D,
		"Level has narrow corridor"
	)
	_expect(level.get_node_or_null("Player") is CharacterBody3D, "Level instances Player")
	_expect(level.get_node_or_null("FixedCameraRig") is Node3D, "Level instances Camera Rig")
	level.free()


func _test_main_scene() -> void:
	var main := _instantiate_scene(MAIN_SCENE_PATH, "Main")
	if main == null:
		return

	_expect_equal(main.get_class(), "Node", "Main root is plain Node")
	_expect(not main is Control, "Main root is not Localization Control")
	_expect(main.get_node_or_null("PlayerMovementTest") is Node3D, "Main loads movement test")

	root.add_child(main)
	await process_frame
	await physics_frame
	main.queue_free()
	await process_frame


func _instantiate_scene(path: String, label: String) -> Node:
	var packed_scene := load(path) as PackedScene
	_expect(packed_scene != null, "%s scene loads" % label)
	if packed_scene == null:
		return null

	var instance := packed_scene.instantiate()
	_expect(instance != null, "%s scene instantiates" % label)
	return instance


func _has_key_binding(action: StringName, expected_key: Key, physical: bool) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if not event is InputEventKey:
			continue
		var key_event := event as InputEventKey
		var actual_key := key_event.physical_keycode if physical else key_event.keycode
		if actual_key == expected_key:
			return true
	return false


func _has_axis_binding(action: StringName, axis: JoyAxis, axis_value: float) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if not event is InputEventJoypadMotion:
			continue
		var motion_event := event as InputEventJoypadMotion
		if motion_event.axis == axis and is_equal_approx(motion_event.axis_value, axis_value):
			return true
	return false


func _has_button_binding(action: StringName, button: JoyButton) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and event.button_index == button:
			return true
	return false


func _expect(condition: bool, label: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: %s" % label)


func _expect_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual == expected:
		return
	_failures += 1
	printerr("FAIL: %s | expected=%s actual=%s" % [label, str(expected), str(actual)])
