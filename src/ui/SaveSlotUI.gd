extends Control

@onready var slots_container: VBoxContainer = $CenterContainer/VBoxContainer
@onready var slot_button_template: Button = $CenterContainer/VBoxContainer/SlotButtonTemplate

func _ready() -> void:
	slot_button_template.visible = false
	_populate_slots()

func _populate_slots() -> void:
	for i in range(1, 4):
		var btn = slot_button_template.duplicate()
		btn.visible = true
		btn.text = "Save Slot %d" % i
		
		# Check if save exists
		var path = GameManager.SAVE_PATH % i
		if FileAccess.file_exists(path):
			btn.text += " (Existing)"
		else:
			btn.text += " (Empty)"
			
		btn.pressed.connect(_on_slot_selected.bind(i))
		slots_container.add_child(btn)

func _on_slot_selected(slot_index: int) -> void:
	GameManager.current_slot = slot_index
	GameManager.load_from_disk(slot_index) # Try to load, if fails, it's a new game
	get_tree().change_scene_to_file("res://src/world/TownFixed.tscn")
