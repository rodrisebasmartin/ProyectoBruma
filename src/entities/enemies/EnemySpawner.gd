extends Node3D

@export var enemy_scene: PackedScene = load("res://src/entities/enemies/Enemy.tscn")
@export var spawn_delay: float = 5.0

func _ready() -> void:
	# Initial spawn
	spawn_enemy()

func spawn_enemy() -> void:
	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	# Connect death signal to respawn
	enemy.died.connect(_on_enemy_died)
	print("[Spawner] Enemy spawned at: ", global_position)

func _on_enemy_died(_pos: Vector3, rewards: Dictionary) -> void:
	# Rewards can be handled here or by the player
	print("[Spawner] Enemy died. Rewards: ", rewards)
	print("[Spawner] Respawning in %f seconds..." % spawn_delay)
	await get_tree().create_timer(spawn_delay).timeout
	spawn_enemy()
