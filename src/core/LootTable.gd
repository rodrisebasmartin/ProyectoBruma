extends Resource
class_name LootTable

@export var drops: Array[LootDrop] = []

func get_random_loot() -> Array:
	var results = []
	for drop in drops:
		if not drop or not drop.item: continue
		if randf() <= drop.chance:
			results.append({
				"item": drop.item,
				"amount": randi_range(drop.min_amount, drop.max_amount)
			})
	return results
