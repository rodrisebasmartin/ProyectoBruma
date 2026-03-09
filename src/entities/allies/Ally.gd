extends CharacterBody3D

enum State { FOLLOW, SUPPORT, ATTACK, DEAD }

@export var player_node: CharacterBody3D 
@export var move_speed: float = 4.0
@export var follow_distance: float = 5.0 
@export var heal_threshold: float = 0.9 
@export var attack_range: float = 12.0

@export_group("Animations")
@export var animation_sources: Dictionary = {
	"Idle": "res://assets/animations/characters/idle/Idle.fbx",
	"Walk": "res://assets/animations/characters/walk/Standard Walk.fbx",
	"Punch1": "res://assets/animations/characters/combat/punch/Punching1.fbx",
	"Punch2": "res://assets/animations/characters/combat/punch/Punching2.fbx",
	"Punch3": "res://assets/animations/characters/combat/punch/Punching3.fbx",
	"Dodge": "res://assets/animations/characters/combat/dodge/StandingDodge.fbx"
}

@export_group("Magic")
@export var spell_scene: PackedScene = preload("res://src/entities/player/SpellProjectile.tscn")
@export var mana_cost_spell: float = 15.0
@export var cast_duration: float = 0.6 

# RPG State (Managed by Components)
var current_mana: float = 180.0
var max_mana: int = 180
var cast_timer: float = 0.0
var is_casting: bool = false
var next_projectile_is_heal: bool = false
var pending_target_pos: Vector3

# Components
var health: HealthComponent
var stats: StatsComponent
var animator: CharacterAnimator

func _ready() -> void:
	add_to_group("allies")
	
	# Dynamically ensure components exist
	_ensure_components()
	
	# Setup visuals (creates model and animator)
	_setup_visuals()
	
	# Connect component signals
	health.died.connect(_on_died)
	health.damage_taken.connect(_on_damage_taken)
	health.healed.connect(_on_healed)
	
	collision_layer = 8
	collision_mask = 2 | 4 
	if not player_node: _find_player()
	_add_minimap_icon()
	
	if animator:
		animator.play("Idle")

func _add_minimap_icon() -> void:
	var icon = MinimapIcon.new()
	icon.color = Color.GREEN
	icon.size = 2.5
	add_child(icon)

func _ensure_components() -> void:
	health = get_node_or_null("HealthComponent")
	if not health:
		health = HealthComponent.new()
		health.name = "HealthComponent"
		health.max_health = 100
		add_child(health)
		
	stats = get_node_or_null("StatsComponent")
	if not stats:
		stats = StatsComponent.new()
		stats.name = "StatsComponent"
		add_child(stats)
		
	animator = get_node_or_null("CharacterAnimator")
	if not animator:
		animator = CharacterAnimator.new()
		animator.name = "CharacterAnimator"
		# Script must be set for logic to run
		animator.set_script(load("res://src/core/components/CharacterAnimator.gd"))
		add_child(animator)

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0: player_node = players[0]

func _setup_visuals() -> void:
	var model_scene = load("res://assets/models/characters/player/test/testmodel.fbx")
	if model_scene:
		var model = model_scene.instantiate()
		model.name = "Model"
		add_child(model)
		model.position.y = 0.5 # Fix floating feet
		var animation_player = model.get_node_or_null("AnimationPlayer")
		
		# Link animator component to the new model
		if animator:
			animator.animation_player = animation_player
			animator.model_root = model
			animator.animation_sources = animation_sources
			# Re-trigger internal setup if already ready
			if animator.has_method("_load_external_animations"):
				animator._load_external_animations()
		
		_apply_tint_recursive(model, Color(0.4, 0.6, 1.0))
	
	# Ensure there is a collision shape
	if not get_node_or_null("CollisionShape3D"):
		var coll = CollisionShape3D.new()
		coll.name = "CollisionShape3D"
		coll.shape = CapsuleShape3D.new()
		add_child(coll)
		coll.position.y = 1.0

func _apply_tint_recursive(node: Node, tint: Color) -> void:
	if node is MeshInstance3D:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = tint
		node.material_override = mat
	for child in node.get_children():
		_apply_tint_recursive(child, tint)

func _physics_process(delta: float) -> void:
	if not health or health.is_dead or not is_inside_tree(): return
	
	# Apply Gravity
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0

	if not is_instance_valid(player_node): 
		_find_player()
		return
	
	if not is_casting:
		current_mana = min(current_mana + 15.0 * delta, max_mana)
	
	if is_casting:
		_update_aim() 
		cast_timer -= delta
		if cast_timer <= 0:
			_complete_cast()
		return

	_update_ai_logic(delta)
	_update_animations(delta)

func _update_animations(_delta: float) -> void:
	if not animator or is_casting: return
	
	if velocity.length() > 0.1:
		animator.play("Walk")
		var speed_percent = velocity.length() / move_speed
		animator.set_speed(speed_percent * 1.2)
	else:
		animator.play("Idle")
		animator.set_speed(1.0)

func _update_ai_logic(delta: float) -> void:
	var p_health = player_node.get_node_or_null("HealthComponent")
	var hp_pct = 1.0
	if p_health:
		hp_pct = float(p_health.current_health) / float(p_health.max_health)
		
	if hp_pct < heal_threshold and current_mana >= mana_cost_spell:
		_start_cast(true)
		return
	
	var enemy = _find_nearest_enemy()
	if enemy and global_position.distance_to(enemy.global_position) < attack_range:
		_start_cast(false)
		return
	
	var dist = global_position.distance_to(player_node.global_position)
	if dist > follow_distance:
		var dir = global_position.direction_to(player_node.global_position)
		velocity = dir * move_speed
		var target_angle = atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, target_angle, 5.0 * delta)
		move_and_slide()
	else:
		velocity = velocity.move_toward(Vector3.ZERO, 10.0 * delta)
		move_and_slide()

func _find_nearest_enemy() -> Node3D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest = null
	var min_dist = 999.0
	for e in enemies:
		if e.has_method("get_node"):
			var e_health = e.get_node_or_null("HealthComponent")
			if e_health and e_health.is_dead: continue
		
		var d = global_position.distance_to(e.global_position)
		if d < min_dist:
			min_dist = d
			nearest = e
	return nearest

func _start_cast(is_healing: bool) -> void:
	is_casting = true
	cast_timer = cast_duration
	next_projectile_is_heal = is_healing
	
	if animator:
		animator.play("Idle") 
		animator.set_speed(0.5) 

func _update_aim() -> void:
	if not health or health.is_dead or not is_inside_tree(): return
	var target = player_node if next_projectile_is_heal else _find_nearest_enemy()
	if is_instance_valid(target):
		var look_pos = Vector3(target.global_position.x, global_position.y, target.global_position.z)
		pending_target_pos = target.global_position + Vector3.UP * (0.8 if next_projectile_is_heal else 0.5)
		if global_position.distance_to(look_pos) > 0.1:
			look_at(look_pos, Vector3.UP)

func _complete_cast() -> void:
	if not health or health.is_dead or not is_inside_tree(): return
	is_casting = false
	current_mana -= mana_cost_spell
	
	if animator:
		animator.set_speed(1.0)
	
	var parent = get_parent()
	if not parent: return
	
	var spawn_pos = global_position + Vector3.UP * 1.0 - global_transform.basis.z * 1.2
	var fire_dir = (pending_target_pos - spawn_pos).normalized()

	var proj = spell_scene.instantiate()
	proj.set("caster", self)
	proj.set("is_healing", next_projectile_is_heal)
	if next_projectile_is_heal:
		proj.set("speed", 35.0) 
		proj.set("heal_amount", 30)
	
	parent.add_child(proj)
	proj.global_position = spawn_pos
	proj.set("direction", fire_dir)

func take_damage(amount: int, attacker: Node3D = null) -> void:
	if health:
		health.take_damage(amount, attacker)

func heal(amount: int) -> void:
	if health:
		health.heal(amount)

# Signal Callbacks
func _on_damage_taken(amount: int, _is_blocked: bool) -> void:
	EventBus.damage_triggered.emit(global_position + Vector3.UP * 2.0, amount, Color.RED)

func _on_healed(amount: int) -> void:
	EventBus.heal_triggered.emit(global_position + Vector3.UP * 2.0, amount)

func _on_died(_attacker: Node3D) -> void:
	queue_free()
