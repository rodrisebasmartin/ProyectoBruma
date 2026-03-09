extends Node
class_name StatsComponent

signal level_up(new_level: int)
signal experience_gained(amount: int, current: int, total_needed: int)
signal gold_changed(total: int)
signal stats_changed() # For UI updates

@export_group("Base Stats")
@export var level: int = 1
@export var gold: int = 0
@export var experience: int = 0
@export var experience_needed: int = 100
@export var stat_points: int = 0

@export_group("RPG Attributes")
@export var strength: int = 10
@export var intelligence: int = 10
@export var dexterity: int = 10
@export var constitution: int = 10

# Modifiers from equipment
var bonus_damage: int = 0
var bonus_defense: int = 0

func get_total_attack() -> int:
	# Formula: STR * 1.5 + Weapon Bonus
	return int(float(strength) * 1.5) + bonus_damage

func get_total_defense() -> int:
	# Formula: CON * 0.8 + Armor Bonus
	return int(float(constitution) * 0.8) + bonus_defense

func update_equipment_bonuses(dmg: int, def: int) -> void:
	bonus_damage = dmg
	bonus_defense = def
	stats_changed.emit()
	print("[Stats] Equipment updated: Bonus DMG=%d, Bonus DEF=%d" % [bonus_damage, bonus_defense])

func add_experience(amount: int) -> void:
	experience += amount
	while experience >= experience_needed:
		_perform_level_up()
	experience_gained.emit(amount, experience, experience_needed)

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

func spend_stat_point(attribute: String) -> bool:
	if stat_points <= 0: return false
	
	match attribute.to_lower():
		"strength": strength += 1
		"intelligence": intelligence += 1
		"dexterity": dexterity += 1
		"constitution": constitution += 1
		_: return false
		
	stat_points -= 1
	stats_changed.emit()
	return true

func _perform_level_up() -> void:
	level += 1
	experience -= experience_needed
	experience_needed = int(experience_needed * 1.5)
	
	# Earn points instead of auto-increasing everything
	stat_points += 5 
	
	level_up.emit(level)
	stats_changed.emit()
	print("[Stats] Level Up! Now level %d. Points earned: 5" % level)
