extends CharacterBody3D

enum NPCType { CITIZEN, GUARD, QUEST_GIVER, BANKER, SHOPKEEPER }

@export_group("NPC Identity")
@export var npc_name: String = "Citizen"
@export var npc_type: NPCType = NPCType.CITIZEN
@export_multiline var initial_dialogue: String = "Nice day, isn't it?"
@export var dialogue_lines: Array[String] = []
@export var random_chatter: Array[String] = [
	"I hope it doesn't rain today.",
	"Have you seen the price of bread lately?",
	"The guards look very serious today.",
	"I love the smell of the sea in the morning.",
	"Be careful out there in the Wilds!"
]

@export_group("AI Movement")
@export var can_wander: bool = true
@export var move_speed: float = 1.5
@export var wander_radius: float = 8.0
@export var idle_time_range: Vector2 = Vector2(2.0, 5.0)

@export_group("Quest Data (Optional)")
@export var has_quest: bool = false
@export var quest_id: String = "wolf_slayer_1"
@export var quest_title: String = "Wolf Slayer"
@export var quest_target_name: String = "Wolf"
@export var quest_required_amount: int = 5
@export var quest_reward_exp: int = 150
@export var quest_reward_gold: int = 75

var original_position: Vector3
var state_machine: StateMachine

@onready var interactable: Interactable = $Interactable
@onready var animation_player: AnimationPlayer = $Model/AnimationPlayer

func _ready() -> void:
	original_position = global_position
	
	_setup_fsm()
	
	if interactable:
		interactable.prompt_message = "Talk to " + npc_name
		interactable.interacted.connect(_on_interacted)
	
	if has_quest:
		_setup_runtime_quest()
	
	_add_minimap_icon()
	_apply_visuals()
	_randomize_appearance()
	
	if animation_player:
		animation_player.play("Idle")

func _setup_fsm() -> void:
	state_machine = StateMachine.new()
	state_machine.name = "StateMachine"
	add_child(state_machine)
	
	var idle = load("res://src/entities/npc/states/IdleState.gd").new()
	idle.name = "Idle"
	idle.idle_time_range = idle_time_range
	state_machine.add_child(idle)
	
	var wander = load("res://src/entities/npc/states/WanderState.gd").new()
	wander.name = "Wander"
	# Properties are read from actor in enter()
	state_machine.add_child(wander)
	
	var talk = load("res://src/entities/npc/states/TalkState.gd").new()
	talk.name = "Talk"
	state_machine.add_child(talk)
	
	state_machine.initial_state = idle
	# Force ready of state machine after adding children
	state_machine._ready() 

func _physics_process(delta: float) -> void:
	# Gravity is the only thing handled here now, FSM handles horizontal logic
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0
		
	# Note: state_machine._physics_process is called automatically because it's in the tree
	move_and_slide()

func _play_animation(anim_name: String) -> void:
	if not animation_player: return
	
	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name, 0.3)
	else:
		# Search for similar names
		for full_name in animation_player.get_animation_list():
			if anim_name.to_lower() in full_name.to_lower():
				animation_player.play(full_name, 0.3)
				return

func _randomize_appearance() -> void:
	# Small scale variation
	var s = randf_range(0.9, 1.1)
	scale = Vector3(s, s, s)
	
	if npc_type == NPCType.CITIZEN:
		var model = get_node_or_null("Model")
		if model:
			var random_color = Color(randf(), randf(), randf())
			for child in model.get_children():
				if child is MeshInstance3D:
					var mat = StandardMaterial3D.new()
					mat.albedo_color = random_color
					child.material_override = mat
					break

func _add_minimap_icon() -> void:
	var icon = MinimapIcon.new()
	match npc_type:
		NPCType.GUARD: icon.color = Color.GREEN
		NPCType.BANKER: icon.color = Color.GOLD
		NPCType.SHOPKEEPER: icon.color = Color.PURPLE
		NPCType.CITIZEN: icon.color = Color.SKY_BLUE
		_: icon.color = Color.CYAN
	
	icon.size = 2.0
	add_child(icon)

func _apply_visuals() -> void:
	var model = get_node_or_null("Model")
	if model and npc_type != NPCType.CITIZEN:
		var tint = Color(0.2, 0.8, 0.2) 
		match npc_type:
			NPCType.BANKER: tint = Color(0.8, 0.6, 0.1) 
			NPCType.SHOPKEEPER: tint = Color(0.1, 0.4, 0.8)
			NPCType.QUEST_GIVER: tint = Color(0.8, 0.2, 0.8) 
		
		for child in model.get_children():
			if child is MeshInstance3D:
				var mat = StandardMaterial3D.new()
				mat.albedo_color = tint
				child.material_override = mat
				break

func _setup_runtime_quest() -> void:
	var runtime_quest = Quest.new()
	runtime_quest.quest_id = quest_id
	runtime_quest.title = quest_title
	runtime_quest.target_name = quest_target_name
	runtime_quest.required_amount = quest_required_amount
	runtime_quest.reward_exp = quest_reward_exp
	runtime_quest.reward_gold = quest_reward_gold
	self.set_meta("runtime_quest", runtime_quest)

func _on_interacted(player: CharacterBody3D) -> void:
	var dir_to_player = (player.global_position - global_position).normalized()
	# Standard Godot: atan2(-x, -z) aligns -Z with target
	rotation.y = atan2(-dir_to_player.x, -dir_to_player.z)
	
	state_machine.transition_to("Talk")
	
	var lines: Array[String] = []
	
	if npc_type == NPCType.CITIZEN and random_chatter.size() > 0:
		lines.append(random_chatter[randi() % random_chatter.size()])
	else:
		lines.append(initial_dialogue)
		lines.append_array(dialogue_lines)
	
	if npc_type == NPCType.BANKER:
		_open_bank(player)
	elif npc_type == NPCType.SHOPKEEPER:
		_open_shop(player)
	
	var runtime_quest = get_meta("runtime_quest") if has_meta("runtime_quest") else null
	
	if has_quest and runtime_quest:
		var q_id = runtime_quest.quest_id
		if q_id in QuestManager.active_quests:
			var active_q = QuestManager.active_quests[q_id]
			if active_q.status == Quest.Status.COMPLETED:
				lines = ["Great job! Here is your reward."]
				QuestManager.complete_quest(q_id, player)
			else:
				lines = ["Still working on that quest? (%d/%d %s)" % [active_q.current_amount, active_q.required_amount, active_q.target_name]]
		elif q_id in QuestManager.completed_quests:
			lines = ["Thanks for your help earlier!"]
		else:
			lines.append("New Quest: " + runtime_quest.title)
			QuestManager.accept_quest(runtime_quest)

	_say(lines)

func _say(lines: Array[String]) -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		var dialogue_ui = hud.find_child("DialogueUI", true, false)
		if dialogue_ui:
			if not dialogue_ui.dialogue_finished.is_connected(_on_dialogue_finished):
				dialogue_ui.dialogue_finished.connect(_on_dialogue_finished, CONNECT_ONE_SHOT)
			dialogue_ui.start_dialogue(npc_name, lines)

func _on_dialogue_finished() -> void:
	state_machine.transition_to("Idle")

func _open_bank(_player: Node3D) -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		var bank_window = hud.find_child("BankWindow", true, false)
		if bank_window:
			bank_window.open()

func _open_shop(_player: Node3D) -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		var shop_window = hud.find_child("ShopWindow", true, false)
		if shop_window:
			# Give some default items for now
			var items: Array[ItemData] = []
			var potion = LootManager.get_item_by_id("health_potion")
			if potion: items.append(potion)
			var sword = LootManager.get_item_by_id("iron_sword")
			if sword: items.append(sword)
			
			shop_window.open(npc_name, items)
