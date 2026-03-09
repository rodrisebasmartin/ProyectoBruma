extends "res://src/entities/enemies/Enemy.gd"

## WolfBoss: A stronger version of the wolf with special attacks and indicators.

@export var slam_damage: int = 30
@export var slam_radius: float = 4.0
@export var slam_cooldown: float = 5.0

var slam_timer: float = 0.0

func _physics_process(delta: float) -> void:
	if health.is_dead: return
	slam_timer -= delta
	super._physics_process(delta)

func _update_ai_state(delta: float) -> void:
	if current_state == AIState.STAGGER: return
	
	_update_target()
	
	if target_player:
		var dist = global_position.distance_to(target_player.global_position)
		if dist < slam_radius and slam_timer <= 0 and not is_attacking:
			_perform_slam_attack()
			return
			
	super._update_ai_state(delta)

func _perform_slam_attack() -> void:
	is_attacking = true
	slam_timer = slam_cooldown
	
	# 1. Show Indicator
	var indicator = _create_circular_indicator(slam_radius)
	add_child(indicator)
	indicator.global_position = global_position
	indicator.position.y = 0.05
	
	# 2. Windup
	_play_animation("Attack") # Or a special roar/slam anim if available
	animation_player.speed_scale = 0.5 # Slow windup for telegraphing
	
	var tween = create_tween()
	var mat = indicator.material_override
	mat.albedo_color.a = 0
	tween.tween_property(mat, "albedo_color:a", 0.8, 1.0)
	tween.parallel().tween_property(indicator, "scale", Vector3(1.1, 1.1, 1.1), 0.5)
	
	await get_tree().create_timer(1.5).timeout
	
	if health.is_dead:
		indicator.queue_free()
		is_attacking = false
		return
		
	# 3. Impact
	animation_player.speed_scale = 2.0
	_play_animation("Attack")
	
	# FX
	if FXManager:
		FXManager.FloatingTextScript.create(get_tree().root, global_position + Vector3.UP, "CRUSH!", Color.ORANGE)
	
	# Damage check
	var players = get_tree().get_nodes_in_group("player")
	var allies = get_tree().get_nodes_in_group("allies")
	for p in players + allies:
		if global_position.distance_to(p.global_position) < slam_radius:
			if p.has_method("take_damage"):
				p.take_damage(slam_damage, self)
				
	# Screen shake (optional, if camera supports it)
	
	await get_tree().create_timer(0.5).timeout
	indicator.queue_free()
	is_attacking = false
	animation_player.speed_scale = 1.0

func _create_circular_indicator(radius: float) -> MeshInstance3D:
	var mesh_inst = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = 0.1
	mesh_inst.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0, 0, 0.4)
	mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mesh_inst.material_override = mat
	
	return mesh_inst
