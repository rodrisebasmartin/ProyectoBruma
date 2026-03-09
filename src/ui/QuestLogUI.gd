extends Control

@onready var container = $VBoxContainer

func _ready() -> void:
	QuestManager.quest_status_changed.connect(_on_quest_updated)
	QuestManager.objective_updated.connect(_on_quest_updated)
	_refresh_list()

func _on_quest_updated(_quest: Quest) -> void:
	_refresh_list()

func _refresh_list() -> void:
	# Clear existing
	for child in container.get_children():
		child.queue_free()
	
	# Add active quests
	for quest_id in QuestManager.active_quests:
		var quest = QuestManager.active_quests[quest_id]
		var label = Label.new()
		
		var status_text = ""
		if quest.status == Quest.Status.COMPLETED:
			status_text = " (READY TO TURN IN)"
		else:
			status_text = " (%d/%d)" % [quest.current_amount, quest.required_amount]
			
		label.text = "- " + quest.title + status_text
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 4)
		label.add_theme_font_size_override("font_size", 14)
		
		if quest.status == Quest.Status.COMPLETED:
			label.add_theme_color_override("font_color", Color.YELLOW)
		
		container.add_child(label)

func toggle() -> void:
	visible = !visible
