extends CharacterBody2D

enum State { PATROL, CHASE, ATTACK }

@export var speed: float = 120.0
@export var gravity: float = 1800.0
@export var patrol_direction: float = 1.0

# ── HP System ───────────────────────────────────────────────
@export var max_hp: int = 100
var current_hp: int = 100
var is_dead: bool = false

# ── Attack ──────────────────────────────────────────────────
@export var attack_range: float = 130.0
@export var attack_cooldown: float = 1.0
var attack_timer: float = 0.0

var current_state: State = State.PATROL
var player_ref: Node2D = null
var spawn_pos: Vector2 = Vector2.ZERO
var spawn_patrol_direction: float = 1.0  # remember original patrol direction

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ray_left: RayCast2D = $RayLeft
@onready var ray_right: RayCast2D = $RayRight
@onready var detection: Area2D = $DetectionArea
@onready var health_bar: ProgressBar = $HealthBar

func _ready() -> void:
	add_to_group("enemies")
	spawn_pos = global_position
	spawn_patrol_direction = patrol_direction
	current_hp = max_hp
	is_dead = false
	detection.body_entered.connect(_on_detect_enter)
	detection.body_exited.connect(_on_detect_exit)
	sprite.visible = true
	sprite.modulate = Color(1, 1, 1)
	sprite.play("static")
	health_bar.max_value = max_hp
	health_bar.value = current_hp
	print("🦹 ENEMY READY! Position: ", global_position)

func reset() -> void:
	print("🔄 Enemy reset to: ", spawn_pos)
	is_dead = false
	global_position = spawn_pos
	current_hp = max_hp
	velocity = Vector2.ZERO
	player_ref = null
	current_state = State.PATROL
	patrol_direction = spawn_patrol_direction
	attack_timer = 0.0
	sprite.modulate = Color(1, 1, 1)
	sprite.visible = true
	sprite.play("static")
	health_bar.value = max_hp
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	attack_timer = maxf(attack_timer - delta, 0)

	if not is_on_floor():
		velocity.y += gravity * delta

	if player_ref:
		var dist = global_position.distance_to(player_ref.global_position)
		if dist <= attack_range:
			current_state = State.ATTACK
		else:
			current_state = State.CHASE
		if dist <= attack_range and attack_timer <= 0:
			player_ref.take_damage(10)
			attack_timer = attack_cooldown
			print("👊 Enemy attacked player!")

	match current_state:
		State.PATROL:
			patrol_behavior()
		State.CHASE:
			chase_behavior()
		State.ATTACK:
			attack_behavior(delta)

	move_and_slide()
	update_animation()

func patrol_behavior() -> void:
	velocity.x = patrol_direction * speed
	if ray_left.is_colliding() and patrol_direction < 0:
		patrol_direction = 1.0
	if ray_right.is_colliding() and patrol_direction > 0:
		patrol_direction = -1.0

func chase_behavior() -> void:
	if player_ref:
		var direction = sign(player_ref.global_position.x - global_position.x)
		velocity.x = direction * speed
		if ray_left.is_colliding() and direction < 0:
			velocity.x = 0
		if ray_right.is_colliding() and direction > 0:
			velocity.x = 0

func attack_behavior(_delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, speed)
	if player_ref:
		sprite.flip_h = player_ref.global_position.x < global_position.x

func _on_detect_enter(body: Node2D) -> void:
	if body == self or body.is_in_group("platforms"):
		return
	if body.name == "Player" or body.is_in_group("player"):
		player_ref = body
		current_state = State.CHASE

func _on_detect_exit(body: Node2D) -> void:
	if body == player_ref:
		player_ref = null
		current_state = State.PATROL

func take_damage(amount: int) -> void:
	if is_dead:
		return
	current_hp -= amount
	health_bar.value = current_hp
	print("💥 Enemy hit! HP: ", current_hp, " / ", max_hp)
	sprite.modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.15).timeout
	if not is_dead:
		sprite.modulate = Color(1, 1, 1)
	if current_hp <= 0:
		die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	print("💀 Enemy killed!")
	velocity = Vector2.ZERO
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	if sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
		await sprite.animation_finished
	else:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.4)
		await tween.finished
	queue_free()

func update_animation() -> void:
	match current_state:
		State.PATROL, State.CHASE:
			if velocity.x > 0:
				sprite.flip_h = false
			elif velocity.x < 0:
				sprite.flip_h = true
			if abs(velocity.x) > 0:
				sprite.play("walk")
			else:
				sprite.play("static")
		State.ATTACK:
			if player_ref:
				sprite.flip_h = player_ref.global_position.x < global_position.x
			if sprite.sprite_frames.has_animation("attack"):
				if sprite.animation != "attack":
					sprite.play("attack")
			else:
				sprite.play("static")
