extends CharacterBody2D

# Properties
@export var speed: int = 421
@export var acceleration: float = 0.5
@export var friction: float = 0.7
@export var attack_duration: float = 0.3
@export var attack_cooldown: float = 0.5
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

# State variables
var can_attack: bool = true
var can_dash: bool = true
var is_attacking: bool = false
var is_dashing: bool = false
var current_direction: String = "down"
var dash_direction: Vector2 = Vector2.ZERO
var movement_input: Vector2 = Vector2.ZERO

func _ready() -> void:
	hitbox_attack.monitoring = false
	# Setup timers
	attack_timer.wait_time = attack_duration
	attack_cooldown_timer.wait_time = attack_cooldown
	dash_timer.wait_time = dash_duration
	dash_cooldown_timer.wait_time = dash_cooldown

func _process(_delta: float) -> void:
	handle_input()
	update_animation()

func _physics_process(_delta: float) -> void:
	movement_input = get_movement_input()
	
	var target_velocity = Vector2.ZERO
	
	if is_dashing:
		target_velocity = dash_direction * dash_speed
	else:
		target_velocity = movement_input * speed
		
	# Smoother movement with acceleration and friction applied
	if target_velocity.length() > 0:
		velocity = velocity.lerp(target_velocity, acceleration)
	else:
		velocity = velocity.lerp(Vector2.ZERO, friction)
	
	move_and_slide()

func handle_input() -> void:
	if Input.is_action_just_pressed("player_attack") and can_attack:
		attack()
	if Input.is_action_just_pressed("player_dash") and can_dash:
		dash()

func get_movement_input() -> Vector2:
	var input = Vector2.ZERO
	
	if Input.is_action_pressed("move_right"):
		input.x += 1
		current_direction = "right"
	if Input.is_action_pressed("move_left"):
		input.x -= 1
		current_direction = "left"
	if Input.is_action_pressed("move_up"):
		input.y -= 1
		current_direction = "up"
	if Input.is_action_pressed("move_down"):
		input.y += 1
		current_direction = "down"
	
	return input.normalized() if input.length() > 0 else input

func update_animation() -> void:
	if movement_input.length() > 0 and !is_dashing:
		# Assign animation based on movement direction
		if abs(movement_input.x) > abs(movement_input.y):
			if movement_input.x > 0:
				animated_sprite.play("right")
			else:
				animated_sprite.play("left")
		else:
			if movement_input.y > 0:
				animated_sprite.play("down")
			else:
				animated_sprite.play("up")

func attack() -> void:
	is_attacking = true
	can_attack = false
	
	position_hitbox()
	hitbox_attack.monitoring = true
	
	# Start timers
	attack_timer.start()
	attack_cooldown_timer.start()

func dash() -> void:
	is_dashing = true
	can_dash = false
	
	# Determine dash direction based on input or current facing direction
	if movement_input != Vector2.ZERO:
		dash_direction = movement_input
	else:
		dash_direction = get_direction_vector(current_direction)
	
	# Start timers
	dash_timer.start()
	dash_cooldown_timer.start()

func get_direction_vector(dir: String) -> Vector2:
	match dir:
		"right":
			return Vector2(1, 0)
		"left":
			return Vector2(-1, 0)
		"up":
			return Vector2(0, -1)
		"down":
			return Vector2(0, 1)
	return Vector2.ZERO

func position_hitbox() -> void:
	# Adjust hitbox position/rotation based on the current direction
	match current_direction:
		"right":
			hitbox_attack.rotation_degrees = -90
		"left":
			hitbox_attack.rotation_degrees = 90
		"up":
			hitbox_attack.rotation_degrees = 180
		"down":
			hitbox_attack.rotation_degrees = 0

func _on_attack_timer_timeout() -> void:
	# Disable the hitbox after attack
	hitbox_attack.monitoring = false
	is_attacking = false

func _on_attack_cooldown_timer_timeout() -> void:
	can_attack = true

func _on_dash_timer_timeout() -> void:
	is_dashing = false
	
func _on_dash_cooldown_timer_timeout() -> void:
	can_dash = true

func _on_hitbox_attack_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(1)

# Function for enemy detection
func player():
	pass
