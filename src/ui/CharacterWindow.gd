extends Control

@onready var points_label = %PointsLabel
@onready var str_val = %StrValue
@onready var int_val = %IntValue
@onready var dex_val = %DexValue
@onready var con_val = %ConValue
@onready var atk_val = %AtkValue
@onready var def_val = %DefValue

@onready var head_slot = %HeadSlot
@onready var armor_slot = %ArmorSlot
@onready var weapon_slot = %WeaponSlot
@onready var shield_slot = %ShieldSlot

var player_stats: StatsComponent
var player_equipment: EquipmentComponent

func _ready() -> void:
	visible = false
	_find_player_refs()
	
	# Setup slot clicks for unequipping
	head_slot.slot_clicked.connect(_on_slot_clicked.bind("head"))
	armor_slot.slot_clicked.connect(_on_slot_clicked.bind("armor"))
	weapon_slot.slot_clicked.connect(_on_slot_clicked.bind("weapon"))
	shield_slot.slot_clicked.connect(_on_slot_clicked.bind("shield"))

func _find_player_refs() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player_stats = player.get_node_or_null("StatsComponent")
		player_equipment = player.get_node_or_null("EquipmentComponent")
		
		if player_stats and not player_stats.stats_changed.is_connected(update_ui):
			player_stats.stats_changed.connect(update_ui)
		
		if player_equipment and not player_equipment.equipment_changed.is_connected(_on_equipment_changed):
			player_equipment.equipment_changed.connect(_on_equipment_changed)

func toggle() -> void:
	visible = !visible
	if visible:
		_find_player_refs()
		update_ui()

func update_ui() -> void:
	if not is_instance_valid(player_stats): 
		_find_player_refs()
		if not is_instance_valid(player_stats): return
		
	points_label.text = "Points: " + str(player_stats.stat_points)
	str_val.text = str(player_stats.strength)
	int_val.text = str(player_stats.intelligence)
	dex_val.text = str(player_stats.dexterity)
	con_val.text = str(player_stats.constitution)
	
	atk_val.text = str(player_stats.get_total_attack())
	def_val.text = str(player_stats.get_total_defense())
	
	_update_equipment_slots()

func _update_equipment_slots() -> void:
	if not player_equipment: return
	head_slot.update_slot(player_equipment.head)
	armor_slot.update_slot(player_equipment.armor)
	weapon_slot.update_slot(player_equipment.weapon)
	shield_slot.update_slot(player_equipment.shield)

func _on_equipment_changed(_slot: String, _inst: ItemInstance) -> void:
	update_ui()

func _on_slot_clicked(_index: int, button: MouseButton, slot_name: String) -> void:
	if button == MOUSE_BUTTON_RIGHT and player_equipment:
		player_equipment.unequip_slot(slot_name)

# Attribute Buttons
func _on_add_str_pressed() -> void: if player_stats: player_stats.spend_stat_point("strength")
func _on_add_int_pressed() -> void: if player_stats: player_stats.spend_stat_point("intelligence")
func _on_add_dex_pressed() -> void: if player_stats: player_stats.spend_stat_point("dexterity")
func _on_add_con_pressed() -> void: if player_stats: player_stats.spend_stat_point("constitution")
