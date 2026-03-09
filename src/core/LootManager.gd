extends Node

# Database of all items (for syncing and saving)
var item_database: Dictionary = {}
var affixes: Array[Affix] = []

# PackedScene of DroppedItem
var dropped_item_scene: PackedScene = preload("res://src/entities/world/DroppedItem.tscn")

func _ready() -> void:
	_load_database()
	_setup_affixes()

func _setup_affixes() -> void:
	# Create some basic affixes dynamically or load from resources
	var stats = [
		[Affix.StatType.HP, "of the Whale", 10, 30],
		[Affix.StatType.DAMAGE, "Sharp", 2, 8],
		[Affix.StatType.DEFENSE, "Sturdy", 2, 8],
		[Affix.StatType.STRENGTH, "Strong", 1, 5]
	]
	
	for s in stats:
		var a = Affix.new()
		a.stat = s[0]
		a.name = s[1]
		a.min_value = s[2]
		a.max_value = s[3]
		affixes.append(a)

func _load_database() -> void:
	# Scan the items folder for .tres files
	var dir = DirAccess.open("res://assets/items/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var item = load("res://assets/items/" + file_name)
				if item is ItemData:
					item_database[item.id] = item
					print("[LootManager] Loaded item: ", item.id)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		printerr("[LootManager] Could not open items directory!")

func get_item_by_id(id: String) -> ItemData:
	return item_database.get(id)

func get_affix_by_name(a_name: String) -> Affix:
	for a in affixes:
		if a.name == a_name:
			return a
	return null

func spawn_loot(loot_list: Array, position: Vector3) -> void:
	for loot in loot_list:
		var base_item = loot.item as ItemData
		
		# 1. Roll for rarity
		var rolled_rarity = _roll_rarity()
		
		# 2. Create Instance
		var inst = ItemInstance.new()
		inst.base_item = base_item
		inst.rarity = rolled_rarity
		inst.amount = loot.amount
		
		# 3. Roll Affixes for non-common items
		if rolled_rarity != ItemData.Rarity.COMMON:
			_roll_affixes(inst)

		# 4. Spawn dropped item
		var dropped = dropped_item_scene.instantiate()
		dropped.set("item_instance", inst) # Use the new instance
		
		get_tree().root.add_child(dropped)
		dropped.global_position = position + Vector3(randf_range(-1, 1), 0.5, randf_range(-1, 1))

func _roll_rarity() -> ItemData.Rarity:
	var roll = randf()
	if roll < 0.02: return ItemData.Rarity.LEGENDARY
	if roll < 0.07: return ItemData.Rarity.EPIC
	if roll < 0.15: return ItemData.Rarity.RARE
	if roll < 0.35: return ItemData.Rarity.UNCOMMON
	return ItemData.Rarity.COMMON

func _roll_affixes(inst: ItemInstance) -> void:
	var num_to_roll = 0
	match inst.rarity:
		ItemData.Rarity.UNCOMMON: num_to_roll = 1
		ItemData.Rarity.RARE: num_to_roll = 2
		ItemData.Rarity.EPIC: num_to_roll = 3
		ItemData.Rarity.LEGENDARY: num_to_roll = 4
	
	var available = affixes.duplicate()
	available.shuffle()
	
	for i in range(min(num_to_roll, available.size())):
		var affix = available[i]
		inst.affixes.append({
			"affix": affix,
			"value": affix.get_random_value()
		})
