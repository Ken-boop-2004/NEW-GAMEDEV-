extends Area2D

@export var target_scene: String = "res://game_level_2.tscn"

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	monitoring = true
	monitorable = true
	print("🌀 PORTAL READY at position: ", global_position)
	print("🌀 Target scene path: ", target_scene)
	print("🌀 Portal Collision Layer: ", collision_layer)
	print("🌀 Portal Collision Mask: ", collision_mask)

func _on_body_entered(body: Node2D) -> void:
	print("🚶 BODY ENTERED PORTAL: ", body.name, " (type: ", body.get_class(), ")")
	print("🚶 Body position: ", body.global_position)
	
	# Flexible check: name OR has die() method OR group
	if body.name == "Player" or body.has_method("die") or body.is_in_group("player"):
		print("✅ PLAYER CONFIRMED! Teleporting...")
		
		# Verify file exists before changing
		var resource = load(target_scene)
		if resource == null:
			printerr("❌ TARGET SCENE NOT FOUND: ", target_scene)
			return
		
		var err = get_tree().change_scene_to_file(target_scene)
		if err != OK:
			printerr("❌ SCENE CHANGE FAILED! Error code: ", err)
		else:
			print("🎉 TELEPORT SUCCESS!")
	else:
		print("❌ Not player – ignored")
