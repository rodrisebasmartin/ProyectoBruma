extends Node
class_name InventoryComponent

## InventoryComponent: Handles ItemInstances (Solo/Co-op)
## Supports stacking, weight, and persistence of unique item rolls.

signal inventory_changed
signal item_added(instance: ItemInstance)

@export var max_slots: int = 24
@export var max_weight: float = 50.0

var slots: Array[ItemInstance] = [] # Changed from InventorySlot to ItemInstance
var current_weight: float = 0.0

func _ready() -> void:
	slots.resize(max_slots)

func add_item_instance(inst: ItemInstance) -> bool:
	if not inst: return false
	
	# 1. Try to stack if stackable
	if inst.base_item.stackable:
		for slot in slots:
			if slot and slot.base_item.id == inst.base_item.id:
				# Check for same affixes (Diablo style: usually only whites stack, 
				# but for simplicity we'll only stack if affixes match exactly)
				if slot.affixes == inst.affixes:
					var space = inst.base_item.max_stack - slot.amount
					var to_add = min(space, inst.amount)
					slot.amount += to_add
					inst.amount -= to_add
					if inst.amount <= 0:
						_on_inventory_updated()
						return true

	# 2. Find empty slot
	if inst.amount > 0:
		for i in range(slots.size()):
			if slots[i] == null:
				slots[i] = inst
				_on_inventory_updated()
				item_added.emit(inst)
				return true
				
	return false

func remove_at(index: int, amount: int = 1) -> void:
	if index < 0 or index >= slots.size() or not slots[index]: return
	
	slots[index].amount -= amount
	if slots[index].amount <= 0:
		slots[index] = null
	
	_on_inventory_updated()

func _on_inventory_updated() -> void:
	_recalculate_weight()
	inventory_changed.emit()

func _recalculate_weight() -> void:
	current_weight = 0.0
	for slot in slots:
		if slot:
			current_weight += slot.base_item.weight * slot.amount

# Persistence
func get_save_data() -> Array:
	var data = []
	for slot in slots:
		if slot:
			var slot_data = {
				"id": slot.base_item.id,
				"amount": slot.amount,
				"rarity": slot.rarity,
				"affixes": []
			}
			for a in slot.affixes:
				slot_data["affixes"].append({
					"name": a["affix"].name,
					"value": a["value"]
				})
			data.append(slot_data)
		else:
			data.append(null)
	return data

func load_save_data(data: Array) -> void:
	slots.clear()
	slots.resize(max_slots)
	
	for i in range(min(data.size(), max_slots)):
		var d = data[i]
		if d and d is Dictionary:
			var base_item = LootManager.get_item_by_id(d.get("id", ""))
			if base_item:
				var inst = ItemInstance.new()
				inst.base_item = base_item
				inst.amount = d.get("amount", 1)
				inst.rarity = d.get("rarity", ItemData.Rarity.COMMON)
				
				var affixes_data = d.get("affixes", [])
				for a_d in affixes_data:
					var affix = LootManager.get_affix_by_name(a_d.get("name", ""))
					if affix:
						inst.affixes.append({
							"affix": affix,
							"value": a_d.get("value", 0)
						})
				slots[i] = inst
	
	_recalculate_weight()
	inventory_changed.emit()
