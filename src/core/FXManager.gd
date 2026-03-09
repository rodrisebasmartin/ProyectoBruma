extends Node

## FXManager: Listens to EventBus and spawns world-space effects (Solo/Co-op)
## This decouples entities from having to load UI/SFX scripts.

const FloatingTextScript = preload("res://src/ui/FloatingText.gd")

func _ready() -> void:
	EventBus.damage_triggered.connect(_on_damage_triggered)
	EventBus.heal_triggered.connect(_on_heal_triggered)
	EventBus.level_up_triggered.connect(_on_level_up_triggered)

func _on_damage_triggered(pos: Vector3, amount: int, color: Color) -> void:
	FloatingTextScript.create(get_tree().root, pos, str(amount), color)

func _on_heal_triggered(pos: Vector3, amount: int) -> void:
	FloatingTextScript.create(get_tree().root, pos, str(amount), Color.GREEN)

func _on_level_up_triggered(pos: Vector3, new_level: int) -> void:
	FloatingTextScript.create(get_tree().root, pos, "LEVEL UP! (" + str(new_level) + ")", Color.CYAN)
