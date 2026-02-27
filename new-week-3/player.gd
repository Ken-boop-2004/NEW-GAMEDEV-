extends CharacterBody2D

# ── Movement ────────────────────────────────────────────────

@export var auto_run_speed : float = 250.0
@export var max_run_speed : float = 450.0
@export var acceleration : float = 1800.0
@export var friction : float = 1400.0
@export var jump_velocity : float = -920.0
@export var gravity : float = 1800.0

# ── Dash ────────────────────────────────────────────────────

@export var dash_speed : float = 900.0
@export var dash_duration : float = 0.15
@export var dash_cooldown : float = 0.9

var is_dashing : bool = false
var dash_timer : float = 0.0
var dash_cooldown_timer : float = 0.0
var dash_direction : Vector2 = Vector2.RIGHT

# ── Fall Death & Respawn ────────────────────────────────────

@export var death_y : float = 600.0
@export var spawn_position : Vector2 = Vector2(0, 0)

# ── Trackers ────────────────────────────────────────────────

var total_distance : float = 0.0

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	global_position = spawn_position

func _physics_process(delta: float) -> void:
	total_distance += velocity.x * delta

	# ── Gravity ─────────────────────────────────────────────
	if not is_on_floor() and not is_dashing:
		velocity.y += gravity * delta

	# ── Movement ─────────────────────────────────────────────
	if not is_dashing:
		var direction = Input.get_axis("move_left", "move_right")
		if direction != 0:
			velocity.x = move_toward(velocity.x, direction * auto_run_speed, acceleration * delta)
			sprite.flip_h = direction < 0
		else:
			velocity.x = move_toward(velocity.x, 0, friction * delta)

	# ── Jump ────────────────────────────────────────────────
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		sprite.play("jump")

	# ── Dash ────────────────────────────────────────────────
	if Input.is_action_just_pressed("dash") and not is_dashing and dash_cooldown_timer <= 0:
		start_dash()

	if is_dashing:
		velocity = dash_direction * dash_speed
		dash_timer -= delta
		if dash_timer <= 0:
			end_dash()

	dash_cooldown_timer = maxf(dash_cooldown_timer - delta, 0)

	# ── Apply movement ──────────────────────────────────────
	move_and_slide()

	# ── Fall Death Check ────────────────────────────────────
	if global_position.y > death_y:
		die()

	# ── Animations ──────────────────────────────────────────
	if is_dashing:
		sprite.play("dash")
	elif not is_on_floor():
		sprite.play("fall" if velocity.y > 0 else "jump")
	elif abs(velocity.x) > 20:
		sprite.play("run")
	else:
		sprite.play("idle")

func start_dash() -> void:
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown

	var h = Input.get_axis("move_left", "move_right")
	var v = Input.get_axis("jump", "jump")  # ignored, just using horizontal + jump combo

	# Dash direction based on input
	var dir = Vector2.ZERO
	dir.x = h

	# Allow upward dash if in air and jump is held
	if not is_on_floor() and Input.is_action_pressed("jump"):
		dir.y = -1.0

	# If no input at all, dash the way the sprite is facing
	if dir == Vector2.ZERO:
		dir.x = -1.0 if sprite.flip_h else 1.0

	dash_direction = dir.normalized()

func end_dash() -> void:
	is_dashing = false

func die() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	total_distance = 0.0
	dash_cooldown_timer = 0.0
	is_dashing = false
	print("Player fell off → respawned at ", spawn_position)

func _input(event: InputEvent) -> void:
	if event.is_action_released("jump") and velocity.y < 0:
		velocity.y *= 0.45
