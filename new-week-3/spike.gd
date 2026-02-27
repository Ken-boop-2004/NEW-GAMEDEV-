extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)
	# Add to hazards group (for future)
	add_to_group("hazards")

func _on_body_entered(body):
	if body.has_method("die"):  # Calls player.die()
		body.die()
