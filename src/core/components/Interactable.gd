extends Area3D
class_name Interactable

signal interacted(player: CharacterBody3D)

@export var prompt_message: String = "Interact"
@export var is_active: bool = true

func interact(player: CharacterBody3D) -> void:
	if is_active:
		interacted.emit(player)
		print("[Interactable] Interacted with: ", name)
