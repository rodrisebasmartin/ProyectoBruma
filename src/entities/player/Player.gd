extends CharacterBody3D

enum PlayerClass { WARRIOR, MAGE, PALADIN, CLERIC }

@export_group("Class Settings")
@export var current_class: PlayerClass = PlayerClass.WARRIOR

@export_group("Movement")
@export var speed: float = 6.0
@export var acceleration: float = 15.0
@export var rotation_speed: float = 12.0
@export var dodge_force: float = 20.0 
@export var dodge_cooldown: float = 1.5 

@export_group("Combat")
@export var attack_cooldown: float = 0.2
@export var base_damage: int = 15
@export var stamina_cost_attack: float = 20.0
@export var stamina_cost_dodge: float = 25.0
@export var stamina_cost_block_hit: float = 15.0

@export_group("Magic")
@export var spell_bolt_scene: PackedScene = preload("res://src/entities/player/SpellProjectile.tscn")
@export var lightning_spell_scene: PackedScene = preload("res://src/entities/player/LightningSpell.tscn")
@export var target_indicator_scene: PackedScene = preload("res://src/ui/TargetIndicator.tscn")
@export var mana_cost_spell: float = 15.0
@export var mana_cost_lightning: float = 30.0
@export var cast_duration: float = 0.8 

@export_group("RPG Stats (Read Only)")
var max_mana: float = 100.0
var max_stamina: float = 100.0
var current_mana: float 
var current_stamina: float
var mana_regen: float = 5.0
var stamina_regen: float = 15.0

var is_attacking: bool = false
var is_dodging: bool = false
var is_casting: bool = false
var is_blocking: bool = false
var is_parrying: bool = false
var is_dead: bool = false: get = get_is_dead

# Interaction Logic
var current_interactable: Interactable = null

# Internal Logic
var current_spell_index: int = 0 # 0: Bolt, 1: Lightning
var spell_ready: bool = false
var target_indicator: Node3D
var pending_spell_target: Vector3

# Timers
var attack_buffer_timer: float = 0.0
var cooldown_timer: float = 0.0
var dodge_cooldown_timer: float = 0.0
var cast_timer: float = 0.0
var parry_window_timer: float = 0.0
const ATTACK_BUFFER_TIME: float = 0.2
const PARRY_WINDOW: float = 0.2 

# Components
@onready var health: HealthComponent = $HealthComponent
@onready var stats: StatsComponent = $StatsComponent
@onready var animator: CharacterAnimator = $CharacterAnimator
@onready var inventory: Node = $InventoryComponent # InventoryComponent
@onready var equipment: Node = $EquipmentComponent # EquipmentComponent
@onready var hitbox: ShapeCast3D = %Hitbox
@onready var interact_ray: RayCast3D = $InteractRay

var input: InputComponent

func _ready() -> void:
	# 0. Setup Input
	input = InputComponent.new()
	input.name = "InputComponent"
	add_child(input)

	# 1. Apply base class stats first
	_apply_class_stats()
	
	# 2. LOAD persistent data from GameManager
	if GameManager:
		GameManager.load_player(self)
	
	add_to_group("player")
	add_to_group("allies")
	
	# Connect component signals
	health.died.connect(_on_died)
	health.damage_taken.connect(_on_damage_taken)
	health.healed.connect(_on_healed)
	stats.level_up.connect(_on_level_up)
	
	# Initial Equipment stat update
	if equipment: equipment._update_stats()
	
	# Layer 1: Player
	collision_layer = 1
	collision_mask = 2 | 4 
	
	_setup_target_indicator()
	_setup_interact_ray()
	_add_minimap_icon()
	animator.play("Idle")

func _add_minimap_icon() -> void:
	var icon = MinimapIcon.new()
	icon.color = Color.WHITE
	icon.size = 3.0
	add_child(icon)

func _setup_interact_ray() -> void:
	if not interact_ray:
		interact_ray = RayCast3D.new()
		interact_ray.name = "InteractRay"
		add_child(interact_ray)
	
	interact_ray.target_position = Vector3(0, 0, -2.5) # Front is -Z, longer distance to hit NPC backs
	interact_ray.hit_from_inside = true
	interact_ray.position.y = 1.0
	interact_ray.enabled = true
	interact_ray.collision_mask = 32 # Layer 6: Interactables
	interact_ray.collide_with_areas = true
	interact_ray.collide_with_bodies = false

func get_is_dead() -> bool:
	if not health: return false
	return health.is_dead

func _apply_class_stats() -> void:
	match current_class:
		PlayerClass.WARRIOR:
			health.set_max_health(150)
			max_stamina = 120
			max_mana = 50
			mana_regen = 2.0
			base_damage = 20
		PlayerClass.MAGE:
			health.set_max_health(80)
			max_stamina = 80
			max_mana = 200
			mana_regen = 12.0
			base_damage = 10
		PlayerClass.PALADIN:
			health.set_max_health(120)
			max_stamina = 100
			max_mana = 100
			mana_regen = 5.0
			base_damage = 15
		PlayerClass.CLERIC:
			health.set_max_health(90)
			max_stamina = 90
			max_mana = 180
			mana_regen = 8.0
			base_damage = 12
	
	current_stamina = max_stamina
	current_mana = max_mana

func _handle_actions() -> void:
	if is_dead: return
	
	if input.interact_triggered:
		_handle_interaction()

	if input.is_casting_spell_1:
		current_spell_index = 0
		spell_ready = !spell_ready
		target_indicator.visible = spell_ready
	
	if input.is_casting_spell_2:
		current_spell_index = 1
		spell_ready = !spell_ready
		target_indicator.visible = spell_ready
	
	if spell_ready and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): 
		var cost = mana_cost_spell if current_spell_index == 0 else mana_cost_lightning
		if current_mana >= cost and not is_casting:
			_start_casting()

	if input.is_blocking and not is_attacking and not is_dodging:
		if not is_blocking: _start_blocking()
	elif not input.is_blocking and is_blocking:
		_stop_blocking()

func _handle_interaction() -> void:
	if is_instance_valid(current_interactable):
		current_interactable.interact(self)

func _physics_process(delta: float) -> void:
	if is_dead: return
	
	_handle_actions()

	# Apply Gravity
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0

	_update_interactable()

	attack_buffer_timer -= delta
	cooldown_timer -= delta
	dodge_cooldown_timer -= delta
	parry_window_timer -= delta

	if is_casting:
		cast_timer -= delta
		if cast_timer <= 0:
			_complete_casting()

	if parry_window_timer <= 0:
		is_parrying = false

	if spell_ready:
		_update_target_indicator()

	# Continuous Regeneration
	if not is_casting:
		current_mana = min(current_mana + mana_regen * delta, max_mana)
	
	if not is_attacking and not is_dodging and not is_casting and not is_blocking:
		current_stamina = min(current_stamina + stamina_regen * delta, max_stamina)

	if input.is_attacking and not spell_ready and not is_blocking:
		attack_buffer_timer = ATTACK_BUFFER_TIME

	if input.is_dodging and not is_dodging and not is_attacking and dodge_cooldown_timer <= 0:
		if current_stamina >= stamina_cost_dodge:
			_cancel_cast()
			_stop_blocking()
			_perform_dodge()

	if attack_buffer_timer > 0 and not is_attacking and not is_dodging and not is_casting and not is_blocking and cooldown_timer <= 0:
		if current_stamina >= stamina_cost_attack:
			_perform_attack()
			attack_buffer_timer = 0

	if is_attacking or is_dodging or is_casting or is_blocking:
		var friction_mult = 4.0 if is_attacking else 3.0
		velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta * friction_mult)
		move_and_slide()
		return

	_handle_movement(delta)

func _update_interactable() -> void:
	if interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		if collider is Interactable:
			current_interactable = collider
		else:
			current_interactable = null
	else:
		current_interactable = null

func _handle_movement(delta: float) -> void:
	var input_dir: Vector2 = input.move_dir
	var view_dir: Vector3 = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, deg_to_rad(45))
	
	if view_dir.length() > 0:
		velocity.x = lerp(velocity.x, view_dir.x * speed, acceleration * delta)
		velocity.z = lerp(velocity.z, view_dir.z * speed, acceleration * delta)
		
		# Standard Godot: -Z is forward. atan2(x, z) points +Z. To point -Z, we use atan2(-x, -z)
		var target_rotation: float = atan2(-view_dir.x, -view_dir.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)
		
		animator.play("Walk") 
		var speed_percent = velocity.length() / speed
		animator.set_speed(speed_percent * 1.2)
	else:
		_apply_friction(delta)
		animator.play("Idle")
		animator.set_speed(1.0)
	move_and_slide()

func _apply_friction(delta: float) -> void:
	velocity = velocity.lerp(Vector3.ZERO, acceleration * delta)
	move_and_slide()

func _start_blocking() -> void:
	is_blocking = true
	is_parrying = true
	parry_window_timer = PARRY_WINDOW
	var tween = create_tween()
	# Rotate model slightly to show guard pose (offset from PI base)
	tween.tween_property($Model, "rotation:y", PI + deg_to_rad(30), 0.1)

func _stop_blocking() -> void:
	is_blocking = false
	is_parrying = false
	var tween = create_tween()
	tween.tween_property($Model, "rotation:y", PI, 0.1)

func _start_casting() -> void:
	var camera = get_viewport().get_camera_3d()
	if not camera: return
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_normal = camera.project_ray_normal(mouse_pos)
	var plane = Plane(Vector3.UP, 0)
	var target_point = plane.intersects_ray(ray_origin, ray_normal)
	if not target_point: target_point = global_position - global_transform.basis.z * 10.0

	pending_spell_target = target_point
	is_casting = true
	cast_timer = cast_duration
	spell_ready = false
	target_indicator.visible = false

	# Face target (-Z forward)
	var dir = global_position.direction_to(target_point)
	rotation.y = atan2(-dir.x, -dir.z)
	animator.play("Idle")

func _complete_casting() -> void:
	is_casting = false
	
	var tween = create_tween()
	tween.tween_property($Model, "scale", Vector3(1.2, 0.8, 1.2), 0.05)
	tween.chain().tween_property($Model, "scale", Vector3.ONE, 0.1)

	if current_spell_index == 0:
		current_mana -= mana_cost_spell
		var proj = spell_bolt_scene.instantiate()
		if current_class == PlayerClass.CLERIC:
			proj.set("is_healing", true)
			
		get_parent().add_child(proj)
		proj.set("caster", self)
		# Spawn in front (-Z)
		proj.global_position = global_position + Vector3.UP * 1.0 - global_transform.basis.z * 0.5
		var fire_dir = (pending_spell_target - proj.global_position).normalized()
		proj.direction = fire_dir
	elif current_spell_index == 1:
		current_mana -= mana_cost_lightning
		var spell = lightning_spell_scene.instantiate()
		get_parent().add_child(spell)
		spell.set("caster", self)
		spell.global_position = pending_spell_target

func _cancel_cast() -> void:
	is_casting = false
	cast_timer = 0

func _perform_attack() -> void:
	is_attacking = true
	current_stamina -= stamina_cost_attack
	cooldown_timer = attack_cooldown
	
	var punches = ["Punch1", "Punch2", "Punch3"]
	var selected_punch = punches[randi() % punches.size()]
	animator.set_speed(1.3)
	animator.play(selected_punch)
	
	# Small dash forward (-Z)
	velocity = -global_transform.basis.z * (speed * 0.5)
	await get_tree().create_timer(0.15).timeout 
	_check_hitbox()
	await get_tree().create_timer(0.5).timeout
	if is_attacking: is_attacking = false

func _check_hitbox() -> void:
	hitbox.enabled = true
	hitbox.force_shapecast_update()
	var hit_something = false
	
	# Total damage = Base + STR Bonus + Equipment Bonus
	var total_damage = base_damage + int(float(stats.strength) / 2.0) + stats.bonus_damage
	
	if hitbox.is_colliding():
		for i in range(hitbox.get_collision_count()):
			var collider = hitbox.get_collider(i)
			if collider and collider.has_method("take_damage"):
				collider.take_damage(total_damage, self)
				hit_something = true
	hitbox.enabled = false
	if hit_something and SoundManager: SoundManager.play_hit_sound(global_position)

func _perform_dodge() -> void:
	is_dodging = true
	dodge_cooldown_timer = dodge_cooldown
	current_stamina -= stamina_cost_dodge
	
	var input_dir = input.move_dir
	var dodge_dir: Vector3
	if input_dir.length() > 0.1:
		dodge_dir = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, deg_to_rad(45)).normalized()
		rotation.y = atan2(-dodge_dir.x, -dodge_dir.z) # Standard -Z forward
	else:
		dodge_dir = -global_transform.basis.z # Dodge current forward
	
	animator.play("Dodge")
	velocity = dodge_dir * dodge_force
	await get_tree().create_timer(0.6).timeout
	if is_dodging: is_dodging = false

func take_damage(amount: int, attacker: Node3D = null) -> void:
	if is_dodging: return
	# Reduce damage by equipment defense
	var actual_damage = max(1, amount - stats.bonus_defense)
	health.take_damage(actual_damage, attacker, is_blocking, is_parrying)

func heal(amount: int) -> void:
	health.heal(amount)

func gain_rewards(rewards: Dictionary) -> void:
	if rewards.has("exp"): stats.add_experience(rewards["exp"])
	if rewards.has("gold"): stats.add_gold(rewards["gold"])

# Signal Callbacks
func _on_damage_taken(amount: int, is_blocked: bool) -> void:
	var color = Color.RED if not is_blocked else Color.GRAY
	EventBus.damage_triggered.emit(global_position + Vector3.UP * 2.0, amount, color)
	
	if SoundManager: SoundManager.play_hit_sound(global_position)
	_cancel_cast()

func _on_healed(amount: int) -> void:
	EventBus.heal_triggered.emit(global_position + Vector3.UP * 2.0, amount)

func _on_died(_attacker: Node3D) -> void:
	is_attacking = false
	is_dodging = false
	is_casting = false
	is_blocking = false
	var tween = create_tween().set_parallel(true)
	tween.tween_property($Model, "rotation:x", deg_to_rad(-90), 0.5)
	tween.tween_property($Model, "position:y", -0.5, 0.5)
	await get_tree().create_timer(3.0).timeout
	_respawn()

func _on_level_up(new_level: int) -> void:
	EventBus.level_up_triggered.emit(global_position + Vector3.UP * 3.0, new_level)
	
	# Refill health on level up
	health.set_max_health(health.max_health + 10, true)

func _respawn() -> void:
	global_position = Vector3.ZERO 
	health.set_max_health(health.max_health, true)
	current_mana = max_mana
	current_stamina = max_stamina
	var tween = create_tween().set_parallel(true)
	tween.tween_property($Model, "rotation:x", 0.0, 0.1)
	tween.tween_property($Model, "position:y", 0.0, 0.1)
	animator.play("Idle")

func _setup_target_indicator() -> void:
	if target_indicator_scene:
		target_indicator = target_indicator_scene.instantiate()
		add_child(target_indicator)
		target_indicator.visible = false

func _update_target_indicator() -> void:
	var camera = get_viewport().get_camera_3d()
	if not camera: return
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var plane = Plane(Vector3.UP, 0)
	var intersection = plane.intersects_ray(ray_origin, camera.project_ray_normal(mouse_pos))
	if intersection:
		target_indicator.global_position = intersection + Vector3.UP * 0.1
		target_indicator.visible = true

func _on_animation_finished(anim_name: String) -> void:
	if "Punch" in anim_name or "Dodge" in anim_name:
		is_attacking = false
		is_dodging = false
		animator.set_speed(1.0)
		animator.play("Idle")
