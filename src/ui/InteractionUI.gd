extends Control

@onready var label = $Label
var player: CharacterBody3D

func _ready() -> void:
	visible = false

func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
		else:
			visible = false
			return
			
	var interactable = player.get("current_interactable")
	if interactable:
		visible = true
		label.text = "[E] " + interactable.prompt_message
	else:
		visible = false
