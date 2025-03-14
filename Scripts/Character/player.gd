extends CharacterBody2D
class_name Player

# Properties
@export_group("Movement")
@export var speed: int = 421
@export var acceleration: float = 0.5
@export var friction: float = 0.7

@export_group("Combat")
@export var attack_duration: float = 0.3
@export var attack_cooldown: float = 0.5
@export var attack_damage: int = 1

@export_group("Dash")
@export var dash_speed: int = 1211 
@export var dash_duration: float = 0.3
@export var dash_cooldown: float = 1.0  

# Nodes references
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox_attack: Area2D = $HitboxAttack
@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer
@onready var attack_timer: Timer = $AttackTimer
@onready var dash_timer: Timer = $DashTimer
@onready var dash_cooldown_timer: Timer = $DashCooldownTimer

# State Machine
enum State {IDLE, MOVING, ATTACKING, DASHING}
var current_state: State = State.IDLE

# Direction Management
enum Direction {RIGHT, LEFT, UP, DOWN}
var current_direction: Direction = Direction.DOWN

# State variables
var dash_direction: Vector2 = Vector2.ZERO
var movement_input: Vector2 = Vector2.ZERO
var can_attack: bool = true
var can_dash: bool = true

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
	
	# Configure the timers
	attack_timer.wait_time = attack_duration
	attack_cooldown_timer.wait_time = attack_cooldown
	dash_timer.wait_time = dash_duration
	dash_cooldown_timer.wait_time = dash_cooldown
	
	# Connect timer signals to prevent reconnection issues
	if not attack_timer.timeout.is_connected(_on_attack_timer_timeout):
		attack_timer.timeout.connect(_on_attack_timer_timeout)
	if not attack_cooldown_timer.timeout.is_connected(_on_attack_cooldown_timer_timeout):
		attack_cooldown_timer.timeout.connect(_on_attack_cooldown_timer_timeout)
	if not dash_timer.timeout.is_connected(_on_dash_timer_timeout):
		dash_timer.timeout.connect(_on_dash_timer_timeout)
	if not dash_cooldown_timer.timeout.is_connected(_on_dash_cooldown_timer_timeout):
		dash_cooldown_timer.timeout.connect(_on_dash_cooldown_timer_timeout)

func _process(_delta: float) -> void:
	handle_input()
	update_animation()

func _physics_process(_delta: float) -> void:
	movement_input = get_movement_input()
	calculate_velocity()
	move_and_slide()

func calculate_velocity() -> void:
	var target_velocity = Vector2.ZERO
	
	match current_state:
		State.DASHING:
			target_velocity = dash_direction * dash_speed
		State.IDLE, State.MOVING, State.ATTACKING:
			if current_state != State.ATTACKING:
				target_velocity = movement_input * speed
	
	# Apply the acceleration or friction based on movement
	if target_velocity.length() > 0:
		velocity = velocity.lerp(target_velocity, acceleration)
	else:
		velocity = velocity.lerp(Vector2.ZERO, friction)

func handle_input() -> void:
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
	
	if current_state == State.ATTACKING:
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
			animated_sprite.play(DIRECTION_STRINGS[current_direction])
		State.DASHING:
			# TODO: DASHING Animation
			animated_sprite.play(DIRECTION_STRINGS[current_direction])
		State.MOVING:
			# Determine animation based on direction
			animated_sprite.play(DIRECTION_STRINGS[current_direction])
		State.IDLE:
			# TODO: IDLE Animation
			animated_sprite.play(DIRECTION_STRINGS[current_direction])

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
	
	# Start timers
	dash_timer.start()
	dash_cooldown_timer.start()

func position_hitbox() -> void:
	hitbox_attack.rotation_degrees = HITBOX_ROTATIONS[current_direction]

func change_state(new_state: State) -> void:
	# Exit current state logic
	match current_state:
		State.ATTACKING:
			hitbox_attack.monitoring = false
		State.DASHING:
			pass
		State.MOVING:
			pass
		State.IDLE:
			pass
	
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

func _on_hitbox_attack_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(attack_damage)
