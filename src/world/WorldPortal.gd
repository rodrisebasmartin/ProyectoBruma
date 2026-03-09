extends Area3D
class_name WorldPortal

## WorldPortal: Handles scene transitions and displays a Minimap marker.

@export_file("*.tscn") var target_scene: String
@export var portal_name: String = "Gate"
@export var icon_color: Color = Color.VIOLET

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_add_minimap_icon()

func _add_minimap_icon() -> void:
	var icon = MinimapIcon.new()
	icon.color = icon_color
	icon.size = 4.0
	add_child(icon)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and target_scene != "":
		print("[Portal] Traveling to ", target_scene)
		if GameManager:
			GameManager.change_scene(target_scene, body)
		else:
			get_tree().change_scene_to_file(target_scene)
