extends Control

@export var shop_slot_ui_scene: PackedScene = preload("res://src/ui/InventorySlotUI.tscn")

@onready var grid_container: GridContainer = %GridContainer
@onready var player_gold_label: Label = %PlayerGoldLabel
@onready var shop_name_label: Label = %ShopNameLabel

var slot_uis: Array[InventorySlotUI] = []
var player_stats: StatsComponent
var player_inventory: InventoryComponent
var current_shop_items: Array[ItemInstance] = []

func _ready() -> void:
	visible = false
	_setup_grid()

func _find_player() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player_stats = player.get_node_or_null("StatsComponent")
		player_inventory = player.get_node_or_null("InventoryComponent")

func _setup_grid() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	slot_uis.clear()
	
	# Create 24 slots for the shop
	for i in range(24):
		var slot_ui = shop_slot_ui_scene.instantiate()
		grid_container.add_child(slot_ui)
		slot_ui.slot_index = i
		slot_ui.slot_clicked.connect(_on_shop_slot_clicked)
		slot_uis.append(slot_ui)

func _update_ui() -> void:
	if not is_instance_valid(player_stats):
		_find_player()
	
	# Update slots
	for i in range(slot_uis.size()):
		if i < current_shop_items.size():
			slot_uis[i].update_slot(current_shop_items[i])
		else:
			slot_uis[i].update_slot(null)
			
	if player_stats:
		player_gold_label.text = "Your Gold: " + str(player_stats.gold)

func open(shop_name: String, items: Array[ItemData]) -> void:
	_find_player()
	shop_name_label.text = shop_name
	
	current_shop_items.clear()
	for item in items:
		var inst = ItemInstance.new()
		inst.base_item = item
		inst.amount = 1
		current_shop_items.append(inst)
		
	visible = true
	_update_ui()
	
	# Also open player inventory to allow selling (future)
	var hud = get_parent().get_parent() # PlayerHUD -> Control -> ShopWindow
	if hud and hud.has_node("%InventoryWindow"):
		var inv = hud.get_node("%InventoryWindow")
		if not inv.visible: inv.visible = true

func close() -> void:
	visible = false

func _on_shop_slot_clicked(index: int, button: MouseButton) -> void:
	if button == MOUSE_BUTTON_RIGHT:
		if index < current_shop_items.size():
			_buy_item(index)

func _buy_item(index: int) -> void:
	if not player_stats or not player_inventory: return
	
	var inst = current_shop_items[index]
	var cost = inst.base_item.value # Basic value for now
	
	if player_stats.gold >= cost:
		var new_inst = ItemInstance.new()
		new_inst.base_item = inst.base_item
		new_inst.amount = 1
		
		if player_inventory.add_item_instance(new_inst):
			player_stats.add_gold(-cost)
			_update_ui()
			print("[Shop] Bought ", inst.base_item.name, " for ", cost)
		else:
			print("[Shop] Inventory full!")
	else:
		print("[Shop] Not enough gold!")
