extends State

@export var idle_time_range: Vector2 = Vector2(2.0, 5.0)
var timer: float

func enter() -> void:
	timer = randf_range(idle_time_range.x, idle_time_range.y)
	if actor.has_method("_play_animation"):
		actor._play_animation("Idle")
		
func physics_update(delta: float) -> void:
	# Gravity handled by actor or here? Ideally actor, but let's keep it simple.
	# Assuming actor handles gravity in _physics_process outside FSM or FSM handles all movement.
	# For this refactor, let's have FSM handle horizontal movement, actor handles gravity if needed.
	
	actor.velocity.x = move_toward(actor.velocity.x, 0, 10.0 * delta)
	actor.velocity.z = move_toward(actor.velocity.z, 0, 10.0 * delta)
	actor.move_and_slide()

	timer -= delta
	if timer <= 0 and actor.get("can_wander"):
		fsm.transition_to("wander")
