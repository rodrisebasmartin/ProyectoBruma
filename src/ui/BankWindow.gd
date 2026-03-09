extends Control

@export var bank_slot_ui_scene: PackedScene = preload("res://src/ui/InventorySlotUI.tscn")

@onready var grid_container: GridContainer = %GridContainer
@onready var bank_gold_label: Label = %BankGoldLabel
@onready var player_gold_label: Label = %PlayerGoldLabel

var slot_uis: Array[InventorySlotUI] = []
var player_stats: StatsComponent
var player_inventory: InventoryComponent

func _ready() -> void:
	visible = false
	BankManager.bank_updated.connect(_update_ui)
	_setup_grid()
	_update_ui()

func _find_player() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player_stats = player.get_node_or_null("StatsComponent")
		player_inventory = player.get_node_or_null("InventoryComponent")

func _setup_grid() -> void:
	# Clear existing
	for child in grid_container.get_children():
		child.queue_free()
	slot_uis.clear()
	
	# Create slots based on bank size
	for i in range(BankManager.bank_inventory.max_slots):
		var slot_ui = bank_slot_ui_scene.instantiate()
		grid_container.add_child(slot_ui)
		slot_ui.slot_index = i
		slot_ui.slot_clicked.connect(_on_bank_slot_clicked)
		slot_uis.append(slot_ui)

func _update_ui() -> void:
	if not is_instance_valid(player_stats):
		_find_player()
	
	# Update slots
	for i in range(BankManager.bank_inventory.slots.size()):
		if i < slot_uis.size():
			slot_uis[i].update_slot(BankManager.bank_inventory.slots[i])
			
	bank_gold_label.text = "Bank Gold: " + str(BankManager.bank_gold)
	if player_stats:
		player_gold_label.text = "Player Gold: " + str(player_stats.gold)

func open() -> void:
	_find_player()
	visible = true
	_update_ui()
	
	# Also open player inventory for convenience
	var hud = get_parent().get_parent() # PlayerHUD -> Control -> BankWindow
	if hud and hud.has_node("%InventoryWindow"):
		var inv = hud.get_node("%InventoryWindow")
		if not inv.visible: inv.visible = true

func close() -> void:
	visible = false

func _on_bank_slot_clicked(index: int, button: MouseButton) -> void:
	if button == MOUSE_BUTTON_RIGHT:
		if player_inventory:
			BankManager.withdraw_item(index, player_inventory)

func _on_deposit_gold_pressed() -> void:
	if player_stats:
		# Could add a popup to ask how much, for now just 100 or all if less
		var amount = min(100, player_stats.gold)
		if amount > 0:
			BankManager.deposit_gold(amount, player_stats)

func _on_withdraw_gold_pressed() -> void:
	if player_stats:
		var amount = min(100, BankManager.bank_gold)
		if amount > 0:
			BankManager.withdraw_gold(amount, player_stats)
