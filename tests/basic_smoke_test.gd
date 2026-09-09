extends SceneTree

const SCENE_PATHS := [
	"res://scenes/main.tscn",
	"res://scenes/movement_test.tscn",
	"res://scenes/player.tscn",
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
	_check_camera()
	_check_input_actions()
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


func _check_input_actions() -> void:
	for action in MOVEMENT_ACTIONS:
		if not InputMap.has_action(action):
			_failures.append("Missing InputMap action: %s" % action)


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
