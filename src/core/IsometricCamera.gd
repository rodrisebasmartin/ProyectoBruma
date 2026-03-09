extends Node3D

@export_group("Target Settings")
@export var target: Node3D
@export var smooth_speed: float = 8.0

@export_group("Isometric View")
@export var angle_x: float = -35.0
@export var angle_y: float = 45.0

func _ready() -> void:
	rotation_degrees = Vector3(angle_x, angle_y, 0)
	add_to_group("camera")
	
	# Exclude Layer 10 (Minimap Icons) from main rendering
	var cam = get_node_or_null("Camera3D")
	if cam:
		# Layer bitmask: ~(1 << 9) means "all layers EXCEPT bit 9"
		cam.cull_mask = ~(1 << 9)

func _physics_process(delta: float) -> void:
	if is_instance_valid(target):
		_follow_target(delta)

func _follow_target(delta: float) -> void:
	global_position = global_position.lerp(target.global_position, smooth_speed * delta)
