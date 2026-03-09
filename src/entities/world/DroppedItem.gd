extends Node3D
class_name DroppedItem

## DroppedItem: Physical item in the world (Solo/Co-op)
## Displays rarity pillars (Diablo-style) and floating labels.

@export var item_instance: ItemInstance
@export var amount: int = 1

@onready var interactable: Interactable = $Interactable
@onready var label: Label3D = $Label3D
@onready var model_container: Node3D = $ModelContainer

func _ready() -> void:
	if not item_instance:
		queue_free()
		return
		
	_setup_visuals()
	_setup_rarity_pillar()
	
	# Bounce animation
	var tween = create_tween().set_loops()
	tween.tween_property(model_container, "position:y", 0.6, 1.2).set_trans(Tween.TRANS_SINE)
	tween.tween_property(model_container, "position:y", 0.3, 1.2).set_trans(Tween.TRANS_SINE)

func _setup_visuals() -> void:
	var base = item_instance.base_item
	label.text = item_instance.get_display_name() + ((" x" + str(item_instance.amount)) if item_instance.amount > 1 else "")
	label.modulate = item_instance.get_rarity_color()
	
	if base.world_model:
		var model = base.world_model.instantiate()
		model_container.add_child(model)
	else:
		# Fallback sphere
		var mesh = MeshInstance3D.new()
		mesh.mesh = SphereMesh.new()
		mesh.scale = Vector3(0.4, 0.4, 0.4)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = item_instance.get_rarity_color()
		mesh.material_override = mat
		model_container.add_child(mesh)
		
	interactable.prompt_message = "Pick up " + item_instance.get_display_name()
	interactable.interacted.connect(_on_interacted)

func _setup_rarity_pillar() -> void:
	# Only Rare+ items get a pillar
	if item_instance.rarity < ItemData.Rarity.RARE: return
	
	var pillar = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.05
	cylinder.bottom_radius = 0.2
	cylinder.height = 3.0
	pillar.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	var color = item_instance.get_rarity_color()
	color.a = 0.4
	mat.albedo_color = color
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	pillar.material_override = mat
	
	add_child(pillar)
	pillar.position.y = 1.5

func _on_interacted(player: Node3D) -> void:
	var inventory = player.get_node_or_null("InventoryComponent")
	if inventory:
		# We need to update inventory to accept instances
		var success = inventory.add_item_instance(item_instance)
		if success:
			if EventBus: EventBus.item_picked_up.emit(item_instance.get_display_name())
			queue_free()
