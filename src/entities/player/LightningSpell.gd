extends Node3D

@export var damage: int = 40
@export var aoe_radius: float = 2.5
@export var lifetime: float = 0.5

var caster: Node3D = null

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var particles: GPUParticles3D = $ImpactParticles
@onready var light: OmniLight3D = $OmniLight3D

func _ready() -> void:
	_trigger_damage()
	
	# Visual sequence
	var tween = create_tween()
	tween.tween_property(mesh, "scale:x", 0.0, lifetime)
	tween.parallel().tween_property(mesh, "scale:z", 0.0, lifetime)
	tween.parallel().tween_property(light, "light_energy", 0.0, lifetime)
	
	await get_tree().create_timer(lifetime + 0.2).timeout
	queue_free()

func _trigger_damage() -> void:
	var space_state = get_world_3d().direct_space_state
	# We use a sphere shape to check for enemies in radius
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = aoe_radius
	query.shape = sphere
	query.transform = global_transform
	query.collision_mask = 4 # Enemies
	
	var results = space_state.intersect_shape(query)
	for result in results:
		var body = result["collider"]
		if body and body.has_method("take_damage"):
			body.take_damage(damage, caster)
	
	if particles:
		particles.emitting = true
	
	if SoundManager:
		# Could add a thunder sound here
		pass
