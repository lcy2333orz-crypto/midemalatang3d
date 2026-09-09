extends Node

@onready var _player: CharacterBody2D = get_parent() as CharacterBody2D


func _ready() -> void:
	process_physics_priority = -100


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector(
		&"gameplay_move_left",
		&"gameplay_move_right",
		&"gameplay_move_up",
		&"gameplay_move_down"
	)
	_player.call(&"set_move_intent", direction)
