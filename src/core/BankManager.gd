extends Node

signal bank_updated

var bank_gold: int = 0
var bank_inventory: InventoryComponent

func _ready() -> void:
	bank_inventory = InventoryComponent.new()
	bank_inventory.max_slots = 100
	bank_inventory.max_weight = 9999.0 # Banker has infinite storage!
	add_child(bank_inventory)
	
	bank_inventory.inventory_changed.connect(_on_bank_changed)

func deposit_gold(amount: int, player_stats: StatsComponent) -> void:
	if player_stats.gold >= amount:
		player_stats.add_gold(-amount)
		bank_gold += amount
		bank_updated.emit()
		print("[Bank] Deposited %d gold. Total: %d" % [amount, bank_gold])

func withdraw_gold(amount: int, player_stats: StatsComponent) -> void:
	if bank_gold >= amount:
		bank_gold -= amount
		player_stats.add_gold(amount)
		bank_updated.emit()
		print("[Bank] Withdrew %d gold. Remaining: %d" % [amount, bank_gold])

func deposit_item(slot_index: int, player_inventory: InventoryComponent) -> void:
	var slot = player_inventory.slots[slot_index]
	if slot:
		var remaining = bank_inventory.add_item(slot.item, slot.amount)
		if remaining == 0:
			player_inventory.remove_item_at(slot_index, slot.amount)
		elif remaining < slot.amount:
			player_inventory.remove_item_at(slot_index, slot.amount - remaining)
		bank_updated.emit()

func withdraw_item(bank_slot_index: int, player_inventory: InventoryComponent) -> void:
	var slot = bank_inventory.slots[bank_slot_index]
	if slot:
		var remaining = player_inventory.add_item(slot.item, slot.amount)
		if remaining == 0:
			bank_inventory.remove_item_at(bank_slot_index, slot.amount)
		elif remaining < slot.amount:
			bank_inventory.remove_item_at(bank_slot_index, slot.amount - remaining)
		bank_updated.emit()

func _on_bank_changed() -> void:
	bank_updated.emit()
