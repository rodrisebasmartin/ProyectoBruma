extends Node3D

var citizen_scene: PackedScene = preload("res://src/entities/NPC.tscn")

var citizen_names = ["Arin", "Borg", "Celia", "Daro", "Elen", "Frey", "Gald", "Heda", "Ion", "Jora", "Kael", "Lina"]
var citizen_chatter = [
	"The tavern serves the best ale in the kingdom.",
	"I've lived here for forty years and never seen such wolves.",
	"Did you hear the king is raising taxes again?",
	"Keep your gold close, the road is full of thieves.",
	"Beautiful day, isn't it?",
	"I hope the trade caravans arrive soon."
]

func _ready() -> void:
	if has_node("GateToWild"):
		$GateToWild.body_entered.connect(_on_gate_entered)
		_add_portal_icon($GateToWild, Color.VIOLET)
	
	_spawn_key_npcs()
	_spawn_citizens(12)

func _spawn_key_npcs() -> void:
	# Banker
	var banker = citizen_scene.instantiate()
	add_child(banker)
	banker.npc_name = "Silas the Banker"
	banker.npc_type = 3 # BANKER
	banker.initial_dialogue = "Safe keeping for your gold and treasures. How can I help you today?"
	banker.global_position = Vector3(-10, 0, -10)
	banker.can_wander = false
	
	# Shopkeeper
	var shop = citizen_scene.instantiate()
	add_child(shop)
	shop.npc_name = "Marcus the Merchant"
	shop.npc_type = 4 # SHOPKEEPER
	shop.initial_dialogue = "Finest goods in all of Argentum! Have a look."
	shop.global_position = Vector3(10, 0, -10)
	shop.can_wander = false

func _add_portal_icon(node: Node3D, color: Color) -> void:
	var icon = MinimapIcon.new()
	icon.color = color
	icon.size = 4.0
	node.add_child(icon)

func _spawn_citizens(amount: int) -> void:
	for i in range(amount):
		var npc = citizen_scene.instantiate()
		add_child(npc)
		
		# Pick a name and some chatter
		npc.npc_name = citizen_names[i % citizen_names.size()]
		npc.npc_type = 0 # CITIZEN
		
		# Pick 2-3 random chatter lines
		var my_chatter: Array[String] = []
		for j in range(2):
			my_chatter.append(citizen_chatter[randi() % citizen_chatter.size()])
		npc.random_chatter = my_chatter
		
		# Random position within town floor (100x100)
		# We'll stay within -40 to 40 for safety
		var rx = randf_range(-40, 40)
		var rz = randf_range(-40, 40)
		
		# Ensure they don't spawn too close to the player or gates
		if Vector2(rx, rz).length() < 5: rx += 10
		
		npc.global_position = Vector3(rx, 0, rz)
		npc.original_position = npc.global_position
		print("[Town] Spawned citizen: ", npc.npc_name, " at ", npc.global_position)

func _on_gate_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		print("[Town] Traveling to the Wild...")
		if GameManager:
			GameManager.change_scene("res://src/world/Main.tscn", body)
		else:
			get_tree().change_scene_to_file("res://src/world/Main.tscn")
