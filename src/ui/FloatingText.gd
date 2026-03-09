extends Label3D

func _ready() -> void:
	# Horizontal randomization only
	position += Vector3(randf_range(-0.5, 0.5), 0.0, randf_range(-0.5, 0.5))
	
	var tween := create_tween().set_parallel(true)
	
	# Move up significantly
	tween.tween_property(self, "position:y", position.y + 2.0, 1.0)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	
	# Scale up and down
	scale = Vector3.ZERO
	tween.tween_property(self, "scale", Vector3.ONE, 0.2)
	
	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, 0.5).set_delay(0.3)
	
	tween.finished.connect(queue_free)

static func create(parent: Node, pos: Vector3, text_value: String, color: Color = Color.WHITE) -> void:
	# Correct way to instantiate a node with a script in Godot 4
	var label := Label3D.new()
	label.set_script(load("res://src/ui/FloatingText.gd"))
	
	label.text = text_value
	label.modulate = color
	label.outline_modulate = Color.BLACK
	label.outline_size = 12
	label.font_size = 64
	label.billboard = StandardMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	
	parent.add_child(label)
	label.global_position = pos
