extends State

func enter() -> void:
	actor.velocity.x = 0
	actor.velocity.z = 0
	if actor.has_method("_play_animation"):
		actor._play_animation("Idle")

func physics_update(_delta: float) -> void:
	actor.move_and_slide()
