extends Node
class_name EquipmentComponent

## EquipmentComponent: Manages equipped ItemInstances (Solo/Co-op)
## Updates player stats based on base item stats + affixes.

signal equipment_changed(slot: String, instance: ItemInstance)

# Slot storage
var weapon: ItemInstance
var shield: ItemInstance
var armor: ItemInstance
var head: ItemInstance

var inventory: InventoryComponent
var stats: StatsComponent

func _ready() -> void:
	var parent = get_parent()
	inventory = parent.get_node_or_null("InventoryComponent")
	stats = parent.get_node_or_null("StatsComponent")

func equip_item_instance(inst: ItemInstance, inv_index: int = -1) -> bool:
	if not inst or not inst.base_item: return false
	
	var old_inst: ItemInstance = null
	var slot_name = ""
	
	match inst.base_item.item_type:
		ItemData.ItemType.WEAPON:
			old_inst = weapon
			weapon = inst
			slot_name = "weapon"
		ItemData.ItemType.SHIELD:
			old_inst = shield
			shield = inst
			slot_name = "shield"
		ItemData.ItemType.ARMOR:
			old_inst = armor
			armor = inst
			slot_name = "armor"
		_:
			return false 
			
	# Remove from inventory
	if inv_index != -1 and inventory:
		inventory.slots[inv_index] = null
		inventory.inventory_changed.emit()
		
	# Put old item back in inventory
	if old_inst and inventory:
		inventory.add_item_instance(old_inst)
		
	equipment_changed.emit(slot_name, inst)
	_update_stats()
	return true

func unequip_slot(slot_name: String) -> bool:
	var inst: ItemInstance = null
	match slot_name:
		"weapon":
			inst = weapon
			weapon = null
		"shield":
			inst = shield
			shield = null
		"armor":
			inst = armor
			armor = null
			
	if inst:
		if inventory:
			inventory.add_item_instance(inst)
		equipment_changed.emit(slot_name, null)
		_update_stats()
		return true
	return false

func _update_stats() -> void:
	if not stats: return
	
	var total_dmg = 0
	var total_def = 0
	
	var active_items = [weapon, shield, armor, head]
	for inst in active_items:
		if inst:
			var item_stats = inst.get_total_stats()
			total_dmg += item_stats["damage"]
			total_def += item_stats["defense"]
			# ... add more bonuses from affixes here
			
	if stats.has_method("update_equipment_bonuses"):
		# Update StatsComponent with the new totals
		stats.bonus_damage = total_dmg
		stats.bonus_defense = total_def
		# We can also add affix bonuses to stats
		stats.stats_changed.emit()
