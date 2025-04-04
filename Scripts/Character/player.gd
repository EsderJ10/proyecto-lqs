extends CharacterBody2D
class_name Player

# Signals
signal health_changed(new_health, max_health)
signal player_died()

# Properties
@export_group("Movement")
@export var speed: int = 400
@export var acceleration: float = 0.5
@export var friction: float = 0.7
@export var deceleration: float = 1.5

@export_group("Combat")
@export var attack_duration: float = 0.3
@export var attack_cooldown: float = 0.5
@export var attack_damage: int = 1

@export_group("Dash")
@export var dash_speed: int = 1200 
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
@onready var camera: Camera2D = $Camera2D
@onready var hurt_timer: Timer = $HurtTimer

# State Machine
enum State {IDLE, MOVING, ATTACKING, DASHING, HURT, DEAD}
var current_state: State = State.IDLE

# Direction Management
enum Direction {RIGHT, LEFT, UP, DOWN}
var current_direction: Direction = Direction.DOWN
var previous_direction: Direction = Direction.DOWN

# State variables
# Vectors
var dash_direction: Vector2 = Vector2.ZERO
var movement_input: Vector2 = Vector2.ZERO
var last_hit_direction: Vector2 = Vector2.ZERO

# Booleans
var can_attack: bool = true
var can_dash: bool = true
var is_invulnerable: bool = false

var current_health: int = 0
var current_tween: Tween
var current_animation: String = ""
var blink_time: float = 0.0

# Constants for direction and hitbox
const DIRECTION_VECTORS = {
	Direction.RIGHT: Vector2(1, 0),
	Direction.LEFT: Vector2(-1, 0),
	Direction.UP: Vector2(0, -1),
	Direction.DOWN: Vector2(0, 1)
}

const DIRECTION_STRINGS = {
	Direction.RIGHT: "right",
	Direction.LEFT: "left",
	Direction.UP: "up",
	Direction.DOWN: "down"
}

const HITBOX_ROTATIONS = {
	Direction.RIGHT: -90.0,
	Direction.LEFT: 90.0,
	Direction.UP: 180.0,
	Direction.DOWN: 0.0
}

func _ready() -> void:
	initialize_player()
	
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_cooldown_timer.timeout.connect(_on_attack_cooldown_timer_timeout)
	dash_timer.timeout.connect(_on_dash_timer_timeout)
	dash_cooldown_timer.timeout.connect(_on_dash_cooldown_timer_timeout)
	invulnerability_timer.timeout.connect(_on_invulnerability_timer_timeout)
	hurt_timer.timeout.connect(_on_hurt_timer_timeout)
	hitbox_attack.body_entered.connect(_on_hitbox_attack_body_entered)

func initialize_player() -> void:
	hitbox_attack.monitoring = false
	current_health = max_health
	
	# Configure the timers
	attack_timer.wait_time = attack_duration
	attack_cooldown_timer.wait_time = attack_cooldown
	dash_timer.wait_time = dash_duration
	dash_cooldown_timer.wait_time = dash_cooldown
	invulnerability_timer.wait_time = invulnerability_duration
	hurt_timer.one_shot = true
	hurt_timer.wait_time = 0.3

func _process(delta: float) -> void:
	handle_input()
	update_animation()
	
	# Blinking effect when invulnerable
	if is_invulnerable and current_state != State.DEAD:
		blink_time += delta * 10.0
		animated_sprite.modulate.a = 0.5 + sin(blink_time) * 0.5

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return
		
	movement_input = get_movement_input()
	calculate_velocity(delta)
	move_and_slide()

func calculate_velocity(delta: float) -> void:
	var target_velocity = Vector2.ZERO
	
	match current_state:
		State.DASHING:
			target_velocity = dash_direction * dash_speed
		State.HURT:
			target_velocity = last_hit_direction * hit_knockback_force
		State.IDLE, State.MOVING, State.ATTACKING:
			if current_state != State.ATTACKING:
				target_velocity = movement_input * speed
	
	if target_velocity.length_squared() > 0:
		velocity = velocity.lerp(target_velocity, acceleration * delta * 60.0)
	else:
		# Apply deceleration when actively stopping and friction when idle
		var stop_factor = deceleration if movement_input == Vector2.ZERO and velocity.length_squared() > 0 else friction
		velocity = velocity.lerp(Vector2.ZERO, stop_factor * delta * 10.0)

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
	if current_state == State.ATTACKING or current_state == State.HURT:
		return Vector2.ZERO
	
	previous_direction = current_direction
	
	var input = Vector2.ZERO
	var just_pressed_horizontal = false
	var just_pressed_vertical = false
	
	# Check horizontal movement
	if Input.is_action_pressed("move_right"):
		input.x = 1
		just_pressed_horizontal = Input.is_action_just_pressed("move_right")
	elif Input.is_action_pressed("move_left"):
		input.x = -1
		just_pressed_horizontal = Input.is_action_just_pressed("move_left")
		
	# Check vertical movement
	if Input.is_action_pressed("move_up"):
		input.y = -1
		just_pressed_vertical = Input.is_action_just_pressed("move_up")
	elif Input.is_action_pressed("move_down"):
		input.y = 1
		just_pressed_vertical = Input.is_action_just_pressed("move_down")
	
	# Update direction based on input priority
	if input.x != 0 and (input.y == 0 or just_pressed_horizontal):
		current_direction = Direction.RIGHT if input.x > 0 else Direction.LEFT
	elif input.y != 0 and (input.x == 0 or just_pressed_vertical):
		current_direction = Direction.UP if input.y < 0 else Direction.DOWN
	
	# Update state based on input length
	var input_length_squared = input.length_squared()
	
	if input_length_squared > 0 and current_state == State.IDLE:
		change_state(State.MOVING)
	elif input_length_squared == 0 and current_state == State.MOVING:
		change_state(State.IDLE)
	
	# Normalize only if needed
	return input.normalized() if input_length_squared > 0 else input

func update_animation() -> void:
	var dir_string = DIRECTION_STRINGS[current_direction]
	var anim_name = ""
	
	match current_state:
		State.ATTACKING:
			anim_name = "attack_" + dir_string
		State.DASHING:
			anim_name = "dash_" + dir_string
		State.MOVING:
			anim_name = dir_string
		State.IDLE:
			anim_name = "idle_" + dir_string
		State.HURT:
			anim_name = "hurt_" + dir_string
		State.DEAD:
			anim_name = "dead"
	
	if current_animation != anim_name:
		current_animation = anim_name
		
		# Check if animation exists, fall back if necessary
		if !animated_sprite.sprite_frames.has_animation(anim_name):
			if anim_name.begins_with("attack_") or anim_name.begins_with("dash_") or anim_name.begins_with("idle_") or anim_name.begins_with("hurt_"):
				anim_name = dir_string
			
			# Final fallback for dead animation
			if anim_name == "dead" and !animated_sprite.sprite_frames.has_animation("dead"):
				anim_name = dir_string
		
		animated_sprite.play(anim_name)

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
	if movement_input != Vector2.ZERO:
		dash_direction = movement_input
	else:
		dash_direction = DIRECTION_VECTORS[current_direction]
	
	# Set invulnerable during dash
	set_invulnerable(true)
	
	# Start timers
	dash_timer.start()
	dash_cooldown_timer.start()

func position_hitbox() -> void:
	hitbox_attack.rotation_degrees = HITBOX_ROTATIONS[current_direction]

func change_state(new_state: State) -> void:
	if current_state == new_state:
		return
		
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
			if hurt_timer and hurt_timer.is_stopped() == false:
				hurt_timer.stop()
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
			if hurt_timer:
				hurt_timer.start()
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
		last_hit_direction = -DIRECTION_VECTORS[current_direction]
	
	# Apply damage
	current_health = max(0, current_health - damage)
	
	kill_tween()
	
	# Flash effect
	animated_sprite.modulate = Color(1.5, 0.3, 0.3, 1.0)
	current_tween = create_tween()
	current_tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 1), 0.2)
	current_tween.finished.connect(func(): current_tween = null)
	
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		change_state(State.DEAD)
	else:
		# Apply hit reaction
		if camera.has_method("add_trauma"):
			camera.add_trauma(0.5)
		change_state(State.HURT)
		set_invulnerable(true)

func kill_tween() -> void:
	if current_tween and current_tween.is_valid():
		current_tween.kill()
		current_tween = null

func _on_hurt_timer_timeout() -> void:
	if current_state == State.HURT:
		change_state(State.IDLE)

func set_invulnerable(value: bool) -> void:
	is_invulnerable = value
	
	if value:
		invulnerability_timer.start()
		blink_time = 0.0
	else:
		# Reset sprite modulation
		animated_sprite.modulate.a = 1.0

func die() -> void:
	# Disable collision and input
	set_physics_process(false)
	set_process_input(false)
	
	kill_tween()
	
	player_died.emit()
	
	# Fade out animation
	current_tween = create_tween()
	current_tween.tween_property(animated_sprite, "modulate:a", 0.0, death_fade_duration)
	current_tween.tween_callback(queue_free)
	current_tween.finished.connect(func(): current_tween = null)

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
