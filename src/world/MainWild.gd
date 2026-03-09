extends Node3D

@export var wolf_boss_scene: PackedScene = preload("res://src/entities/enemies/Enemy.tscn") # Placeholder until boss variant created

var wolf_kill_count: int = 0
const BOSS_SPAWN_CHANCE_BASE: float = 0.15 # 15% chance after 5 kills

func _ready() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)
	
	if has_node("GateToTown"):
		$GateToTown.body_entered.connect(_on_gate_entered)
		_add_portal_icon($GateToTown, Color.VIOLET)

func _on_enemy_died(enemy_name: String, pos: Vector3) -> void:
	if enemy_name == "Wolf":
		wolf_kill_count += 1
		if wolf_kill_count >= 5:
			if randf() < BOSS_SPAWN_CHANCE_BASE:
				_spawn_wolf_boss(pos + Vector3(5, 0, 5)) # Spawn near the last kill
				wolf_kill_count = 0

func _spawn_wolf_boss(pos: Vector3) -> void:
	# Ensure position is grounded (simplified)
	pos.y = 1.0 
	
	var boss = wolf_boss_scene.instantiate()
	boss.set_script(load("res://src/entities/enemies/WolfBoss.gd"))
	
	boss.enemy_name = "Mor'ghul the Shadow-Stalker"
	boss.max_health = 600
	boss.damage = 18
	boss.move_speed = 1.5
	boss.chase_speed = 5.0
	boss.exp_reward = 500
	boss.gold_reward = 200
	
	add_child(boss)
	boss.global_position = pos
	
	# Visual customization for boss
	if boss.has_node("Model"):
		boss.get_node("Model").scale *= 2.5
		_apply_boss_tint(boss.get_node("Model"), Color(1.0, 0.2, 0.2))
	
	EventBus.boss_spawned.emit(boss.enemy_name)

func _apply_boss_tint(node: Node, tint: Color) -> void:
	if node is MeshInstance3D:
		var mat = node.material_override
		if not mat:
			mat = StandardMaterial3D.new()
			node.material_override = mat
		if mat is StandardMaterial3D:
			mat.albedo_color = tint
	for child in node.get_children():
		_apply_boss_tint(child, tint)

func _add_portal_icon(node: Node3D, color: Color) -> void:
	var icon = MinimapIcon.new()
	icon.color = color
	icon.size = 4.0
	node.add_child(icon)

func _on_gate_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		print("[Wild] Returning to Town...")
		if GameManager:
			GameManager.change_scene("res://src/world/TownFixed.tscn", body)
		else:
			get_tree().change_scene_to_file("res://src/world/TownFixed.tscn")
