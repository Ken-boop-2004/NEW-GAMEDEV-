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

# ── Combat ──────────────────────────────────────────────────
@export var max_hp : int = 100
var current_hp : int = 100
@export var attack_damage : int = 10
@export var attack_cooldown : float = 0.5
var attack_timer : float = 0.0
var attack_queued : bool = false
var is_attacking : bool = false
var attack_anim_timer : float = 0.0      # forces attack anim to end
@export var attack_anim_duration : float = 0.4  # match this to your attack animation length
var is_invincible : bool = false

# ── Trackers ────────────────────────────────────────────────
var total_distance : float = 0.0

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area : Area2D = $AttackArea
var health_bar : ProgressBar = null

func _ready() -> void:
	global_position = spawn_position
	current_hp = max_hp
	
	# Debug — print all child node names
	for child in get_children():
		print("Child node: ", child.name)
	
	if has_node("HealthBar"):
		health_bar = $HealthBar
		health_bar.max_value = max_hp
		health_bar.value = current_hp
		print("✅ HealthBar connected!")
	else:
		printerr("❌ HealthBar not found — check node name is exactly 'HealthBar'")
	
	if not attack_area:
		printerr("AttackArea node missing!")
	
	attack_anim_timer = 0.0

func _physics_process(delta: float) -> void:
	total_distance += velocity.x * delta

	# Gravity
	if not is_on_floor() and not is_dashing:
		velocity.y += gravity * delta

	# Movement
	if not is_dashing:
		var direction = Input.get_axis("move_left", "move_right")
		if direction != 0:
			velocity.x = move_toward(velocity.x, direction * auto_run_speed, acceleration * delta)
			sprite.flip_h = direction < 0
		else:
			velocity.x = move_toward(velocity.x, 0, friction * delta)

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Dash
	if Input.is_action_just_pressed("dash") and not is_dashing and dash_cooldown_timer <= 0:
		start_dash()
	if is_dashing:
		velocity = dash_direction * dash_speed
		dash_timer -= delta
		if dash_timer <= 0:
			end_dash()
	dash_cooldown_timer = maxf(dash_cooldown_timer - delta, 0)

	# Attack
	attack_timer = maxf(attack_timer - delta, 0)
	if Input.is_action_just_pressed("attack"):
		attack_queued = true
	if attack_queued and attack_timer <= 0 and not is_attacking:
		attack()
		attack_timer = attack_cooldown
		attack_queued = false

	# Force-clear attack animation after duration
	if is_attacking:
		attack_anim_timer -= delta
		if attack_anim_timer <= 0:
			is_attacking = false

	# Apply movement
	move_and_slide()

	# Fall death
	if global_position.y > death_y:
		die()

	# Animations
	_update_animation()

func _update_animation() -> void:
	if is_attacking:
		_play_anim("attack")
	elif is_dashing:
		_play_anim("dash", "run")
	elif not is_on_floor():
		if velocity.y > 0:
			_play_anim("fall", "jump")
		else:
			_play_anim("jump")
	elif abs(velocity.x) > 20:
		_play_anim("run")
	else:
		_play_anim("idle")

func _play_anim(anim: String, fallback: String = "") -> void:
	var target : String = ""
	if sprite.sprite_frames.has_animation(anim):
		target = anim
	elif fallback != "" and sprite.sprite_frames.has_animation(fallback):
		target = fallback
	else:
		return
	if sprite.animation != target or not sprite.is_playing():
		sprite.play(target)

func start_dash() -> void:
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	var h = Input.get_axis("move_left", "move_right")
	var dir = Vector2(h, 0)
	if not is_on_floor() and Input.is_action_pressed("jump"):
		dir.y = -1.0
	if dir == Vector2.ZERO:
		dir.x = -1.0 if sprite.flip_h else 1.0
	dash_direction = dir.normalized()

func end_dash() -> void:
	is_dashing = false

func attack() -> void:
	is_attacking = true
	attack_anim_timer = attack_anim_duration  # start countdown to end attack anim
	_play_anim("attack")
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == self:
			continue
		if not enemy.has_method("take_damage"):
			continue
		if global_position.distance_to(enemy.global_position) <= 150.0:
			enemy.take_damage(attack_damage)

func take_damage(amount: int) -> void:
	if is_invincible:
		return
	if current_hp <= 0:
		return
	current_hp -= amount
	if health_bar:
		health_bar.value = current_hp
	print("Player HP: ", current_hp)
	is_invincible = true
	sprite.modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.4).timeout
	if is_instance_valid(self):
		sprite.modulate = Color(1, 1, 1)
		is_invincible = false
	if current_hp <= 0:
		die()

func die() -> void:
	is_invincible = false
	is_attacking = false
	is_dashing = false
	attack_anim_timer = 0.0
	velocity = Vector2.ZERO
	total_distance = 0.0
	dash_cooldown_timer = 0.0
	current_hp = max_hp
	if health_bar:
		health_bar.value = max_hp
	sprite.modulate = Color(1, 1, 1)
	global_position = spawn_position
	print("Player died → respawned at ", spawn_position)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_method("reset"):
			enemy.reset()

func _input(event: InputEvent) -> void:
	if event.is_action_released("jump") and velocity.y < 0:
		velocity.y *= 0.45
