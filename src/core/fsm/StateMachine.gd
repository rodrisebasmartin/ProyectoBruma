extends Node
class_name StateMachine

@export var initial_state: State

var current_state: State
var states: Dictionary = {}

func _ready() -> void:
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.fsm = self
			child.actor = get_parent()
	
	if initial_state:
		initial_state.enter()
		current_state = initial_state

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func transition_to(target_state_name: String) -> void:
	if not states.has(target_state_name.to_lower()):
		printerr("[StateMachine] Cannot transition to state: ", target_state_name)
		return
	
	if current_state:
		current_state.exit()
	
	current_state = states[target_state_name.to_lower()]
	current_state.enter()
