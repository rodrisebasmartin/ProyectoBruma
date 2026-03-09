extends Node3D

func _ready() -> void:
	if has_node("GateToTown"):
		$GateToTown.body_entered.connect(_on_gate_entered)
		_add_portal_icon($GateToTown, Color.VIOLET)

func _add_portal_icon(node: Node3D, color: Color) -> void:
	var icon = MinimapIcon.new()
	icon.color = color
	icon.size = 4.0
	node.add_child(icon)

func _on_gate_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		print("[Wild] Returning to Town...")
		if GameManager:
			GameManager.change_scene("res://src/world/TownFixed.tscn", body)
		else:
			get_tree().change_scene_to_file("res://src/world/TownFixed.tscn")
