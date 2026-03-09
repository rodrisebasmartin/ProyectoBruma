extends CanvasLayer

signal dialogue_finished

@onready var dialogue_box = $Control/DialogueBox
@onready var name_label = $Control/DialogueBox/NameLabel
@onready var text_label = $Control/DialogueBox/TextLabel
@onready var next_button = $Control/DialogueBox/NextButton
@onready var choice_container = $Control/DialogueBox/ChoiceContainer

var current_dialogue: Array[String] = []
var current_index: int = 0
var is_active: bool = false
var typewriter_speed: float = 0.03
var is_typing: bool = false

func _ready() -> void:
	visible = false
	dialogue_box.visible = false
	choice_container.visible = false
	add_to_group("dialogue_ui")

func start_dialogue(speaker_name: String, lines: Array[String]) -> void:
	is_active = true
	visible = true
	dialogue_box.visible = true
	name_label.text = speaker_name
	current_dialogue = lines
	current_index = 0
	choice_container.visible = false
	_show_line()

func _show_line() -> void:
	if current_index >= current_dialogue.size():
		_finish_dialogue()
		return
	
	_type_text(current_dialogue[current_index])
	current_index += 1

func _type_text(full_text: String) -> void:
	is_typing = true
	text_label.text = ""
	
	for c in full_text:
		if not is_active: return
		text_label.text += c
		if c != " ":
			await get_tree().create_timer(typewriter_speed).timeout
			
	is_typing = false
	next_button.visible = true

func _input(event: InputEvent) -> void:
	if not is_active: return
	
	if event.is_action_pressed("interact") or event.is_action_pressed("attack"):
		if is_typing:
			# Skip typewriter (optional, for now just wait)
			pass
		else:
			_show_line()

func _on_next_pressed() -> void:
	if not is_typing:
		_show_line()

func _finish_dialogue() -> void:
	is_active = false
	visible = false
	dialogue_box.visible = false
	dialogue_finished.emit()

# Choice System Support (for Phase 3)
func show_choices(_choices: Array) -> void:
	# Placeholder for future choice logic (Accept Quest / Shop / Bank / Exit)
	pass
