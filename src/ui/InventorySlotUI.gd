extends Control
class_name InventorySlotUI

signal slot_clicked(index: int, button: MouseButton)

const TooltipScene = preload("res://src/ui/RichItemTooltip.tscn")

@onready var icon_rect: TextureRect = $Icon
@onready var amount_label: Label = $Amount
@onready var rarity_border: Panel = $RarityBorder

var slot_index: int = -1
var current_instance: ItemInstance

func update_slot(inst: ItemInstance) -> void:
	current_instance = inst
	
	if inst == null or inst.base_item == null:
		icon_rect.texture = null
		amount_label.text = ""
		rarity_border.self_modulate = Color(1, 1, 1, 0.2)
		tooltip_text = "" # This must be non-empty for _make_custom_tooltip to work
		return
		
	var base = inst.base_item
	icon_rect.texture = base.icon
	amount_label.text = str(inst.amount) if inst.amount > 1 else ""
	
	var color = inst.get_rarity_color()
	rarity_border.self_modulate = color
	
	# Set tooltip_text to something to enable custom tooltip
	tooltip_text = "item"

func _make_custom_tooltip(_for_text: String) -> Object:
	if not current_instance: return null
	
	var tooltip = TooltipScene.instantiate()
	
	# Find equipped item for comparison
	var equipped: ItemInstance = null
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var equipment: EquipmentComponent = player.get_node_or_null("EquipmentComponent")
		if equipment:
			match current_instance.base_item.item_type:
				ItemData.ItemType.WEAPON: equipped = equipment.weapon
				ItemData.ItemType.ARMOR: equipped = equipment.armor
				ItemData.ItemType.SHIELD: equipped = equipment.shield
	
	tooltip.setup(current_instance, equipped)
	return tooltip

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		slot_clicked.emit(slot_index, event.button_index)
