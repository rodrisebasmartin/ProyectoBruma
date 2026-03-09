extends Node

# This will be a Global Singleton (Autoload)
# Usage: SoundManager.play_hit_sound(position)

func play_hit_sound(pos: Vector3) -> void:
	var player := AudioStreamPlayer3D.new()
	add_child(player)
	
	# Placeholder: You can set a real stream here later
	# player.stream = load("res://assets/sounds/hit.wav")
	
	player.global_position = pos
	player.bus = "Master"
	player.unit_size = 10.0
	player.max_db = 0.0
	
	# For now, just a debug print since we don't have .wav files
	print("[SoundManager] Playing hit sound at: ", pos)
	
	# Auto-destroy the player after sound finishes (or instantly for now)
	player.finished.connect(player.queue_free)
	# player.play() # Uncomment once you have a sound file!
	
	# If no sound file, just delete it
	if player.stream == null:
		player.queue_free()
