extends Node3D
class_name MinimapIcon

@export var color: Color = Color.WHITE
@export var size: float = 2.0

func _ready() -> void:
	# Create a simple mesh that's only visible on the Minimap layer
	var mesh_instance = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = size * 0.5
	mesh.bottom_radius = size * 0.5
	mesh.height = 0.1
	mesh_instance.mesh = mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true # Always on top of the world in the minimap
	mesh_instance.material_override = mat
	
	add_child(mesh_instance)
	
	# Position above for the minimap
	mesh_instance.position.y = 10.0 
	
	# Render Layer 10 for Minimap
	mesh_instance.layers = 1 << 9 # Layer 10
