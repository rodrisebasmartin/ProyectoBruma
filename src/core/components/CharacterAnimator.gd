extends Node
class_name CharacterAnimator

@export var animation_player: AnimationPlayer
@export var model_root: Node3D
@export var animation_sources: Dictionary
@export var auto_ground: bool = true

func _ready() -> void:
	if animation_player:
		_load_external_animations()
	
	if auto_ground and model_root:
		# Small delay to ensure everything is initialized
		call_deferred("_perform_auto_ground")

func _perform_auto_ground() -> void:
	if not model_root or not is_inside_tree(): return
	
	var parent = get_parent()
	var lowest_y = 99999.0
	var meshes = []
	_find_meshes_recursive(model_root, meshes)
	
	if meshes.is_empty(): return
	
	for mesh_node in meshes:
		var aabb = mesh_node.get_aabb()
		# Check all 8 corners of the AABB in parent's local space
		for i in range(8):
			var corner = aabb.get_endpoint(i)
			var global_corner = mesh_node.to_global(corner)
			var local_corner = parent.to_local(global_corner)
			if local_corner.y < lowest_y:
				lowest_y = local_corner.y
	
	# Offset the model root so the lowest point is at parent's zero (feet)
	if lowest_y != 99999.0:
		model_root.position.y -= lowest_y
		print("[CharacterAnimator] Auto-grounding: Offset applied to ", parent.name, " (", -lowest_y, ")")

func _find_meshes_recursive(node: Node, results: Array) -> void:
	if node is MeshInstance3D:
		results.append(node)
	for child in node.get_children():
		_find_meshes_recursive(child, results)

func play(anim_name: String, blend: float = 0.2) -> void:
	if not animation_player: return
	if animation_player.current_animation.to_lower() == anim_name.to_lower() and animation_player.is_playing(): return
	
	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name, blend)
	else:
		# Fallback for prefixed animations
		for full_name in animation_player.get_animation_list():
			if anim_name.to_lower() in full_name.to_lower():
				animation_player.play(full_name, blend)
				return

func set_speed(speed: float) -> void:
	if animation_player:
		animation_player.speed_scale = speed

func _load_external_animations() -> void:
	var library = animation_player.get_animation_library("")
	if not library:
		library = AnimationLibrary.new()
		animation_player.add_animation_library("", library)
		
	for anim_key in animation_sources:
		var path = animation_sources[anim_key]
		if FileAccess.file_exists(path):
			var fbx_scene: PackedScene = load(path)
			if fbx_scene:
				var instance = fbx_scene.instantiate()
				var anim_p = instance.get_node_or_null("AnimationPlayer")
				if anim_p:
					var internal_anim_name = anim_p.get_animation_list()[0]
					var anim: Animation = anim_p.get_animation(internal_anim_name).duplicate(true)
					
					# Remove root motion tracks
					for track_idx in range(anim.get_track_count() - 1, -1, -1):
						var t_path = str(anim.track_get_path(track_idx)).to_lower()
						if "hips" in t_path or "root" in t_path:
							if anim.track_get_type(track_idx) == Animation.TYPE_POSITION_3D:
								anim.remove_track(track_idx)
					
					if "Punch" in anim_key or "Dodge" in anim_key:
						anim.loop_mode = Animation.LOOP_NONE
					else:
						anim.loop_mode = Animation.LOOP_LINEAR
						
					library.add_animation(anim_key, anim)
				instance.queue_free()
