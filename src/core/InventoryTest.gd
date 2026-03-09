extends Node

func _ready() -> void:
	await get_tree().create_timer(1.0).timeout
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var inventory = player.get_node_or_null("InventoryComponent")
		if inventory:
			var potion_data = load("res://assets/items/health_potion.tres")
			var pelt_data = load("res://assets/items/wolf_pelt.tres")
			var sword_data = load("res://assets/items/iron_sword.tres")
			
			if potion_data:
				var inst = ItemInstance.new()
				inst.base_item = potion_data
				inst.amount = 3
				inventory.add_item_instance(inst)
				
			if pelt_data:
				var inst = ItemInstance.new()
				inst.base_item = pelt_data
				inst.amount = 5
				inventory.add_item_instance(inst)
				
			if sword_data:
				var inst = ItemInstance.new()
				inst.base_item = sword_data
				inst.amount = 1
				# Give the sword a random rarity for testing
				inst.rarity = ItemData.Rarity.RARE
				inventory.add_item_instance(inst)
			
			print("[Test] ItemInstances added to player inventory.")
