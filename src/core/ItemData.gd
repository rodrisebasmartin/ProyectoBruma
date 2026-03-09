extends Resource
class_name ItemData

enum ItemType { CONSUMABLE, WEAPON, ARMOR, SHIELD, MISC }
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

@export_group("Identity")
@export var id: String = "item_001"
@export var name: String = "New Item"
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var item_type: ItemType = ItemType.MISC
@export var rarity: Rarity = Rarity.COMMON

@export_group("Visuals")
@export var world_model: PackedScene # Model for when it's on the ground

@export_group("Stats")
@export var weight: float = 1.0
@export var value: int = 10
@export var stackable: bool = false
@export var max_stack: int = 99

@export_group("Combat/RPG Effects")
@export var health_restore: int = 0
@export var mana_restore: int = 0
@export var damage_bonus: int = 0
@export var defense_bonus: int = 0

func use(_target: Node) -> bool:
	# Virtual function to be overridden by specific items
	# Returns true if the item was consumed
	print("Using item: ", name)
	return false
