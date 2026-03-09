extends Node3D

@export var enemy_scenes: Array[PackedScene] = [
	preload("res://src/entities/enemies/Enemy.tscn")
]
@export var spawn_delay: float = 5.0

func _ready() -> void:
	if enemy_scenes.is_empty():
		enemy_scenes.append(load("res://src/entities/enemies/Enemy.tscn"))
	spawn_enemy()

func spawn_enemy() -> void:
	var scene = enemy_scenes[randi() % enemy_scenes.size()]
	var enemy = scene.instantiate()
	
	# Randomly strengthen some normal wolves
	if randf() < 0.2: # 20% chance for an "Alpha"
		enemy.enemy_name = "Alpha Wolf"
		enemy.max_health *= 2.0
		enemy.damage *= 1.5
		enemy.move_speed *= 1.2
		enemy.exp_reward *= 2.5
		enemy.set_meta("is_alpha", true)
	
	add_child(enemy)
	enemy.died.connect(_on_enemy_died)
	
	# Color alpha wolves slightly darker
	if enemy.get_meta("is_alpha", false):
		_tint_alpha(enemy, Color(0.4, 0.4, 0.5))

func _tint_alpha(node: Node, tint: Color) -> void:
	if node.has_node("Model"):
		var model = node.get_node("Model")
		for child in model.find_children("*", "MeshInstance3D"):
			var mat = child.material_override
			if not mat:
				mat = StandardMaterial3D.new()
				child.material_override = mat
			if mat is StandardMaterial3D:
				mat.albedo_color = mat.albedo_color.lerp(tint, 0.5)

func _on_enemy_died(_pos: Vector3, rewards: Dictionary) -> void:
	# Rewards can be handled here or by the player
	print("[Spawner] Enemy died. Rewards: ", rewards)
	print("[Spawner] Respawning in %f seconds..." % spawn_delay)
	await get_tree().create_timer(spawn_delay).timeout
	spawn_enemy()
