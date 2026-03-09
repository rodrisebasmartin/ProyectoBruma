extends Resource
class_name LootDrop

@export var item: ItemData
@export var chance: float = 0.5 # 0.0 to 1.0
@export var min_amount: int = 1
@export var max_amount: int = 1
