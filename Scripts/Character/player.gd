extends CharacterBody2D
class_name Player

# Signals
signal health_changed(new_health, max_health)
signal player_died()

# Properties
@export_group("Movement")
@export var speed: int = 421
@export var acceleration: float = 0.5
@export var friction: float = 0.7
@export var deceleration: float = 1.5  # Added deceleration for stopping

@export_group("Combat")
@export var attack_duration: float = 0.3
@export var attack_cooldown: float = 0.5
@export var attack_damage: int = 1

@export_group("Dash")
@export var dash_speed: int = 1211 
@export var dash_duration: float = 0.3
@export var dash_cooldown: float = 1.0
@export var invulnerability_duration: float = 1.0

@export_group("Health")
@export var max_health: int = 5
@export var hit_knockback_force: float = 300.0
@export var death_fade_duration: float = 0.8

# Nodes references
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox_attack: Area2D = $HitboxAttack
@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer
@onready var attack_timer: Timer = $AttackTimer
@onready var dash_timer: Timer = $DashTimer
@onready var dash_cooldown_timer: Timer = $DashCooldownTimer
@onready var invulnerability_timer: Timer = $InvulnerabilityTimer

# State Machine
enum State {IDLE, MOVING, ATTACKING, DASHING, HURT, DEAD}
var current_state: State = State.IDLE

# Direction Management
enum Direction {RIGHT, LEFT, UP, DOWN}
var current_direction: Direction = Direction.DOWN

# State variables
var dash_direction: Vector2 = Vector2.ZERO
var movement_input: Vector2 = Vector2.ZERO
var can_attack: bool = true
var can_dash: bool = true
var is_invulnerable: bool = false
var current_health: int = 0
var last_hit_direction: Vector2 = Vector2.ZERO

# Constants for direction and hitbox
const DIRECTION_VECTORS = {
	Direction.RIGHT: Vector2(1, 0),
	Direction.LEFT: Vector2(-1, 0),
	Direction.UP: Vector2(0, -1),
	Direction.DOWN: Vector2(0, 1)
}

const HITBOX_ROTATIONS = {
	Direction.RIGHT: -90.0,
	Direction.LEFT: 90.0,
	Direction.UP: 180.0,
	Direction.DOWN: 0.0
}

const DIRECTION_STRINGS = {
	Direction.RIGHT: "right",
	Direction.LEFT: "left",
	Direction.UP: "up",
	Direction.DOWN: "down"
}

func _ready() -> void:
	initialize_player()

func initialize_player() -> void:
	hitbox_attack.monitoring = false
	current_health = max_health
	
	# Configure the timers
	attack_timer.wait_time = attack_duration
	attack_cooldown_timer.wait_time = attack_cooldown
	dash_timer.wait_time = dash_duration
	dash_cooldown_timer.wait_time = dash_cooldown
	invulnerability_timer.wait_time = invulnerability_duration

func _process(_delta: float) -> void:
	handle_input()
	update_animation()
	
	# Blinking effect when invulnerable
	if is_invulnerable and current_state != State.DEAD:
		animated_sprite.modulate.a = sin(Time.get_ticks_msec() * 0.01) * 0.5 + 0.5

func _physics_process(_delta: float) -> void:
	if current_state == State.DEAD:
		return
		
	movement_input = get_movement_input()
	calculate_velocity()
	move_and_slide()

func calculate_velocity() -> void:
	var target_velocity = Vector2.ZERO
	
	match current_state:
		State.DASHING:
			target_velocity = dash_direction * dash_speed
		State.HURT:
			target_velocity = last_hit_direction * hit_knockback_force
		State.IDLE, State.MOVING, State.ATTACKING:
			if current_state != State.ATTACKING:
				target_velocity = movement_input * speed
	
	# Apply acceleration, deceleration, or friction based on movement state
	if target_velocity.length() > 0:
		velocity = velocity.lerp(target_velocity, acceleration)
	else:
		# Apply deceleration when actively stopping and friction when idle
		var stop_factor = deceleration if movement_input == Vector2.ZERO and velocity.length() > 0 else friction
		velocity = velocity.lerp(Vector2.ZERO, stop_factor)

func handle_input() -> void:
	if current_state == State.DEAD or current_state == State.HURT:
		return
		
	match current_state:
		State.DASHING:
			# No input processing during DASHING state
			pass
		State.ATTACKING:
			# Limited input processing during ATTACKING state
			if Input.is_action_just_pressed("player_dash") and can_dash:
				change_state(State.DASHING)
				dash()
		State.IDLE, State.MOVING:
			if Input.is_action_just_pressed("player_attack") and can_attack:
				change_state(State.ATTACKING)
				attack()
			elif Input.is_action_just_pressed("player_dash") and can_dash:
				change_state(State.DASHING)
				dash()

func get_movement_input() -> Vector2:
	var input = Vector2.ZERO
	
	if current_state == State.ATTACKING or current_state == State.HURT:
		return input
	
	# Check each direction and set the current facing direction
	if Input.is_action_pressed("move_right"):
		input.x += 1
		current_direction = Direction.RIGHT
	if Input.is_action_pressed("move_left"):
		input.x -= 1
		current_direction = Direction.LEFT
	if Input.is_action_pressed("move_up"):
		input.y -= 1
		current_direction = Direction.UP
	if Input.is_action_pressed("move_down"):
		input.y += 1
		current_direction = Direction.DOWN
	
	# Prioritize last pressed direction for diagonal movement
	if input.x != 0 and input.y != 0:
		if Input.is_action_just_pressed("move_right"):
			current_direction = Direction.RIGHT
		elif Input.is_action_just_pressed("move_left"):
			current_direction = Direction.LEFT
		elif Input.is_action_just_pressed("move_up"):
			current_direction = Direction.UP
		elif Input.is_action_just_pressed("move_down"):
			current_direction = Direction.DOWN
	
	# Update movement state based on input
	if input.length() > 0 and current_state == State.IDLE:
		change_state(State.MOVING)
	elif input.length() == 0 and current_state == State.MOVING:
		change_state(State.IDLE)
	
	# Normalize only if input has length to avoid divide by zero
	return input.normalized() if input.length() > 0 else input

func update_animation() -> void:
	match current_state:
		State.ATTACKING:
			# TODO: ATTACKING Animation
			#animated_sprite.play("attack_" + DIRECTION_STRINGS[current_direction])
			animated_sprite.play(DIRECTION_STRINGS[current_direction])
		State.DASHING:
			# TODO: DASHING Animation
			#animated_sprite.play("dash_" + DIRECTION_STRINGS[current_direction])
			animated_sprite.play(DIRECTION_STRINGS[current_direction])
		State.MOVING:
			# Determine animation based on direction
			animated_sprite.play(DIRECTION_STRINGS[current_direction])
		State.IDLE:
			# TODO: IDLE Animation
			#animated_sprite.play("idle_" + DIRECTION_STRINGS[current_direction])
			animated_sprite.play(DIRECTION_STRINGS[current_direction])
		State.HURT:
			# TODO: HURT Animation
			#animated_sprite.play("hurt_" + DIRECTION_STRINGS[current_direction])
			animated_sprite.play(DIRECTION_STRINGS[current_direction])
		State.DEAD:
			# TODO: DEAD Animation
			#animated_sprite.play("dead")
			pass

func attack() -> void:
	can_attack = false
	position_hitbox()
	hitbox_attack.monitoring = true
	
	# Start timers
	attack_timer.start()
	attack_cooldown_timer.start()

func dash() -> void:
	can_dash = false
	# Use current movement input or facing direction
	dash_direction = movement_input if movement_input != Vector2.ZERO else DIRECTION_VECTORS[current_direction]
	
	# Set invulnerable during dash
	set_invulnerable(true)
	
	# Start timers
	dash_timer.start()
	dash_cooldown_timer.start()

func position_hitbox() -> void:
	hitbox_attack.rotation_degrees = HITBOX_ROTATIONS[current_direction]

func change_state(new_state: State) -> void:
	# Exit current state logic
	match current_state:
		State.ATTACKING:
			hitbox_attack.set_deferred("monitoring", false)
		State.DASHING:
			pass
		State.MOVING:
			pass
		State.IDLE:
			pass
		State.HURT:
			pass
		State.DEAD:
			return  # Don't allow state change if dead
	
	# Change state
	current_state = new_state
	
	# Enter new state logic
	match new_state:
		State.ATTACKING:
			pass
		State.DASHING:
			pass
		State.MOVING:
			pass
		State.IDLE:
			pass
		State.HURT:
			pass
		State.DEAD:
			die()

func take_damage(damage: int, source_position: Vector2 = Vector2.ZERO) -> void:
	# Check if player can take damage
	if is_invulnerable or current_state == State.DEAD or current_state == State.DASHING:
		return
	
	# Calculate damage direction for knockback
	if source_position != Vector2.ZERO:
		last_hit_direction = (global_position - source_position).normalized()
	else:
		# If no source position, knockback opposite to facing direction
		last_hit_direction = -DIRECTION_VECTORS[current_direction]
	
	# Apply damage
	current_health = max(0, current_health - damage)
	
	# Flash effect
	animated_sprite.modulate = Color(1.5, 0.3, 0.3, 1.0)
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 1), 0.2)
	
	# Emit signal
	health_changed.emit(current_health, max_health)
	
	# Check if player is dead
	if current_health <= 0:
		change_state(State.DEAD)
	else:
		# Apply hit reaction
		change_state(State.HURT)
		set_invulnerable(true)
		
		# Timer to exit hurt state
		var hurt_timer = get_tree().create_timer(0.3)
		hurt_timer.timeout.connect(func(): if current_state == State.HURT: change_state(State.IDLE))

func set_invulnerable(value: bool) -> void:
	is_invulnerable = value
	
	if value:
		invulnerability_timer.start()
	else:
		# Reset sprite modulation
		animated_sprite.modulate.a = 1.0

func die() -> void:
	# Disable collision and input
	set_physics_process(false)
	set_process_input(false)
	
	# Emit signal
	player_died.emit()
	
	# Fade out animation
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate:a", 0.0, death_fade_duration)
	tween.tween_callback(func(): queue_free())

func _on_attack_timer_timeout() -> void:
	if current_state == State.ATTACKING:
		hitbox_attack.monitoring = false
		change_state(State.IDLE)

func _on_attack_cooldown_timer_timeout() -> void:
	can_attack = true

func _on_dash_timer_timeout() -> void:
	if current_state == State.DASHING:
		change_state(State.IDLE)
	
func _on_dash_cooldown_timer_timeout() -> void:
	can_dash = true

func _on_invulnerability_timer_timeout() -> void:
	set_invulnerable(false)

func _on_hitbox_attack_body_entered(body: Node2D) -> void:
	if body == self:
		return
		
	# Only damage nodes that can take damage
	if body.has_method("take_damage"):
		body.take_damage(attack_damage)
