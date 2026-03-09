extends Control

@onready var camera: Camera3D = %MinimapCamera
var player: Node3D

func _ready() -> void:
	_find_player()
	# Set Camera Cull Mask: Layer 1 (Player), Layer 2 (World), Layer 10 (Minimap Icons)
	# Layers are bitmask: 1 | 2 | 512
	camera.cull_mask = (1 << 0) | (1 << 1) | (1 << 9)

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		_find_player()
		return
	
	# Follow player X and Z
	camera.global_position.x = player.global_position.x
	camera.global_position.z = player.global_position.z
	
	# North-is-Up (Reset rotation to look straight down)
	camera.rotation.y = 0
	camera.rotation.x = deg_to_rad(-90) # Look down
	camera.rotation.z = 0
