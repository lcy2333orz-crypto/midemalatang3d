class_name PlayerIdentity
extends Node

@export_range(1, 4, 1, "or_greater") var player_id: int = 1
@export_range(0, 3, 1, "or_greater") var local_slot: int = 0
@export_range(0, 2147483647, 1) var network_peer_id: int = 0
