extends Control
class_name InventoryWindow

@export var inventory: InventoryComponent
@export var slot_ui_scene: PackedScene = preload("res://src/ui/InventorySlotUI.tscn")

@onready var grid_container: GridContainer = %GridContainer
@onready var weight_label: Label = %WeightLabel

var slot_uis: Array[InventorySlotUI] = []

func _ready() -> void:
	# Hide by default
	visible = false
	
	if not inventory:
		_find_player_inventory()
	
	if inventory:
		inventory.inventory_changed.connect(_on_inventory_changed)
		_setup_grid()
		_on_inventory_changed()

func _find_player_inventory() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		inventory = player.get_node_or_null("InventoryComponent")

func _setup_grid() -> void:
	# Clear existing
	for child in grid_container.get_children():
		child.queue_free()
	slot_uis.clear()
	
	# Create slots based on inventory size
	for i in range(inventory.max_slots):
		var slot_ui = slot_ui_scene.instantiate()
		grid_container.add_child(slot_ui)
		slot_ui.slot_index = i
		slot_ui.slot_clicked.connect(_on_slot_clicked)
		slot_uis.append(slot_ui)

func _on_inventory_changed() -> void:
	if not inventory: return
	
	for i in range(inventory.slots.size()):
		if i < slot_uis.size():
			slot_uis[i].update_slot(inventory.slots[i])
			
	weight_label.text = "Weight: %.1f / %.1f" % [inventory.current_weight, inventory.max_weight]

func _on_slot_clicked(index: int, button: MouseButton) -> void:
	if button == MOUSE_BUTTON_RIGHT:
		var inst = inventory.slots[index]
		if not inst: return
		
		var base = inst.base_item
		var player = get_tree().get_first_node_in_group("player")
		if not player: return
		
		# 1. Check if it's equipment
		if base.item_type in [ItemData.ItemType.WEAPON, ItemData.ItemType.ARMOR, ItemData.ItemType.SHIELD]:
			var equipment: Node = player.get_node_or_null("EquipmentComponent")
			if equipment and equipment.has_method("equip_item_instance"):
				equipment.equip_item_instance(inst, index)
				return
		
		# 2. Otherwise use as consumable
		# (Note: Consume system might need instance update too)
		if base.use(player):
			inventory.remove_at(index, 1)

func toggle() -> void:
	visible = !visible
	if visible:
		_on_inventory_changed() # Refresh when opening
