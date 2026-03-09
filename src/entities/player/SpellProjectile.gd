extends Area3D

@export var speed: float = 20.0
@export var damage: int = 20
@export var heal_amount: int = 30
@export var lifetime: float = 2.0

@export var is_healing: bool = false
var caster: Node3D = null

var direction: Vector3 = Vector3.ZERO

@onready var trail_particles: GPUParticles3D = $TrailParticles
@onready var impact_particles: GPUParticles3D = $ImpactParticles
@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var light: OmniLight3D = $OmniLight3D

var hit_occured: bool = false

func _ready() -> void:
	collision_layer = 0
	# Mask: Player/Ally (1), World (2), Enemy (4)
	collision_mask = 1 | 2 | 4
	
	if is_healing:
		_setup_healing_visuals()
	
	get_tree().create_timer(lifetime).timeout.connect(_on_lifetime_end)
	body_entered.connect(_on_body_entered)

func _setup_healing_visuals() -> void:
	if light: light.light_color = Color(0.2, 1.0, 0.4) 
	if mesh:
		var mat = StandardMaterial3D.new()
		mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.2, 1.0, 0.4)
		mesh.material_override = mat

func _physics_process(delta: float) -> void:
	if hit_occured: return
	
	if direction != Vector3.ZERO:
		global_position += direction * speed * delta
		if direction.cross(Vector3.UP).length() > 0.001:
			look_at(global_position + direction, Vector3.UP)

func _on_body_entered(body: Node3D) -> void:
	if hit_occured or body == caster: return
	
	print("[Projectile] Hit: ", body.name, " | Group Allies: ", body.is_in_group("allies"), " | Healing: ", is_healing)

	if is_healing:
		if body.has_method("heal") and body.is_in_group("allies"):
			body.heal(heal_amount)
			_impact_sequence()
		elif body.collision_layer & 2: # World
			_impact_sequence()
	else:
		if body.has_method("take_damage"):
			body.take_damage(damage, caster)
			_impact_sequence()
		elif body.collision_layer & 2: # World
			_impact_sequence()

func _impact_sequence() -> void:
	hit_occured = true
	_trigger_impact()

func _on_lifetime_end() -> void:
	if not hit_occured:
		queue_free()

func _trigger_impact() -> void:
	mesh.visible = false
	light.visible = false
	if trail_particles: trail_particles.emitting = false
	
	if impact_particles:
		if is_healing:
			var mat = impact_particles.process_material.duplicate()
			mat.color = Color(0.2, 1.0, 0.4)
			impact_particles.process_material = mat
		impact_particles.emitting = true
		await get_tree().create_timer(0.5).timeout
	
	queue_free()
