extends Control

@onready var close_button: Button = %CloseButton

func _ready() -> void:
	if GameManager and GameManager.has_shown_welcome:
		visible = false
		return
		
	# Show on start
	visible = true
	if GameManager: GameManager.has_shown_welcome = true
	
	close_button.pressed.connect(hide_welcome)
	
	# Pause game while welcome is open
	get_tree().paused = true

func hide_welcome() -> void:
	visible = false
	get_tree().paused = false

func toggle() -> void:
	visible = !visible
	get_tree().paused = visible

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_H or event.keycode == KEY_F1:
			toggle()
