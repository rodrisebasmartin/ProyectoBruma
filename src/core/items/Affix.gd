extends Resource
class_name Affix

enum StatType { HP, MANA, STRENGTH, INTELIGENCE, DEXTERITY, DAMAGE, DEFENSE, CRIT_CHANCE }

@export var name: String = "of the Whale"
@export var stat: StatType = StatType.HP
@export var min_value: int = 5
@export var max_value: int = 15
@export var level_requirement: int = 1

func get_random_value() -> int:
	return randi_range(min_value, max_value)

func apply_to_stats(stats: Dictionary, value: int) -> void:
	match stat:
		StatType.HP: stats["max_health"] = stats.get("max_health", 0) + value
		StatType.DAMAGE: stats["damage_bonus"] = stats.get("damage_bonus", 0) + value
		StatType.DEFENSE: stats["defense_bonus"] = stats.get("defense_bonus", 0) + value
		StatType.STRENGTH: stats["strength"] = stats.get("strength", 0) + value
		# ... add others as needed
