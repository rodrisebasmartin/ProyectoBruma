extends Node3D
class_name HealthComponent

signal health_changed(current: int, max_val: int)
signal damage_taken(amount: int, is_blocked: bool)
signal healed(amount: int)
signal died(attacker: Node3D)

@export var max_health: int = 100
@onready var current_health: int = max_health

var is_dead: bool = false

func take_damage(amount: int, attacker: Node3D = null, is_blocking: bool = false, parry_active: bool = false) -> void:
	if is_dead: return
	
	# Parry Logic (0 damage + stagger)
	if parry_active:
		damage_taken.emit(0, false)
		if attacker and attacker.has_method("_trigger_stagger"):
			attacker._trigger_stagger()
		return

	var final_damage = amount
	var was_blocked = false
	
	if is_blocking:
		final_damage = int(amount * 0.3) # 70% reduction
		was_blocked = true
	
	current_health -= final_damage
	health_changed.emit(current_health, max_health)
	damage_taken.emit(final_damage, was_blocked)
	
	if current_health <= 0:
		_die(attacker)

func heal(amount: int) -> void:
	if is_dead: return
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)
	healed.emit(amount)

func _die(attacker: Node3D) -> void:
	if is_dead: return
	is_dead = true
	died.emit(attacker)

func set_max_health(new_max: int, refill: bool = true) -> void:
	max_health = new_max
	if refill:
		current_health = max_health
	else:
		current_health = min(current_health, max_health)
	health_changed.emit(current_health, max_health)
