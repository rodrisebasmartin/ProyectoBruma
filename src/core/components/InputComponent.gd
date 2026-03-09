extends Node
class_name InputComponent

## InputComponent: Decouples input handling from the Player entity.
## Supports Keyboard/Mouse and Gamepad (for Local Co-op).

@export var player_id: int = 0 : set = set_player_id # 0 = P1, 1 = P2
@export var is_ai_controlled: bool = false

# Current Input State
var move_dir: Vector2
var look_dir: Vector3
var is_attacking: bool
var is_blocking: bool
var is_dodging: bool
var is_casting_spell_1: bool
var is_casting_spell_2: bool
var interact_triggered: bool

func _ready() -> void:
	set_process(true)

func set_player_id(id: int) -> void:
	player_id = id

func _process(_delta: float) -> void:
	if is_ai_controlled: return
	
	_handle_movement_input()
	_handle_action_input()

func _handle_movement_input() -> void:
	var prefix = "p%d_" % (player_id + 1) if player_id > 0 else "" # "p2_move_left"
	# Fallback to standard inputs for P1 if no prefix
	var left = prefix + "move_left" if InputMap.has_action(prefix + "move_left") else "move_left"
	var right = prefix + "move_right" if InputMap.has_action(prefix + "move_right") else "move_right"
	var up = prefix + "move_forward" if InputMap.has_action(prefix + "move_forward") else "move_forward"
	var down = prefix + "move_backward" if InputMap.has_action(prefix + "move_backward") else "move_backward"
	
	move_dir = Input.get_vector(left, right, up, down)

func _handle_action_input() -> void:
	var prefix = "p%d_" % (player_id + 1) if player_id > 0 else ""
	
	var attack = prefix + "attack" if InputMap.has_action(prefix + "attack") else "attack"
	var block = prefix + "block" if InputMap.has_action(prefix + "block") else "block"
	var dodge = prefix + "dodge" if InputMap.has_action(prefix + "dodge") else "dodge"
	var spell1 = prefix + "spell_1" if InputMap.has_action(prefix + "spell_1") else "spell_1"
	var spell2 = prefix + "spell_2" if InputMap.has_action(prefix + "spell_2") else "spell_2"
	var interact = prefix + "interact" if InputMap.has_action(prefix + "interact") else "interact"

	is_attacking = Input.is_action_just_pressed(attack)
	is_blocking = Input.is_action_pressed(block)
	is_dodging = Input.is_action_just_pressed(dodge)
	is_casting_spell_1 = Input.is_action_just_pressed(spell1)
	is_casting_spell_2 = Input.is_action_just_pressed(spell2)
	interact_triggered = Input.is_action_just_pressed(interact)
