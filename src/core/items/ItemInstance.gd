extends Resource
class_name ItemInstance

## ItemInstance: A specific version of an ItemData (Diablo-style)
## Stores unique rolls, affixes, and durability.

@export var base_item: ItemData
@export var rarity: ItemData.Rarity = ItemData.Rarity.COMMON
@export var affixes: Array[Dictionary] = [] # List of { "affix": Affix, "value": int }
@export var amount: int = 1
@export var level: int = 1

# Display Name (e.g. "Fiery Iron Sword of the Whale")
func get_display_name() -> String:
	if not base_item: return "Unknown"
	
	var prefix = ""
	var suffix = ""
	
	for a_data in affixes:
		var a = a_data["affix"] as Affix
		if a.name.begins_with("of"):
			suffix = " " + a.name
		else:
			prefix = a.name + " "
			
	return prefix + base_item.name + suffix

func get_rarity_color() -> Color:
	match rarity:
		ItemData.Rarity.COMMON: return Color.GRAY
		ItemData.Rarity.UNCOMMON: return Color.GREEN
		ItemData.Rarity.RARE: return Color.BLUE
		ItemData.Rarity.EPIC: return Color.PURPLE
		ItemData.Rarity.LEGENDARY: return Color.ORANGE
	return Color.WHITE

func get_total_stats() -> Dictionary:
	var stats = {
		"damage": base_item.damage_bonus,
		"defense": base_item.defense_bonus,
		"hp": base_item.health_restore,
		"mana": base_item.mana_restore,
		"bonus_str": 0,
		"bonus_dmg": 0,
		"bonus_def": 0
	}
	
	for a_data in affixes:
		var a = a_data["affix"] as Affix
		var val = a_data["value"]
		
		match a.stat:
			Affix.StatType.HP: stats["hp"] += val
			Affix.StatType.DAMAGE: stats["bonus_dmg"] += val
			Affix.StatType.DEFENSE: stats["bonus_def"] += val
			Affix.StatType.STRENGTH: stats["bonus_str"] += val
			# ... handle others
			
	return stats

# Returns a dictionary of stat differences (this - other)
func compare_stats(other: ItemInstance) -> Dictionary:
	var my_stats = get_total_stats()
	var other_stats = {
		"damage": 0, "defense": 0, "hp": 0, "mana": 0,
		"bonus_str": 0, "bonus_dmg": 0, "bonus_def": 0
	}
	
	if other:
		other_stats = other.get_total_stats()
		
	var diff = {}
	for key in my_stats.keys():
		diff[key] = my_stats[key] - other_stats[key]
		
	return diff

# Helper to create a new instance with random rolls
static func create_random(base: ItemData, p_rarity: ItemData.Rarity) -> ItemInstance:
	var inst = ItemInstance.new()
	inst.base_item = base
	inst.rarity = p_rarity
	
	# Logic for rolling affixes would go here (requires an Affix database)
	return inst
