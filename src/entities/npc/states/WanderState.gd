extends State

var target_pos: Vector3
var wander_radius: float = 5.0
var move_speed: float = 1.5

func enter() -> void:
	if "wander_radius" in actor:
		wander_radius = actor.wander_radius
	if "move_speed" in actor:
		move_speed = actor.move_speed
		
	var origin = actor.original_position if "original_position" in actor else actor.global_position
	var offset = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized() * randf_range(2, wander_radius)
	target_pos = origin + offset
	
	if actor.has_method("_play_animation"):
		actor._play_animation("Walk")

func physics_update(delta: float) -> void:
	var current_pos_2d = Vector2(actor.global_position.x, actor.global_position.z)
	var target_pos_2d = Vector2(target_pos.x, target_pos.z)
	var dir_2d = (target_pos_2d - current_pos_2d).normalized()
	
	actor.velocity.x = dir_2d.x * move_speed
	actor.velocity.z = dir_2d.y * move_speed
	
	if actor.velocity.length() > 0.1:
		# Standard Godot: -Z is forward. atan2(-x, -z) aligns -Z with movement.
		var target_angle = atan2(-actor.velocity.x, -actor.velocity.z)
		actor.rotation.y = lerp_angle(actor.rotation.y, target_angle, 6.0 * delta)
	
	actor.move_and_slide()
	
	if current_pos_2d.distance_to(target_pos_2d) < 0.6:
		fsm.transition_to("idle")
