extends CharacterBody3D

enum AIState { IDLE, WANDER, CHASE, ATTACK, STAGGER, DEAD }

@export_group("Stats")
@export var max_health: int = 30
@export var enemy_name: String = "Wolf"
@export var move_speed: float = 2.0
@export var chase_speed: float = 4.0
@export var damage: int = 5
@export var max_poise: float = 30.0 

@export_group("AI Settings")
@export var detection_radius: float = 8.0
@export var wander_radius: float = 5.0
@export var attack_range: float = 1.8
@export var attack_cooldown: float = 1.5

@export_group("Rewards")
@export var exp_reward: int = 25
@export var gold_reward: int = 15
@export var loot_table: Resource # LootTable

var current_poise: float
var current_state: AIState = AIState.IDLE
var target_player: CharacterBody3D = null
var wander_target: Vector3
var state_timer: float = 0.0
var attack_timer: float = 0.0
var is_attacking: bool = false
var attack_hitbox: ShapeCast3D
var is_targeted: bool = false: set = set_targeted
var threat_table: Dictionary = {}

@onready var selection_ring: MeshInstance3D
@onready var animation_player: AnimationPlayer = $Model/AnimationPlayer
@onready var animator: CharacterAnimator = get_node_or_null("CharacterAnimator")
@onready var health: HealthComponent = $HealthComponent
@onready var stats: StatsComponent = $StatsComponent

signal died(spawn_pos: Vector3, rewards: Dictionary)

func _ready() -> void:
	health.set_max_health(max_health)
	current_poise = max_poise
	
	health.died.connect(_on_died)
	health.damage_taken.connect(_on_damage_taken)
	
	# Layer 4: Enemies
	collision_layer = 4
	# Mask: Player(1), World(2), Ally(8)
	collision_mask = 1 | 2 | 8 
	input_ray_pickable = true
	
	if is_instance_valid($Model):
		var plane_node = $Model.get_node_or_null("Plane")
		if plane_node: plane_node.queue_free()

		$Model.scale = Vector3(200, 200, 200) 
		$Model.rotation_degrees.x = 0
		$Model.visible = true
		
		# Recalculate grounding after scaling
		if animator:
			animator._perform_auto_ground()
		
	_setup_hitbox()
	_setup_selection_ring()
	_add_minimap_icon()
	_pick_new_wander_target()

func _add_minimap_icon() -> void:
	var icon = MinimapIcon.new()
	icon.color = Color.RED
	icon.size = 2.5
	add_child(icon)
	
	if animator:
		animator.play("Idle")

func _setup_selection_ring() -> void:
	selection_ring = MeshInstance3D.new()
	selection_ring.name = "SelectionRing"
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.8
	cylinder.bottom_radius = 0.8
	cylinder.height = 0.05
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 1, 0, 0.5) 
	mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	selection_ring.mesh = cylinder
	selection_ring.material_override = mat
	add_child(selection_ring)
	selection_ring.position = Vector3(0, 0.02, 0)
	selection_ring.visible = false

func set_targeted(value: bool) -> void:
	is_targeted = value
	if selection_ring:
		selection_ring.visible = is_targeted

func _physics_process(delta: float) -> void:
	if health.is_dead: return

	# Apply Gravity
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0

	if current_state != AIState.STAGGER:
		current_poise = min(current_poise + 5.0 * delta, max_poise)
	attack_timer -= delta
	_update_ai_state(delta)
	
	if not is_attacking and current_state != AIState.STAGGER:
		_apply_movement(delta)
		_update_animations(delta)
	elif current_state == AIState.STAGGER:
		velocity = velocity.move_toward(Vector3.ZERO, 20.0 * delta)
		move_and_slide()

func _update_animations(delta: float) -> void:
	if not animation_player: return
	if is_attacking or current_state == AIState.STAGGER: return
	
	if velocity.length() > 0.1:
		_play_animation("Walk")
		var speed_scale = (velocity.length() / move_speed) * 2.5
		animation_player.speed_scale = lerp(animation_player.speed_scale, speed_scale, 10.0 * delta)
	else:
		_play_animation("Idle")
		animation_player.speed_scale = lerp(animation_player.speed_scale, 1.0, 10.0 * delta)

func _play_animation(anim_name: String) -> void:
	if not animation_player: return
	if animation_player.current_animation.to_lower() == anim_name.to_lower() and animation_player.is_playing(): return
	
	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name, 0.2)
	else:
		for full_name in animation_player.get_animation_list():
			if anim_name.to_lower() in full_name.to_lower():
				animation_player.play(full_name, 0.2)
				return

func _update_target() -> void:
	var max_threat = -1.0
	var best_target = null
	
	# 1. Clean up invalid keys
	var to_remove = []
	for entity in threat_table:
		if not is_instance_valid(entity) or (entity.has_method("get_is_dead") and entity.get_is_dead()):
			to_remove.append(entity)
			continue
			
		if threat_table[entity] > max_threat:
			max_threat = threat_table[entity]
			best_target = entity
	
	for entity in to_remove:
		threat_table.erase(entity)
	
	# 2. If no threat, find closest player
	if not best_target:
		var players = get_tree().get_nodes_in_group("player")
		var min_dist = detection_radius
		for p in players:
			if p.has_method("get_is_dead") and p.get_is_dead(): continue
			var d = global_position.distance_to(p.global_position)
			if d < min_dist:
				min_dist = d
				best_target = p
	
	target_player = best_target

func _update_ai_state(delta: float) -> void:
	if current_state == AIState.STAGGER: return
	
	_update_target()
	
	if not target_player:
		if current_state == AIState.CHASE or current_state == AIState.ATTACK:
			current_state = AIState.IDLE
		# Keep wandering or idling
	else:
		var dist = global_position.distance_to(target_player.global_position)
		match current_state:
			AIState.IDLE, AIState.WANDER:
				if dist < detection_radius:
					current_state = AIState.CHASE
			AIState.CHASE:
				if dist < attack_range:
					current_state = AIState.ATTACK
				elif dist > detection_radius * 2.0: # Lost interest
					current_state = AIState.IDLE
					target_player = null
					_pick_new_wander_target()
			AIState.ATTACK:
				if dist > attack_range * 1.2:
					current_state = AIState.CHASE

	state_timer -= delta
	match current_state:
		AIState.IDLE:
			if state_timer <= 0:
				current_state = AIState.WANDER
				state_timer = randf_range(2.0, 4.0)
		AIState.WANDER:
			if global_position.distance_to(wander_target) < 0.5 or state_timer <= 0:
				current_state = AIState.IDLE
				state_timer = randf_range(1.0, 3.0)
				_pick_new_wander_target()
		AIState.ATTACK:
			if attack_timer <= 0:
				_perform_attack()

func _perform_attack() -> void:
	if not target_player or health.is_dead or is_attacking or current_state == AIState.STAGGER: return
	is_attacking = true
	attack_timer = attack_cooldown
	
	_play_animation("Attack")
	animation_player.speed_scale = 1.2
	
	await get_tree().create_timer(0.4).timeout
	
	if health.is_dead or current_state == AIState.STAGGER: 
		is_attacking = false
		return
		
	if is_instance_valid(target_player):
		var dir = global_position.direction_to(target_player.global_position)
		velocity = dir * 2.0 
	
	attack_hitbox.enabled = true
	attack_hitbox.force_shapecast_update()
	if attack_hitbox.is_colliding():
		for i in range(attack_hitbox.get_collision_count()):
			var collider = attack_hitbox.get_collider(i)
			if collider and collider.has_method("take_damage"):
				collider.take_damage(damage, self)
	
	await get_tree().create_timer(0.1).timeout
	attack_hitbox.enabled = false
	
	await get_tree().create_timer(0.4).timeout
	is_attacking = false

func _apply_movement(delta: float) -> void:
	var direction := Vector3.ZERO
	match current_state:
		AIState.CHASE:
			if target_player:
				direction = global_position.direction_to(target_player.global_position)
				velocity = direction * chase_speed
		AIState.WANDER:
			direction = global_position.direction_to(wander_target)
			velocity = direction * move_speed
		AIState.IDLE, AIState.ATTACK:
			velocity = velocity.move_toward(Vector3.ZERO, 10.0 * delta)
	if direction.length() > 0.1:
		var target_angle = atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, 5.0 * delta)
	move_and_slide()

func _pick_new_wander_target() -> void:
	var random_offset = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized() * wander_radius
	wander_target = global_position + random_offset

func take_damage(amount: int, attacker: Node3D = null) -> void:
	health.take_damage(amount, attacker)
	
	if is_instance_valid(attacker):
		var current_threat = threat_table.get(attacker, 0)
		threat_table[attacker] = current_threat + amount
		
		# Immediate reaction if idle/wander
		if current_state == AIState.IDLE or current_state == AIState.WANDER:
			_update_target()
			if target_player:
				current_state = AIState.CHASE

func _on_damage_taken(amount: int, _is_blocked: bool) -> void:
	var knock_origin = get_tree().get_first_node_in_group("player")
	if knock_origin:
		var knock_dir = knock_origin.global_position.direction_to(global_position)
		velocity = knock_dir * 8.0 
	
	current_poise -= amount 
	EventBus.damage_triggered.emit(global_position + Vector3.UP * 2.5, amount, Color.YELLOW)
	if SoundManager: SoundManager.play_hit_sound(global_position)
	if current_poise <= 0: _trigger_stagger()

func _trigger_stagger() -> void:
	current_state = AIState.STAGGER
	is_attacking = false
	current_poise = max_poise 
	_play_animation("Hit")
	animation_player.speed_scale = 1.0
	
	await get_tree().create_timer(0.8).timeout 
	if not health.is_dead:
		current_state = AIState.CHASE

func _on_died(attacker: Node3D) -> void:
	current_state = AIState.DEAD
	var rewards = {"exp": exp_reward, "gold": gold_reward}
	
	if is_instance_valid(attacker) and attacker.has_method("gain_rewards"):
		attacker.gain_rewards(rewards)
	
	if QuestManager:
		QuestManager.track_kill(enemy_name)
	
	EventBus.enemy_died.emit(enemy_name, global_position)
	
	# Spawn Loot
	if loot_table and LootManager:
		var drops = loot_table.get_random_loot()
		LootManager.spawn_loot(drops, global_position)
	
	_play_animation("Die")
	died.emit(global_position, rewards)
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _setup_hitbox() -> void:
	attack_hitbox = ShapeCast3D.new()
	attack_hitbox.name = "AttackHitbox"
	var shape = BoxShape3D.new()
	shape.size = Vector3(2.0, 2.0, 2.0)
	attack_hitbox.shape = shape
	attack_hitbox.target_position = Vector3(0, 0, -1.5)
	attack_hitbox.collision_mask = 1 | 8 
	attack_hitbox.enabled = false
	add_child(attack_hitbox)
	attack_hitbox.position = Vector3(0, 1.0, 0)
