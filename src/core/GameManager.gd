extends Node

## GameManager: Handles Save/Load Slots and Persistent World State
## For Solo/Co-op: Supports local files in user://

const SAVE_PATH = "user://save_slot_%d.json"
const DEFAULT_SLOT = 1

var current_slot: int = DEFAULT_SLOT
var player_data: Dictionary = {}

func _ready() -> void:
	reset_data()

func reset_data() -> void:
	player_data = {
		"level": 1,
		"experience": 0,
		"experience_needed": 100,
		"gold": 0,
		"stat_points": 0,
		"strength": 10,
		"intelligence": 10,
		"dexterity": 10,
		"constitution": 10,
		"current_health": -1,
		"current_mana": -1,
		"class": 0,
		"inventory": [],
		"equipment": {}
	}
	print("[GameManager] Data reset to defaults.")

# --- DISK I/O ---

func save_to_disk(slot: int = current_slot) -> void:
	var path = SAVE_PATH % slot
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(player_data, "\t")
		file.store_string(json_string)
		file.close()
		print("[GameManager] Saved to disk: ", path)
	else:
		printerr("[GameManager] Failed to save to: ", path)

func load_from_disk(slot: int = current_slot) -> bool:
	var path = SAVE_PATH % slot
	if not FileAccess.file_exists(path):
		print("[GameManager] No save file found at: ", path)
		return false
		
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			player_data = json.get_data()
			print("[GameManager] Loaded from disk: ", path)
			return true
	return false

# --- PLAYER SYNC ---

func save_player(player: Node3D) -> void:
	var stats = player.get_node_or_null("StatsComponent")
	var health = player.get_node_or_null("HealthComponent")
	var inv = player.get_node_or_null("InventoryComponent")
	
	if stats:
		player_data["level"] = stats.level
		player_data["experience"] = stats.experience
		player_data["experience_needed"] = stats.experience_needed
		player_data["gold"] = stats.gold
		player_data["stat_points"] = stats.stat_points
		player_data["strength"] = stats.strength
		player_data["intelligence"] = stats.intelligence
		player_data["dexterity"] = stats.dexterity
		player_data["constitution"] = stats.constitution
	
	if health:
		player_data["current_health"] = health.current_health
	
	player_data["current_mana"] = player.current_mana
	player_data["class"] = player.current_class
	
	# Component-based save data (if they have the method)
	if inv and inv.has_method("get_save_data"):
		player_data["inventory"] = inv.get_save_data()
		
	# Bank data
	if BankManager:
		player_data["bank_gold"] = BankManager.bank_gold
		if BankManager.bank_inventory:
			player_data["bank_inventory"] = BankManager.bank_inventory.get_save_data()
		
	save_to_disk()

func load_player(player: Node3D) -> void:
	# Try loading from disk first
	if not load_from_disk():
		print("[GameManager] Using existing/default memory data.")

	var stats = player.get_node_or_null("StatsComponent")
	var health = player.get_node_or_null("HealthComponent")
	var inv = player.get_node_or_null("InventoryComponent")
	
	if stats:
		stats.level = player_data.get("level", 1)
		stats.experience = player_data.get("experience", 0)
		stats.experience_needed = player_data.get("experience_needed", 100)
		stats.gold = player_data.get("gold", 0)
		stats.stat_points = player_data.get("stat_points", 0)
		stats.strength = player_data.get("strength", 10)
		stats.intelligence = player_data.get("intelligence", 10)
		stats.dexterity = player_data.get("dexterity", 10)
		stats.constitution = player_data.get("constitution", 10)
	
	player.current_class = player_data.get("class", 0)
	
	if health and player_data.get("current_health", -1) > 0:
		health.current_health = player_data["current_health"]
	
	if player_data.get("current_mana", -1) > 0:
		player.current_mana = player_data["current_mana"]
		
	if inv and inv.has_method("load_save_data") and player_data.has("inventory"):
		inv.load_save_data(player_data["inventory"])
		
	# Bank data
	if BankManager:
		BankManager.bank_gold = player_data.get("bank_gold", 0)
		if player_data.has("bank_inventory") and BankManager.bank_inventory:
			BankManager.bank_inventory.load_save_data(player_data["bank_inventory"])
		
	print("[GameManager] Player and Bank loaded and synced.")

func change_scene(scene_path: String, player: Node3D) -> void:
	if player: save_player(player)
	get_tree().call_deferred("change_scene_to_file", scene_path)
