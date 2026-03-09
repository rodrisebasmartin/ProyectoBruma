extends CanvasLayer

@onready var health_bar: ProgressBar = $Control/StatsContainer/HealthBar
@onready var mana_bar: ProgressBar = $Control/StatsContainer/ManaBar
@onready var stamina_bar: ProgressBar = $Control/StatsContainer/StaminaBar
@onready var dodge_overlay: ColorRect = %CooldownOverlay
@onready var cast_bar: ProgressBar = %CastBar

@onready var level_label: Label = %LevelLabel
@onready var exp_label: Label = %ExpLabel
@onready var gold_label: Label = %GoldLabel

@onready var slot1: ColorRect = $Control/SpellBar/Slot1
@onready var slot2: ColorRect = $Control/SpellBar/Slot2
@onready var character_window = %CharacterWindow
@onready var inventory_window = %InventoryWindow
@onready var quest_log = $Control/QuestLogUI
@onready var welcome_ui = get_node_or_null("Control/WelcomeUI")

var player: CharacterBody3D
var player_health: HealthComponent
var player_stats: StatsComponent

func _ready() -> void:
	add_to_group("hud")
	_find_player()
	EventBus.boss_spawned.connect(_on_boss_spawned)

func _on_boss_spawned(boss_name: String) -> void:
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Control.add_child(center)
	
	var label = Label.new()
	label.text = "THE VEIL THINS...\n" + boss_name.to_upper() + " EMERGES FROM THE ABYSS!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set("theme_override_colors/font_color", Color.RED)
	label.set("theme_override_colors/font_outline_color", Color.BLACK)
	label.set("theme_override_constants/outline_size", 8)
	label.set("theme_override_font_sizes/font_size", 32)
	
	center.add_child(label)
	
	var tween = create_tween()
	label.modulate.a = 0
	tween.tween_property(label, "modulate:a", 1.0, 1.0)
	tween.tween_interval(3.0)
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(center.queue_free)

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var p = players[0]
		if is_instance_valid(p):
			player = p
			player_health = p.get_node_or_null("HealthComponent")
			player_stats = p.get_node_or_null("StatsComponent")
			_update_bar_max_values()
			print("[HUD] Player components linked.")

func _update_bar_max_values() -> void:
	if is_instance_valid(player_health):
		health_bar.max_value = player_health.max_health
	
	if is_instance_valid(player):
		var m_mana = player.get("max_mana")
		var m_stamina = player.get("max_stamina")
		if m_mana != null: mana_bar.max_value = m_mana
		if m_stamina != null: stamina_bar.max_value = m_stamina

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_character_window"):
		if character_window: character_window.toggle()
	
	if event.is_action_pressed("toggle_inventory"):
		if inventory_window: inventory_window.toggle()
	
	if event.is_action_pressed("toggle_quest_log"):
		if quest_log: quest_log.toggle()
		
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_H or event.keycode == KEY_F1:
			if welcome_ui: welcome_ui.toggle()

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		_find_player()
		return

	# Update Bars and their Max Values dynamically
	if is_instance_valid(player_health):
		if health_bar.max_value != player_health.max_health:
			health_bar.max_value = player_health.max_health
		health_bar.value = lerp(health_bar.value, float(player_health.current_health), 15.0 * delta)
			
	var p_max_mana = player.get("max_mana")
	if p_max_mana != null and mana_bar.max_value != p_max_mana:
		mana_bar.max_value = p_max_mana
	
	var p_curr_mana = player.get("current_mana")
	if p_curr_mana != null:
		mana_bar.value = lerp(mana_bar.value, float(p_curr_mana), 15.0 * delta)
	
	var p_max_stamina = player.get("max_stamina")
	if p_max_stamina != null and stamina_bar.max_value != p_max_stamina:
		stamina_bar.max_value = p_max_stamina
	
	var p_curr_stamina = player.get("current_stamina")
	if p_curr_stamina != null:
		stamina_bar.value = lerp(stamina_bar.value, float(p_curr_stamina), 15.0 * delta)
	
	_update_text_stats()
	_update_spell_slots()
	
	# Dodge Cooldown
	var dcd = player.get("dodge_cooldown_timer")
	var dmax = player.get("dodge_cooldown")
	if dcd != null and dmax != null and dcd > 0:
		dodge_overlay.visible = true
		dodge_overlay.anchor_top = 1.0 - (dcd / dmax)
	else:
		dodge_overlay.visible = false
		
	# Casting Bar
	var p_casting = player.get("is_casting")
	if p_casting == true:
		cast_bar.visible = true
		var c_time = player.get("cast_timer")
		var c_max = player.get("cast_duration")
		if c_time != null and c_max != null and c_max > 0:
			cast_bar.value = (1.0 - (c_time / c_max)) * 100.0
	else:
		cast_bar.visible = false

func _update_text_stats() -> void:
	if is_instance_valid(player_stats):
		level_label.text = "LVL: " + str(player_stats.level)
		exp_label.text = "EXP: %d / %d" % [player_stats.experience, player_stats.experience_needed]
		gold_label.text = "GOLD: " + str(player_stats.gold)

func _update_spell_slots() -> void:
	if not is_instance_valid(player): return
	var idx = player.get("current_spell_index")
	if idx != null:
		slot1.color = Color(0.1, 0.4, 0.8, 0.8) if idx == 0 else Color(0.1, 0.1, 0.1, 0.8)
		slot2.color = Color(0.1, 0.4, 0.8, 0.8) if idx == 1 else Color(0.1, 0.1, 0.1, 0.8)
