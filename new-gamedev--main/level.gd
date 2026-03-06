extends Node2D

@export var level_length: float = 8000.0
@export var l2_start: float = 4000.0
@export var death_y: float = 600.0          # Adjust: die if player falls below this Y
@export var spawn_pos: Vector2 = Vector2(100, 300)

var in_l2: bool = false

@onready var player = $Player
@onready var notification: Label = $CanvasLayer/LevelNotification
@onready var trigger_l2: Area2D = $TriggerL2

func _ready():
	if trigger_l2:
		trigger_l2.body_entered.connect(_on_l2_trigger)
	else:
		print("Warning: TriggerL2 node not found!")

	if not player:
		print("ERROR: Player node not found!")

func _process(delta):
	if not player:
		return

	# Debug: Watch player Y position (remove after testing)
	print("Player Y: ", player.global_position.y, "   Death threshold: ", death_y)

	# Fall death
	if player.global_position.y > death_y:
		die()
		return

	# Endless loop reset
	if player.global_position.x > level_length:
		player.global_position.x -= level_length
		player.total_distance = 0

	# Level 2 transition
	if player.total_distance > l2_start and not in_l2:
		enter_l2()

func _on_l2_trigger(body):
	if body == player:
		enter_l2()

func die():
	player.global_position = spawn_pos
	player.velocity = Vector2.ZERO
	player.total_distance = 0
	player.auto_run_speed = 250.0   # Reset to easy speed
	in_l2 = false
	notification.visible = false
	print("Player fell → Died & revived at ", spawn_pos)

func enter_l2():
	in_l2 = true
	player.auto_run_speed = 350.0
	show_notification()

func show_notification():
	notification.visible = true
	var tween = create_tween()
	tween.tween_property(notification, "modulate:a", 0.0, 2.0).from(1.0)
	await tween.finished
	notification.visible = false
